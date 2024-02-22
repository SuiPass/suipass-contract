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
    struct Provider has store {
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
            providers: vec_set::new<addres>(ctx),
            providers_data: table::new<address, Provider>(ctx),
            threshold: DEFAULT_THRESHOLD,
            expiration_period: DEFAULT_EXPIRATION_PERIOD
        });
    }

    public entry fun addProvider(ctx: &mut TxContext, provider: address, score: u16) {
        let suiPass = object::get_object::<SuiPass>(ctx, tx_context::sender(ctx));
        let mut providers = suiPass.providers;
        let mut providers_data = suiPass.providers_data;
        assert!(!vec_set::contains(&providers, provider), EProviderAlreadyExist);
        table::add(&mut providers_data, provider, Provider {score});
        vec_set::insert(&mut providers, provider);
        object::set_object(ctx, suiPass.id, SuiPass {
            id: suiPass.id,
            providers: providers,
            providers_data: providers_data,
            threshold: suiPass.threshold
        });
    }

    public entry fun removeProvider(ctx: &mut TxContext, provider: address) {
        let suiPass = object::get_object::<SuiPass>(ctx, tx_context::sender(ctx));
        let mut providers = suiPass.providers;
        let mut providers_data = suiPass.providers_data;
        assert!(vec_set::contains(&providers, provider), EProviderNotExist);
        vec_set::remove(&mut providers, provider);
        table::remove(&mut providers_data, provider);
        object::set_object(ctx, suiPass.id, SuiPass {
            id: suiPass.id,
            providers: providers,
            providers_data: providers_data,
            threshold: suiPass.threshold
        });
    }

    public entry fun updateProviderScore(ctx: &mut TxContext, provider: address, score: u16) {
        let suiPass = object::get_object::<SuiPass>(ctx, tx_context::sender(ctx));
        let mut providers = suiPass.providers;
        let mut providers_data = suiPass.providers_data;
        assert!(vec_set::contains(&providers, provider), EProviderNotExist);
        table::update(&mut providers_data, provider, Provider {score});
        object::set_object(ctx, suiPass.id, SuiPass {
            id: suiPass.id,
            providers: providers,
            providers_data: providers_data,
            threshold: suiPass.threshold
        });
    }


    public fun getProviderScore(ctx: &mut TxContext, provider: address): u16 {
        let suiPass = object::get_object::<SuiPass>(ctx, tx_context::sender(ctx));
        let providers = suiPass.providers;
        assert!(suiPass.providers.contains(provider), EProviderNotExist);
        return table::get::<Provider>(providers, provider).score;
    }

    public fun calculateUserScore(ctx: &mut TxContext, user: address): f64 {
        let suiPass = object::get_object::<SuiPass>(ctx, tx_context::sender(ctx));
        let providers = suiPass.providers;

        let providers_vector = vec_set::into_keys(&providers);
        let len = Vector::length(providers_vector) - 1;

        let result: f64 = 0;
        loop {
            let provider = providers_vector[len]; //provider address
                                                  // We need to call provider module and get current level of a given user
            let level = 2;
            let total_levels = 3;
            let provider_score = table::get::<Provider>(providers, provider).score;
            result += level as f64 / total_levels as f64 * provider_score as f64;
            len--;
            if len == 0 {
                break
            }
        }

        return result;
    }
    public entry fun mintPassport(ctx: &mut TxContext) {
        let suiPass = object::get_object::<SuiPass>(ctx, tx_context::sender(ctx));
        let score = calculateUserScore(ctx, tx_context::sender(ctx));

        if score < suiPass.threshold as f64 {
            panic!(EUsernotQualified);
        }

        transfer::transfer(NFTPassportMetadata {
            id: object::new(ctx),
            issued_date: tx_context::timestamp(ctx),
            expiration_date: tx_context::timestamp(ctx) + suiPass.expiration_period, 
            score: score,
            threshold: suiPass.threshold
        }, tx_context::sender(ctx));
    }
}
