// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Libraries/Data_Structures.sol";
import "./Libraries/Fees_Functions.sol";

interface ApeMax_Public {
    function get_contract(uint64 contract_index) external view returns (Data_Structures.Contract memory);
    function get_stake(address stake_address) external view returns (Data_Structures.Stake memory);
    function get_global() external view returns (Data_Structures.Global memory);
}

// is Initializable
contract ApeMax_Getter {

    ApeMax_Public internal apemax_token;

    // function initialize(address apemax_contract_address) public initializer {
    constructor(address apemax_contract_address) {
        apemax_token = ApeMax_Public(apemax_contract_address);
    }

    function get_unclaimed_creator_rewards(
        uint64 contract_index
        )
        public view
        returns (uint128)
    {
        return apemax_token.get_contract(contract_index).unclaimed_creator_rewards;
    }

    function get_unclaimed_ministerial_rewards()
        public view
        returns (uint128)
    {
        return apemax_token.get_global().unclaimed_ministerial_rewards;
    }

    function get_staking_fees(
        uint128 amount_staked,
        uint64 contract_index
        )
        public view
        returns (Data_Structures.Split memory)
    {

        Data_Structures.Contract memory Contract = apemax_token.get_contract(contract_index);

        return Fees_Functions.calculate_inbound_fees(
            amount_staked,
            Contract.royalties,
            Contract.total_staked
        );
    }

    function get_staking_rewards(
        address stake_address,
        uint64 contract_index
        )
        public view
        returns (uint128)
    {
        // Create storage / pointer references to make code cleaners
        Data_Structures.Stake memory Stake = apemax_token.get_stake(stake_address);
        Data_Structures.Contract memory Contract = apemax_token.get_contract(contract_index);

        // Exit early if no claim so state is not affected
        uint32 time_elapsed = uint32(block.timestamp) - Stake.init_time;
        if (time_elapsed < Stake.delay_nerf) {
            return 0;
        }

        // Get finders fees owed
        uint160 relevant_multiple = Contract.total_multiple - Stake.multiple;
        uint256 finders_fees =
            relevant_multiple *
            Stake.amount_staked_raw *
            Constants.finders_fee / 10000
            / Constants.decimals;
        
        // Get relevant portions for computation
        uint160 relevant_units =
            Contract.reward_units -
            Stake.historic_reward_units;

        // Compute rewards
        uint256 rewards = 
            Stake.amount_staked *
            relevant_units /
            Constants.decimals;
        
         // Add in finders fees
        rewards += finders_fees;

        // Nerf rewards for delay only for the first claim
        if (Stake.has_been_delay_nerfed == false) {
            uint256 nerfed_rewards =
                rewards *
                (time_elapsed - Stake.delay_nerf) /
                time_elapsed;
            
            rewards = nerfed_rewards;
        }

        return uint128(rewards);
    }

    function get_staking_rewards_batch(
        address[] memory stake_addresses,
        uint64[] memory contract_indexes
        )
        public view
        returns (uint128[] memory)
    {
        require(
            stake_addresses.length == contract_indexes.length,
            "Invalid request"
        );

        uint128[] memory rewards_array = new uint128[](stake_addresses.length);

        for (uint256 i = 0; i < stake_addresses.length; i++) {
            uint128 rewards = get_staking_rewards(
                stake_addresses[i],
                contract_indexes[i]
            );
            rewards_array[i] = rewards;
        }

        return rewards_array;
    }

    function get_contract_ranking(
        uint32 results_per_age,
        uint64 page_number,
        bool high_to_low
        )
        public view
        returns (Data_Structures.Contract[] memory)
    {
        uint64 contract_count = apemax_token.get_global().contract_count;

        uint64 start_index = page_number * results_per_age;
        uint64 end_index = start_index + results_per_age;
        end_index = end_index > contract_count ? contract_count : end_index;

        Data_Structures.Contract[] memory sorted_contracts = new Data_Structures.Contract[](end_index - start_index);

        for (uint64 i = 0; i < contract_count; i++) {
            Data_Structures.Contract memory current_contract = apemax_token.get_contract(i);
            for (uint64 j = start_index; j < end_index; j++) {

                bool should_replace = high_to_low
                    ? current_contract.total_staked > sorted_contracts[j - start_index].total_staked
                    : current_contract.total_staked < sorted_contracts[j - start_index].total_staked;
                
                if (should_replace) {
                    for (uint64 k = end_index - 1; k > j; k--) {
                        sorted_contracts[k - start_index] = sorted_contracts[k - start_index - 1];
                    }
                    sorted_contracts[j - start_index] = current_contract;
                    break;
                }

            }
        }

        return sorted_contracts;
    }
}