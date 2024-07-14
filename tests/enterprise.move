#[test_only]
module suipass::enterprise_test{
    use sui::test_scenario::{Self as test, next_tx, ctx, end, begin, Scenario};
    use suipass::suipass::{Self, SuiPass};
    use suipass::provider::{ProviderCap};
    use suipass::enterprise::{Enterprise, create_enterprise, calculate_user_score};
    use suipass::user::{User, new, merge};
    use suipass::approval::{Approval, level};

    use sui::sui::SUI;
    use sui::coin::{mint_for_testing, burn_for_testing};

    use suipass::provider_test::{creat_provider, submit_request_test, resolve_request_test};

    public fun create_enterprise_test(
        scenario: &mut Scenario, 
        name: vector<u8>, 
        provider_ids: vector<ID>,
        weights_vec: vector<u16>,
        threshold: u16
    ){
        let mut suipass_object = test::take_shared<SuiPass>(scenario);
        let default_metadata = b"metadata::test";
        let owner = @0x9;
        create_enterprise(
            &mut suipass_object,
            owner,
            name,
            default_metadata,
            provider_ids,
            weights_vec,
            threshold,
            ctx(scenario)
        );
        test::return_shared(suipass_object);
    }

    #[test]
    fun calculate_score(){
        let admin = @0x1;
        let provider_0 = @0x2;
        let provider_1 = @0x3;
        let provider_2 = @0x4;

        let provider_0_id: ID;
        let provider_1_id: ID;
        let provider_2_id: ID;

        let user = @0x5;

        let enterprise_creator = @0x6;

        let mut scenario =  begin(admin);
        {
            suipass::init_for_testing(ctx(&mut scenario));
        };
        //Create three providers
        //provider 0
        {
            let total_level = 2;
            let level_score_distribution = vector[50, 50];
            let max_score = 400;
            creat_provider(&mut scenario, admin, provider_0, total_level, level_score_distribution, max_score);
        };
        next_tx(&mut scenario, provider_0);
        {
            let provider_cap = test::take_from_sender<ProviderCap>(&scenario);
            provider_0_id = provider_cap.id_from_cap();
            test::return_to_sender(&scenario, provider_cap);
        };
        //provider 1
        next_tx(&mut scenario, admin);
        {
            let total_level = 3;
            let level_score_distribution = vector[10,40,50];
            let max_score = 500;
            creat_provider(&mut scenario, admin, provider_1, total_level, level_score_distribution, max_score);
        };
        next_tx(&mut scenario, provider_1);
        {
            let provider_cap = test::take_from_sender<ProviderCap>(&scenario);
            provider_1_id = provider_cap.id_from_cap();
            test::return_to_sender(&scenario, provider_cap);
        };
        //provider 2
        next_tx(&mut scenario, admin);
        {
            let total_level = 4;
            let level_score_distribution = vector[10,20,30,40];
            let max_score = 600;
            creat_provider(&mut scenario, admin, provider_2, total_level, level_score_distribution, max_score);
        };
        next_tx(&mut scenario, provider_2);
        {
            let provider_cap = test::take_from_sender<ProviderCap>(&scenario);
            provider_2_id = provider_cap.id_from_cap();
            test::return_to_sender(&scenario, provider_cap);
        };
        //Setup level for user
        next_tx(&mut scenario, user);
        {
            let proof = b"proof";
            let mut coin_in = mint_for_testing<SUI>(100u64, ctx(&mut scenario));
            submit_request_test(&mut scenario, provider_0_id, proof, &mut coin_in);
            burn_for_testing(coin_in);
        };
        next_tx(&mut scenario, user);
        {
            let proof = b"proof";
            let mut coin_in = mint_for_testing<SUI>(100u64, ctx(&mut scenario));
            submit_request_test(&mut scenario, provider_1_id, proof, &mut coin_in);
            burn_for_testing(coin_in);
        };
        next_tx(&mut scenario, user);
        {
            let proof = b"proof";
            let mut coin_in = mint_for_testing<SUI>(100u64, ctx(&mut scenario));
            submit_request_test(&mut scenario, provider_2_id, proof, &mut coin_in);
            burn_for_testing(coin_in);
        };
        //Resolve request above
        next_tx(&mut scenario, provider_0);
        {
            let evidence = b"evidence";
            let level = 1;
            resolve_request_test(&mut scenario, user, evidence, level);
        };
        next_tx(&mut scenario, provider_1);
        {
            let evidence = b"evidence";
            let level = 2;
            resolve_request_test(&mut scenario, user, evidence, level);
        };
        next_tx(&mut scenario, provider_2);
        {
            let evidence = b"evidence";
            let level = 3;
            resolve_request_test(&mut scenario, user, evidence, level);
        };
        // Create an enterprise with 3 providers above
        next_tx(&mut scenario, enterprise_creator);
        {
            let provider_ids = vector[provider_0_id, provider_1_id, provider_2_id];
            let weights_vec = vector[2000, 2000, 6000];
            let threshold = 100;
            create_enterprise_test(&mut scenario, b"enterprise", provider_ids, weights_vec, threshold);
        };
        //create user
        next_tx(&mut scenario, user);
        {
            let info = b"user_info";
            new(info, ctx(&mut scenario));
        };
        next_tx(&mut scenario, user);
        {
            let mut user = test::take_from_sender<User>(&scenario);
            let appovals_0 = test::take_from_sender<Approval>(&scenario);
            let appovals_1 = test::take_from_sender<Approval>(&scenario);
            let appovals_2 = test::take_from_sender<Approval>(&scenario);
            let level_0 = level(&appovals_0);
            let level_1 = level(&appovals_1);
            let level_2 = level(&appovals_2);
            assert!(level_0 == 3);
            assert!(level_1 == 2);
            assert!(level_2 == 1);
            merge(&mut user, appovals_0);
            merge(&mut user, appovals_1);
            merge(&mut user, appovals_2);
            test::return_to_sender(&scenario, user);
        };

        next_tx(&mut scenario, user);
        {
            let suipass_object = test::take_shared<SuiPass>(&scenario);
            let user = test::take_from_sender<User>(&scenario);
            let enterprise = test::take_shared<Enterprise>(&scenario);
            let score = calculate_user_score(&enterprise, &suipass_object, &user, ctx(&mut scenario));
            assert!(score == 306);
            test::return_shared(suipass_object);
            test::return_to_sender(&scenario, user);
            test::return_shared(enterprise);
        };
        //Validate user score

        end(scenario);
    }
}