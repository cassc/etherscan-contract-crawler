// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./base/MultipleRewardPool.sol";

contract PancakeSwapPool is MultipleRewardPool {
    /**
    * @param cakeLP_ Pancake LPs token address.
    * @param poolRewardDistributor_ PoolRewardDistributor contract address.
    * @param seniorage_ Seniorage contract address.
    * @param rewardTokens_ Reward token addresses.
    */
    constructor(
        address cakeLP_,
        address poolRewardDistributor_,
        address seniorage_,
        address[] memory rewardTokens_
    )
        MultipleRewardPool(
            cakeLP_,
            poolRewardDistributor_,
            seniorage_,
            rewardTokens_
        )
    {}
}