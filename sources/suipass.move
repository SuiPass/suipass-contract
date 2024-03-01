module suipass::suipass {
    use sui::object::{Self, UID};
    use std::string::{Self, String};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use std::vector;

    use sui::table::{Self, Table};
    use sui::vec_set::{Self, VecSet};

    // This module sumarizes all supported credits,
    // allows users to mint their passport NFT (Need to check if NFT can be updated, OR users will hold a lot of passports since their credit can be expire)
    const DEFAULT_THRESHOLD: u16 = 30; // 30/100
    const DEFAULT_EXPIRATION_PERIOD: u64 = 3 * 30 * 24 * 60 * 60 * 1000 ; // 3 months in miliseconds

    // Errors
    const EProviderNotExist: u64 = 0;
    const EProviderAlreadyExist: u64 = 1;
    const EUsernotQualified: u64 = 2;

    // This struct store supported providers and their score
    struct SuiPass has key, store {
        id: UID,
        providers: VecSet<address>,
        providers_data: Table<address, Provider>,
        threshold: u16,
        expiration_period: u64
    }

    // We need to pass more data into this object, basically suipass's owner can set score for each 3rd party
    struct Provider has store, drop {
        score: u16
    }

    // We assume that the threshold will be changed in the future, but it doesn't matter. 
    // The NFT is still legal since it doesn't expire
    struct NFTPassportMetadata has key {
        id: UID,
        issued_date: u64,
        expiration_date: u64,
        score: u16,
        threshold: u16
    }

    struct AdminCap has key {
        id: UID
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx),
        }, tx_context::sender(ctx));

        transfer::share_object(SuiPass {
            id: object::new(ctx),
            providers: vec_set::empty(),
            providers_data: table::new<address, Provider>(ctx),
            threshold: DEFAULT_THRESHOLD,
            expiration_period: DEFAULT_EXPIRATION_PERIOD
        });
    }

    public fun add_provider(suiPass: &mut SuiPass, provider: address, score: u16, _: &mut TxContext) {
        assert!(!vec_set::contains(&suiPass.providers, &provider), EProviderAlreadyExist);
        table::add(&mut suiPass.providers_data, provider, Provider {score});
        vec_set::insert(&mut suiPass.providers, provider);
    }

    public fun remove_provider(suiPass: &mut SuiPass, provider: address, _: &mut TxContext) {
        assert_provider_exist(suiPass, provider);
        vec_set::remove(&mut suiPass.providers, &provider);
        table::remove(&mut suiPass.providers_data, provider);
    }

    public fun update_provider_score(suiPass: &mut SuiPass, provider: address, score: u16, _: &mut TxContext) {
        assert_provider_exist(suiPass, provider);
        table::borrow_mut(&mut suiPass.providers_data, provider).score = score;
    }


    public fun get_provider_score(suiPass: &SuiPass, provider: address, _: &mut TxContext): u16 {
        assert_provider_exist(suiPass, provider);
        return table::borrow(&suiPass.providers_data, provider).score
    }

    public fun calculate_user_score(suiPass: &SuiPass, user: address, _: &mut TxContext): u16 {
        let providers_vector = vec_set::keys(&suiPass.providers);
        let len = vector::length(providers_vector) - 1;

        let result: u16 = 0;
        loop {
            let provider = vector::borrow(providers_vector, len); //provider address
                                                  // We need to call provider module and get current level of a given user
            let level = 2;
            let total_levels = 3;
            let provider_score = table::borrow(&suiPass.providers_data, *provider).score;
            let increase = (level / total_levels * provider_score);
            result = result + increase;
            len = len - 1;
            if (len == 0) {
                break
            }
        };

        result
    }
    public entry fun mint_passport(suiPass: &SuiPass, ctx: &mut TxContext) {
        let score = calculate_user_score(suiPass, tx_context::sender(ctx), ctx);

        assert!(score >= suiPass.threshold, EUsernotQualified);

        let issued_date = tx_context::epoch_timestamp_ms(ctx);

        transfer::transfer(NFTPassportMetadata {
            id: object::new(ctx),
            issued_date,
            expiration_date: issued_date + suiPass.expiration_period, 
            score,
            threshold: suiPass.threshold
        }, tx_context::sender(ctx));
    }

    //==============================================================================================
    // Validation functions - Add your validation functions here (if any)
    //==============================================================================================
    fun assert_provider_exist(suiPass: &SuiPass, provider: address) {
        assert!(vec_set::contains(&suiPass.providers, &provider), EProviderNotExist);
    }
}
