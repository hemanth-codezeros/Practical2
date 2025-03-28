module hem_acc::Practical2 {
    use std::signer;
    use std::vector;
    use std::debug;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::object;
    use aptos_framework::timestamp;
    use aptos_framework::string;

    #[test_only]
    use aptos_framework::account;

    // Error codes
    /// Not admin, access only for admin
    const ENOT_ADMIN: u64 = 1001;

    /// Not a customer
    const ENOT_CUSTOMER: u64 = 1002;

    /// The tokens you are trying to fetch have expired
    const ETOKENS_EXPIRED: u64 = 1003;

    ///Customer has no tokens to redeem
    const ENO_TOKENS_TO_REDEEM: u64 = 1004;

    /// Tokens for the customer have expired
    const ETOKENS_NOT_EXPIRED: u64 = 1005;

    /// User doesn't have an account yet, its forbidden to redeem tokens without account.
    const ENO_ACCOUNT_FOR_USER: u64 = 1006;

    /// Creating 1 YEAR as default token expiry time for new minted tokens.
    const SECS_PER_YEAR: u64 = 31536000;

    /// Seed value for admin data object
    const SEED_FOR_OBJECT: vector<u8> = b"AdminDataObject";

    // Custom coin for rewarding customers
    struct LoyaltyToken has store {}

    /// Struct representing a customer's loyalty token account
    struct CustomerAccount has store {
        batches: vector<CoinBatch>, // All batches of tokens minted for a specific customer.
        customer_address: address // Customers public address
    }

    /// Batch of tokens minted with a specific expiry timestamp
    struct CoinBatch has store {
        token: Coin<LoyaltyToken>, // Minted tokens batch
        expiry_timestamp: u64 // and respective expiry timestamp for this batch
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct AdminData has key {
        userfunds: vector<CustomerAccount>,
        total_minted: u64,
        expiry_period: u64 // Default seconds until tokens expire (1 year)
    }

    struct MintCapStorage<phantom LoyaltyToken> has key {
        mint_cap: coin::MintCapability<LoyaltyToken>
    }

    struct BurnCapStorage<phantom LoyaltyToken> has key {
        burn_cap: coin::BurnCapability<LoyaltyToken>
    }

    struct FreezeCapStorage<phantom LoyaltyToken> has key {
        freeze_cap: coin::FreezeCapability<LoyaltyToken>
    }

    // Initializing the contract
    fun init_module(admin: &signer) {
        let constructor_ref = object::create_named_object(admin, SEED_FOR_OBJECT);
        let object_signer = object::generate_signer(&constructor_ref);

        move_to(
            &object_signer,
            AdminData {
                userfunds: vector::empty<CustomerAccount>(),
                total_minted: 0,
                expiry_period: SECS_PER_YEAR
            }
        );

        let (burn_cap, freeze_cap, mint_cap) =
            coin::initialize<LoyaltyToken>(
                admin,
                string::utf8(b"Loyalty Reward Token"),
                string::utf8(b"LRT"),
                0, // decimals
                true // allow_upgrades
            );

        move_to(admin, MintCapStorage { mint_cap });
        move_to(admin, BurnCapStorage { burn_cap });
        move_to(admin, FreezeCapStorage { freeze_cap });
    }

    public entry fun mint_tokens(
        admin: &signer, customer_address: address, amount: u64
    ) acquires AdminData, MintCapStorage {
        assert!(signer::address_of(admin) == @hem_acc, ENOT_ADMIN);
        let object_address = object::create_object_address(&@hem_acc, SEED_FOR_OBJECT);
        let admin_data = borrow_global_mut<AdminData>(object_address);
        let MintCapStorage { mint_cap } =
            move_from<MintCapStorage<LoyaltyToken>>(@hem_acc);
        let index = find_user_fund_index(&admin_data.userfunds, customer_address);

        //Minting coins with one year expiry time.
        let minted_coins = coin::mint<LoyaltyToken>(amount, &mint_cap);
        admin_data.total_minted = admin_data.total_minted
            + coin::value<LoyaltyToken>(&minted_coins);
        let coinbatch = CoinBatch {
            token: minted_coins,
            expiry_timestamp: timestamp::now_seconds() + SECS_PER_YEAR
        };

        if (index == vector::length(&admin_data.userfunds)) {
            // User doesn't have an account yet, create an account and add minted tokens for his address.
            let batches = vector::empty<CoinBatch>();
            vector::push_back(&mut batches, coinbatch);
            vector::push_back(
                &mut admin_data.userfunds,
                CustomerAccount { batches, customer_address }
            );
        } else {
            let customer_account = vector::borrow_mut(&mut admin_data.userfunds, index);
            vector::push_back(&mut customer_account.batches, coinbatch);
        };
        move_to(admin, MintCapStorage { mint_cap });
    }

    public entry fun redeem_tokens(customer_signer: &signer, amount: u64) acquires AdminData {
        let object_address = object::create_object_address(&@hem_acc, SEED_FOR_OBJECT);
        let admin_data = borrow_global_mut<AdminData>(object_address);
        let index =
            find_user_fund_index(
                &admin_data.userfunds, signer::address_of(customer_signer)
            );
        assert!(index != vector::length(&admin_data.userfunds), ENO_ACCOUNT_FOR_USER);
        let customer_account = vector::borrow_mut(&mut admin_data.userfunds, index);
        assert!(
            !vector::is_empty<CoinBatch>(&customer_account.batches),
            ENO_TOKENS_TO_REDEEM
        );

        let i = 0;
        // Trying to remove tokens from batches depending on amount we run loop on batches.
        while (amount > 0) {
            let coinbatch = vector::borrow_mut(&mut customer_account.batches, i);

            // Checking if batch has expired, if yes, then moving to next batch to redeem
            if (coinbatch.expiry_timestamp < timestamp::now_seconds()) {
                i = i + 1;
                continue // Moving to next batch
            };
            let batch_value = coin::value<LoyaltyToken>(&coinbatch.token);
            if (batch_value < amount) {
                let coins = coin::extract_all(&mut coinbatch.token);
                coin::deposit(customer_account.customer_address, coins);
                amount = amount - batch_value;
            } else {
                let coins = coin::extract(&mut coinbatch.token, amount);
                coin::deposit(customer_account.customer_address, coins);
                amount = 0;
            }
        };

    }

    public entry fun withdraw_expired_tokens(admin: &signer) acquires BurnCapStorage, AdminData {
        assert!(signer::address_of(admin) == @hem_acc, ENOT_ADMIN);
        let object_address = object::create_object_address(&@hem_acc, SEED_FOR_OBJECT);
        let admin_data = borrow_global_mut<AdminData>(object_address);
        let BurnCapStorage { burn_cap } =
            move_from<BurnCapStorage<LoyaltyToken>>(@hem_acc);

        vector::for_each_mut(
            &mut admin_data.userfunds,
            |customer_account| {
                let length: u64 = vector::length(&customer_account.batches);
                let i: u64 = 0;
                // let message1 = string::utf8(b"Length is :");
                // debug::print(&message1);
                while (i < length) {
                    let coinbatch = vector::borrow_mut(&mut customer_account.batches, i);
                    if (coinbatch.expiry_timestamp < timestamp::now_seconds()) {
                        let coinbatch = vector::remove(&mut customer_account.batches, i);
                        length = length - 1;
                        let CoinBatch { token,.. } = coinbatch;
                        coin::burn(token, &burn_cap);
                        continue // Don't increment i after removing a batch.
                    };
                    i = i + 1;
                };
            }
        );
        move_to(admin, BurnCapStorage { burn_cap });
    }

    #[view]
    public fun check_balance(customer_address: address): u64 acquires AdminData {
        let object_address = object::create_object_address(&@hem_acc, SEED_FOR_OBJECT);
        let admin_data = borrow_global_mut<AdminData>(object_address);
        let index = find_user_fund_index(&admin_data.userfunds, customer_address);
        // User doesn't have an account yet, cannot find balance for it. Aborts!!
        assert!(index != vector::length(&admin_data.userfunds), ENO_ACCOUNT_FOR_USER);

        let customer_account = vector::borrow_mut(&mut admin_data.userfunds, index);
        let value: u64 = 0;
        vector::for_each_ref(
            &customer_account.batches,
            |coinbatch| {
                value = value + coin::value<LoyaltyToken>(&coinbatch.token);
            }
        );

        value
    }

    // Helper function to find index of an address of a user
    fun find_user_fund_index(
        userfunds: &vector<CustomerAccount>, user_addr: address
    ): u64 {
        let i = 0;
        let len = vector::length(userfunds);

        while (i < len) {
            let customer_account = vector::borrow(userfunds, i);
            if (customer_account.customer_address == user_addr) {
                return i
            };
            i = i + 1;
        };

        len
    }

    #[test(arg = @hem_acc, framework = @aptos_framework)]
    fun test_mint_tokens(arg: signer, framework: signer) acquires AdminData, MintCapStorage {
        init_module(&arg);
        let custom_address: address =
            @0xb1f4c9f2d642d40de852b1bd68138143b95dfe8f8f3676adc7b8fd6f81a14441;
        timestamp::set_time_has_started_for_testing(&framework);
        mint_tokens(&arg, custom_address, 1067);
        assert!(check_balance(custom_address) == 1067, 1);
    }

    #[test(arg = @hem_acc, framework = @aptos_framework)]
    fun test_redeem_tokens(arg: signer, framework: signer) acquires AdminData, MintCapStorage {
        init_module(&arg);

        let recipient_signer = account::create_account_for_test(@0x12345666);
        coin::register<LoyaltyToken>(&recipient_signer);

        let custom_address: address = signer::address_of(&recipient_signer);
        timestamp::set_time_has_started_for_testing(&framework);

        mint_tokens(&arg, custom_address, 3106);
        assert!(check_balance(custom_address) == 3106, 1);

        redeem_tokens(&recipient_signer, 104);
        assert!(check_balance(custom_address) == 3002, 1);
    }

    #[test(arg = @hem_acc, framework = @aptos_framework)]
    fun test_withdraw_expired_tokens(
        arg: signer, framework: signer
    ) acquires AdminData, MintCapStorage, BurnCapStorage {
        init_module(&arg);
        let object_address = object::create_object_address(&@hem_acc, SEED_FOR_OBJECT);
        let admin_data = borrow_global_mut<AdminData>(object_address);
        let MintCapStorage { mint_cap } =
            move_from<MintCapStorage<LoyaltyToken>>(@hem_acc);
        let recipient_signer = account::create_account_for_test(@0x12345666);
        let customer_address: address = signer::address_of(&recipient_signer);
        timestamp::set_time_has_started_for_testing(&framework);
        timestamp::fast_forward_seconds(1_000);

        // Creating 4 batches of minted coins with 1st and 3rd batches have expired coins (1000sec expiry)
        let minted_coins1 = coin::mint<LoyaltyToken>(1050, &mint_cap); //Expired
        let minted_coins2 = coin::mint<LoyaltyToken>(9960, &mint_cap);
        let minted_coins3 = coin::mint<LoyaltyToken>(7050, &mint_cap); //Expired
        let minted_coins4 = coin::mint<LoyaltyToken>(8950, &mint_cap);

        move_to(&arg, MintCapStorage { mint_cap });

        admin_data.total_minted = admin_data.total_minted
            + coin::value<LoyaltyToken>(&minted_coins1)
            + coin::value<LoyaltyToken>(&minted_coins2)
            + coin::value<LoyaltyToken>(&minted_coins3)
            + coin::value<LoyaltyToken>(&minted_coins4);

        let coinbatch1 = CoinBatch { token: minted_coins1, expiry_timestamp: 100 };
        let coinbatch2 = CoinBatch { token: minted_coins2, expiry_timestamp: 1400 };
        let coinbatch3 = CoinBatch { token: minted_coins3, expiry_timestamp: 200 };
        let coinbatch4 = CoinBatch { token: minted_coins4, expiry_timestamp: 1150 };

        let batches = vector::empty<CoinBatch>();
        vector::push_back(&mut batches, coinbatch1);
        vector::push_back(&mut batches, coinbatch2);
        vector::push_back(&mut batches, coinbatch3);
        vector::push_back(&mut batches, coinbatch4);

        vector::push_back(
            &mut admin_data.userfunds,
            CustomerAccount { batches, customer_address }
        );
        withdraw_expired_tokens(&arg);

        debug::print(&check_balance(customer_address));
        assert!(check_balance(customer_address) == 18910, 1); // 9960 + 8950

    }
}
