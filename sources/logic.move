module Hem_Acc::Practical2 {
    use std::signer;
    use std::vector;
    use aptos_framework::account;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::timestamp;
    use aptos_framework::object::ObjectGroup;
    use aptos_framework::string;

    // Error codes
    /// Not admin, access only for admin
    const ENOT_ADMIN: u64 = 1001;

    /// Not a customer
    const ENOT_CUSTOMER: u64 = 1002;

    /// The tokesn you are trying to fetch have expired
    const ETOKENS_EXPIRED: u64 = 1003;

    ///Customer has no tokens to redeem
    const ENO_TOKENS_TO_REDEEM: u64 = 1004;

    /// Tokens for the customer have expired
    const ETOKENS_NOT_EXPIRED: u64 = 1005;

    const SECS_PER_YEAR: u64 = 31536000;

    // const NAME: vector<u8> = b"AdminTokenObject";

    struct LoyaltyToken has store {}

    /// Struct representing a customer's loyalty account
    struct CustomerAccount has store {
        balance: Coin<LoyaltyToken>,
        customer_address: address, // Customers public address
        expiry_timestamp: u64 // When the current balance expires
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct AdminData has key {
        userfunds: vector<CustomerAccount>,
        total_minted: u64
    }

    /// Struct representing the admin's control object
    struct AdminStore has key {
        mint_cap: coin::MintCapability<LoyaltyToken>,
        burn_cap: coin::BurnCapability<LoyaltyToken>,
        freeze_cap: coin::FreezeCapability<LoyaltyToken>,
        expiry_period: u64 // seconds until tokens expire
    }

    struct ObjectStore has key {
        object_address: address
    }

    // Initializing the contract
    fun init_module(admin: &signer) {

        let admin_address = signer::address_of(admin);
        let constructor_ref = object::create_object(admin_address);
        let object_signer = object::generate_signer(&constructor_ref);

        move_to(
            &object_signer,
            AdminData {
                userfunds: vector::empty<CustomerAccount>(),
                total_minted: 0
            }
        );

        move_to(admin, ObjectStore { object_address: signer::address_of(&object_signer) });

        let (burn_cap, freeze_cap, mint_cap) =
            coin::initialize<LoyaltyToken>(
                admin,
                string::utf8(b"Loyalty Reward Token"),
                string::utf8(b"LRT"),
                0, // decimals
                true // allow_upgrades
            );

        move_to(
            admin,
            AdminStore { mint_cap, burn_cap, freeze_cap, expiry_period: SECS_PER_YEAR }
        );

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
    ) acquires ObjectStore, AdminData, AdminStore {
        assert!(signer::address_of(admin) == @Hem_Acc, ENOT_ADMIN);

        let object_address = borrow_global_mut<ObjectStore>(@Hem_Acc).object_address;
        let object = object::address_to_object(object_address);
        let admin_data =
            borrow_global_mut<AdminData>(&object);

        let mint_cap = borrow_global_mut<AdminStore>(@Hem_Acc).mint_cap;

        let index = find_user_fund_index(&admin_data.userfunds, customer_address);

        if (index == vector::length(&admin_data.userfunds)) {
            // User doesn't have an account yet, create account and mint tokens for his address.
            let minted_coins = coin::mint<LoyaltyToken>(amount, &mint_cap);

            vector::push_back(
                &mut admin_data.userfunds,
                CustomerAccount {
                    balance: coin::zero<LoyaltyToken>(),
                    customer_address,
                    expiry_timestamp: timestamp::now_seconds() + SECS_PER_YEAR
                }
            );
        } else {
            let customer_account = vector::borrow_mut(&mut admin_data.userfunds, index);
            let minted_coins = coin::mint<LoyaltyToken>(amount, &mint_cap);

            coin::merge(&mut customer_account.balance, minted_coins);
        };
    }

    public entry fun redeem_tokens(customer_signer: &signer, amount: u64) {}

    public fun check_balance(customer_signer: &signer): u64 { 0 }

    public entry fun withdraw_expired_tokens(admin: &signer) {}
}
