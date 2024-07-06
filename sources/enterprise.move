module suipass::enterprise {
    use std::vector;
    use std::option::{Option};
    use std::string::{Self, String};

    use sui::coin;
    use sui::event;
    use sui::transfer;
    use sui::sui::SUI;
    use sui::object::{Self, UID, ID};
    use sui::vec_map::{Self, VecMap};
    use sui::tx_context::{Self, TxContext};

    use suipass::provider::{Self, Provider, ProviderCap};
    use suipass::user::{Self, User};
    use suipass::suipass::{Self, AdminCap, SuiPass};

    // This module sumarizes all supported credits,
    // allows users to mint their passport NFT (Need to check if NFT can be updated, OR users will hold a lot of passports since their credit can be expire)
    const DEFAULT_THRESHOLD: u16 = 30; // 30/100
    const DEFAULT_EXPIRATION_PERIOD: u64 = 3 * 30 * 24 * 60 * 60 * 1000 ; // 3 months in miliseconds

    // Errors
    const EProviderNotExist: u64 = 0;
    const EProviderAlreadyExist: u64 = 1;
    const EUsernotQualified: u64 = 2;
    const EInvalidProviderWeights: u64 = 3;

    //Const value
    const MAX_WEIGHT: u16 = 1000;

    //======================================================================
    // Module Structs
    //======================================================================

    public struct EnterpriseCap has key {
        id: UID,
        enterprise: ID
    }
    // This struct store supported providers and others config
    public struct Enterprise has key, store {
        id: UID,
        name: String,
        metadata: String,
        providers: VecMap<ID, ProviderConfig>,
        weights: VecMap<ID, u16>,
        threshold: u16,
    }

    public struct ProviderConfig has store { }

    //======================================================================
    // Event Structs
    //======================================================================

    public struct CreatedEnterprise has copy, drop {
        enterprise_id: ID,
        enterprise_cap_id: ID,
    }

    //======================================================================
    // Functions
    //======================================================================

    public fun create_enterprise(
        suipass: &mut SuiPass,
        owner: address,
        name: vector<u8>,
        metadata: vector<u8>,
        provider_ids: vector<ID>,
        weights_vec: vector<u16>,
        threshold: u16, // TODO: Handle check if it valid
        ctx: &mut TxContext
    ) {
        let weights = convert_provider_weights(weights_vec, provider_ids);
        let mut providers = vec_map::empty();
        let mut i = 0;
        while (i < vector::length(&provider_ids)) {
            let id = *vector::borrow(&provider_ids, i);
            suipass::assert_provider_exist(suipass, id);
            vec_map::insert(&mut providers, id, ProviderConfig {});
            i = i + 1;
        };
        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        let cap = EnterpriseCap {
            id: object::new(ctx),
            enterprise: id
        };

        let event = CreatedEnterprise {
           enterprise_id: id,
           enterprise_cap_id: object::uid_to_inner(&cap.id)
        };
        // let weights = vec_map::from_vector(provider_ids, weights_vec);
        transfer::share_object(Enterprise {
            id: uid,
            name: string::utf8(name),
            metadata: string::utf8(metadata),
            providers,
            weights,
            threshold,
        });
        transfer::transfer(cap, tx_context::sender(ctx));
        event::emit(event);
    }

    //======================================================================
    // Accessors
    //======================================================================

    public fun calculate_user_score(ent: &Enterprise, suipass: &SuiPass, user: &User, _: &mut TxContext): u16 {
        let levels = user::levels(user);
        let ids = vec_map::keys(&levels);
        let mut len = vector::length(&ids);

        let mut result: u16 = 0;
        loop {
            if (len == 0) break;
            len = len - 1;

            let id = vector::borrow(&ids, len);

            let level = *vec_map::get(&levels, id);

            let increase = suipass::get_score(suipass, id, level);

            let weight = *vec_map::get(&ent.weights, id);

            result = result + increase * weight / MAX_WEIGHT;
        };

        result
    }

    public fun is_human(ent: &Enterprise, suipass: &SuiPass, user: &User, ctx: &mut TxContext): bool {
        let score = calculate_user_score(ent, suipass, user, ctx);
        score >= ent.threshold
    }

    fun convert_provider_weights(weight_vec: vector<u16>, provider_ids: vector<ID>): VecMap<ID, u16>{
        assert!(vector::length(&provider_ids) == vector::length(&weight_vec), EInvalidProviderWeights);
        let mut len = vector::length(&weight_vec);
        let mut sum = 0;
        let mut weights: VecMap<ID, u16> = vec_map::empty();
        while (len >= 0) {
            let weight = *vector::borrow(&weight_vec, len);
            sum = sum + weight;
            let provider = *vector::borrow(&provider_ids, len);
            vec_map::insert(&mut weights, provider, weight);
            len = len + 1;
        };
        assert!(sum == MAX_WEIGHT, EInvalidProviderWeights);

        weights
    }

    //======================================================================
    // Validation functions
    //======================================================================

    //======================================================================
    // Tests
    //======================================================================
}
