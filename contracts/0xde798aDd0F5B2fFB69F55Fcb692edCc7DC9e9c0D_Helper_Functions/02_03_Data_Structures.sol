// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library Data_Structures {

    struct Split {
        uint128 staker;
        uint128 tax;
        uint128 ministerial;
        uint128 creator;
        uint128 total;
    }

    struct Stake {

        // Used in calculating the finders fees owed to a user
        uint160 multiple;

        // The historic level of the reward units at the last claim...
        uint160 historic_reward_units;

        // Amount user has comitted to this stake
        uint128 amount_staked;

        // Amount user sent to stake, needed for fees calculation
        uint128 amount_staked_raw;

        // Address of the staker
        address staker_address;

        // The address of the contract corresponding to this stake
        uint64 contract_index;

        // The amount of time you need to wait for your first claim. Basically the waiting list time
        uint32 delay_nerf;

        // Stake init time
        uint32 init_time;

        // If the stake has been nerfed with regards to thr waitlist
        bool has_been_delay_nerfed;
        
    }


    struct Contract {

        // The total amount of units so we can know how much a token staked is worth
        // calculated as incoming rewards * 1-royalty / total staked
        uint160 reward_units;

        // Used in calculating staker finder fees
        uint160 total_multiple;

        // The total amount of staked comitted to this contract
        uint128 total_staked;

        // Rewards allocated for the creator of this stake, still unclaimed
        uint128 unclaimed_creator_rewards;

        // The contract address of this stake
        address contract_address;
        
        // The assigned address of the creator
        address owner_address;

        // The rate of the royalties configured by the creator
        uint16 royalties;
        
    }

    struct Global {

        // Used as a source of randomness
        uint256 random_seed;

        // The total amount staked globally
        uint128 total_staked;

        // The total amount of ApeMax minted
        uint128 total_minted;

        // Unclaimed amount of ministerial rewards
        uint128 unclaimed_ministerial_rewards;

        // Extra subsidy lost to mint nerf. In case we want to do something with it later
        uint128 nerfed_subsidy;

        // The number of contracts
        uint64 contract_count;

        // The time at which this is initialized
        uint32 init_time;

        // The last time we has to issue a tax, used for subsidy range calulcation
        uint32 last_subsidy_update_time;

        // The last time a token was minted
        uint32 last_minted_time;

    }

}