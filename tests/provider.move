#[test_only]
module suipass::provider_test {
    use sui::test_scenario::{Self as test, next_tx, ctx, end, begin, Scenario};
    use suipass::suipass::{Self, SuiPass, AdminCap, submit_request, resolve_request, get_score};
    use suipass::provider::{ProviderCap};

    use sui::sui::SUI;
    use sui::coin::{mint_for_testing, burn_for_testing};

    public fun creat_provider(
        scenario: &mut Scenario, 
        admin: address, 
        provider_creator: address, 
        total_levels: u16, 
        level_score_distribution: vector<u16>,
    ){
        //scenario must begin with admin address
        next_tx(scenario, admin);
        {
            let admin_cap = test::take_from_sender<AdminCap>(scenario);
            let mut suipass_obj = scenario.take_shared<SuiPass>();
            suipass::add_provider(
                &admin_cap, 
                &mut suipass_obj,
                provider_creator,
                b"provider::test",
                b"metadata::test",
                0,
                0,
                total_levels,
                level_score_distribution,
                ctx(scenario)
            );
            test::return_to_sender(scenario, admin_cap);
            test::return_shared(suipass_obj);
        };
    }

    public fun submit_request_test(
        scenario: &mut Scenario, 
        provider_id: ID, 
        proof: vector<u8>, 
        coin_in: &mut sui::coin::Coin<SUI>
    ){
        {
            let mut sui_pass_obj = test::take_shared<SuiPass>(scenario);
            submit_request(&mut sui_pass_obj,provider_id,proof, coin_in, ctx(scenario));
            test::return_shared(sui_pass_obj);
        };
    }

    public fun resolve_request_test(scenario: &mut Scenario, requester: address, evidence: vector<u8>, level: u16){
        //Sender must set to provider_creator
        {
            let provider_cap = test::take_from_sender<ProviderCap>(scenario);
            let mut sui_pass_obj = test::take_shared<SuiPass>(scenario);
            resolve_request(&provider_cap, &mut sui_pass_obj, requester, evidence, level, ctx(scenario));
            test::return_to_sender(scenario, provider_cap);
            test::return_shared(sui_pass_obj);
        }
    }

    #[test]
    fun calculate_score(){
        let admin = @0x1;
        let provider = @0x2;
        let mut scenario =  begin(admin);
        let provider_id: ID;
        let total_level = 2;
        let level_score_distribution = vector[50, 50];
        {
            suipass::init_for_testing(ctx(&mut scenario));
        };
        creat_provider(&mut scenario, admin, provider, total_level, level_score_distribution);

        next_tx(&mut scenario, provider);
        let provider_cap = test::take_from_sender<ProviderCap>(&scenario);
        provider_id = provider_cap.id_from_cap();
        test::return_to_sender(&scenario, provider_cap);

        next_tx(&mut scenario, provider);
        {
            let proof = b"proof";
            let mut coin_in = mint_for_testing<SUI>(100u64, ctx(&mut scenario));
            submit_request_test(&mut scenario, provider_id, proof, &mut coin_in);
            burn_for_testing(coin_in);
        };

        next_tx(&mut scenario, provider);
        {
            let evidence = b"evidence";
            let level = 1;
            resolve_request_test(&mut scenario, provider, evidence, level);
        };

        next_tx(&mut scenario, provider);
        {
            let provider_cap = test::take_from_sender<ProviderCap>(&scenario);
            let provider_id = provider_cap.id_from_cap();
            let suipass_obj = test::take_shared<SuiPass>(&scenario);
            let level = 1;
            let score = get_score(&suipass_obj, &provider_id,level);
            assert!(score == 5000);
            test::return_shared(suipass_obj);
            test::return_to_sender(&scenario, provider_cap);
        };

        end(scenario);
    }
}