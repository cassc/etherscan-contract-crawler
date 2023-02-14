// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./base/SingleRewardPool.sol";

contract BiSwapPool is SingleRewardPool {
    /**
    * @param bswLP_ Biswap LPs token address.
    * @param zoinks_ Zoinks token address.
    * @param poolRewardDistributor_ PoolRewardDistributor contract address.
    * @param seniorage_ Seniorage contract address.
    */
    constructor(
        address bswLP_,
        address zoinks_,
        address poolRewardDistributor_,
        address seniorage_
    )
        SingleRewardPool(
            bswLP_,
            zoinks_,
            poolRewardDistributor_,
            seniorage_
        )
    {}
}