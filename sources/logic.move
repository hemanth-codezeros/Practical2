module Hem_Acc::Practical2 {
    use std::signer;
    use std::vector;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::object;
    use aptos_framework::timestamp;
    use aptos_framework::string;

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

    public entry fun mint_tokens(
        admin: &signer, customer_address: address, amount: u64
    ) acquires AdminData, MintCapStorage {
        assert!(signer::address_of(admin) == @Hem_Acc, ENOT_ADMIN);
        let object_address =
            object::create_object_address(&@Hem_Acc, SEED_FOR_OBJECT);
        let admin_data = borrow_global_mut<AdminData>(object_address);
        let mint_cap = borrow_global_mut<MintCapStorage<LoyaltyToken>>(@Hem_Acc).mint_cap;
        let index = find_user_fund_index(&admin_data.userfunds, customer_address);

        if (index == vector::length(&admin_data.userfunds)) {
            // User doesn't have an account yet, create account and mint tokens for his address.
            let minted_coins = coin::mint<LoyaltyToken>(amount, &mint_cap);
            admin_data.total_minted = admin_data.total_minted
                + coin::value<LoyaltyToken>(&minted_coins);
            let coinbatch = CoinBatch {
                token: minted_coins,
                expiry_timestamp: timestamp::now_seconds() + SECS_PER_YEAR
            };
            let batches = vector::empty<CoinBatch>();
            vector::push_back(&mut batches, coinbatch);

            vector::push_back(
                &mut admin_data.userfunds,
                CustomerAccount { batches, customer_address }
            );
        } else {
            let customer_account = vector::borrow_mut(&mut admin_data.userfunds, index);
            let minted_coins = coin::mint<LoyaltyToken>(amount, &mint_cap);
            admin_data.total_minted = admin_data.total_minted
                + coin::value<LoyaltyToken>(&minted_coins);
            let coinbatch = CoinBatch {
                token: minted_coins,
                expiry_timestamp: timestamp::now_seconds() + SECS_PER_YEAR
            };

            vector::push_back(&mut customer_account.batches, coinbatch);
        };
        move_to(admin, MintCapStorage { mint_cap });
        // destroy_mint_cap<LoyaltyToken>(mint_cap);
    }

    public entry fun redeem_tokens(
        customer_signer: &signer, amount: u64
    ) acquires AdminData {

        let object_address =
            object::create_object_address(&@Hem_Acc, SEED_FOR_OBJECT);
        let admin_data = borrow_global_mut<AdminData>(object_address);
        let index =
            find_user_fund_index(
                &admin_data.userfunds, signer::address_of(customer_signer)
            );
        if (index == vector::length(&admin_data.userfunds)) {
            // User doesn't have an account yet, its forbidden to redeem tokens without account.
            abort ENO_ACCOUNT_FOR_USER;
        } else {
            let customer_account = vector::borrow_mut(&mut admin_data.userfunds, index);
            assert!(
                !vector::is_empty<CoinBatch>(&customer_account.batches),
                ENO_TOKENS_TO_REDEEM
            );

            let coinbatch = vector::remove<CoinBatch>(&mut customer_account.batches, 0);
            assert!(
                coinbatch.expiry_timestamp < timestamp::now_seconds(),
                ETOKENS_EXPIRED
            );
            let coins = coin::extract(&mut coinbatch.token, amount);
            coin::deposit(customer_account.customer_address, coins);
        }
    }

    #[view]
    public fun check_balance(customer_address: address): u64 acquires AdminData {
        let object_address =
            object::create_object_address(&@Hem_Acc, SEED_FOR_OBJECT);
        let admin_data = borrow_global_mut<AdminData>(object_address);
        let index = find_user_fund_index(&admin_data.userfunds, customer_address);
        if (index == vector::length(&admin_data.userfunds)) {
            // User doesn't have an account yet, its forbidden to redeem tokens without account.
            abort ENO_ACCOUNT_FOR_USER
        } else {
            let customer_account = vector::borrow_mut(&mut admin_data.userfunds, index);
            let i: u64 = 0;
            let length: u64 = vector::length(&customer_account.batches);
            let value: u64 = 0;
            while (i < length) {
                let coinbatch = vector::borrow_mut(&mut customer_account.batches, i);
                value = value + coin::value<LoyaltyToken>(&coinbatch.token);
                i = i + 1;
            };
            value
        }
    }

    public entry fun withdraw_expired_tokens(
        admin: &signer, customer_address: address
    ) acquires BurnCapStorage, AdminData {
        let object_address =
            object::create_object_address(&@Hem_Acc, SEED_FOR_OBJECT);
        let admin_data = borrow_global_mut<AdminData>(object_address);
        let index = find_user_fund_index(&admin_data.userfunds, customer_address);

        let customer_account = vector::borrow_mut(&mut admin_data.userfunds, index);
        let burn_cap = borrow_global_mut<BurnCapStorage<LoyaltyToken>>(@Hem_Acc).burn_cap;

        let i: u64 = 0;
        let length: u64 = vector::length(&customer_account.batches);
        while (i < length) {
            let coinbatch = vector::borrow_mut(&mut customer_account.batches, i);

            if (coinbatch.expiry_timestamp > timestamp::now_seconds()) {
                coin::burn(coinbatch.token, &burn_cap);

            };
        };
        move_to(admin, BurnCapStorage { burn_cap });
    }
}
