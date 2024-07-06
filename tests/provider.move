#[test_only]
module suipass::provider_test {
    use sui::test_scenario::{Self as test, Scenario, next_tx, ctx, end, begin};
    use suipass::suipass::{Self, SuiPass, AdminCap, submit_request, resolve_request, get_score};
    use suipass::provider::{ProviderCap};

    use sui::sui::SUI;
    use sui::coin::{mint_for_testing, burn_for_testing};

    #[test]
    fun create_provider(){
        let admin = @0x1;
        let provider = @0x2;
        let mut scenario =  begin(admin);
        {
            suipass::init_for_testing(ctx(&mut scenario));
        };

        next_tx(&mut scenario, admin);

        {
            let admin_cap = test::take_from_sender<AdminCap>(&scenario);
            let mut suipass_obj = scenario.take_shared<SuiPass>();
            let level_score_distribution = vector[50, 50];
            suipass::add_provider(
                &admin_cap, 
                &mut suipass_obj,
                provider,
                b"provider::test",
                b"metadata::test",
                0,
                0,
                2,
                level_score_distribution,
                400,
                ctx(&mut scenario)
            );
            test::return_to_sender(&scenario, admin_cap);
            test::return_shared(suipass_obj);
        };

        next_tx(&mut scenario, provider);
        {
            let provider_cap = test::take_from_sender<ProviderCap>(&scenario);
            let provider_id = provider_cap.id_from_cap();
            let mut sui_pass_obj = test::take_shared<SuiPass>(&scenario);
            let proof = b"proof";
            let mut coin_in = mint_for_testing<SUI>(100u64, ctx(&mut scenario));
            submit_request(&mut sui_pass_obj,provider_id,proof,&mut coin_in, ctx(&mut scenario));
            test::return_to_sender(&scenario, provider_cap);
            test::return_shared(sui_pass_obj);
            burn_for_testing(coin_in);
        };
        next_tx(&mut scenario, provider);
        {
            let provider_cap = test::take_from_sender<ProviderCap>(&scenario);
            let mut sui_pass_obj = test::take_shared<SuiPass>(&scenario);
            let evidence = b"evidence";
            let level = 1;
            resolve_request(&provider_cap, &mut sui_pass_obj, provider, evidence,level, ctx(&mut scenario));
            test::return_to_sender(&scenario, provider_cap);
            test::return_shared(sui_pass_obj);
        };

        next_tx(&mut scenario, provider);
        {
            let provider_cap = test::take_from_sender<ProviderCap>(&scenario);
            let provider_id = provider_cap.id_from_cap();
            let suipass_obj = test::take_shared<SuiPass>(&scenario);
            let level = 1;
            let score = get_score(&suipass_obj, &provider_id,level);
            assert!(score == 200);
            test::return_shared(suipass_obj);
            test::return_to_sender(&scenario, provider_cap);
        };

        end(scenario);
    }
}