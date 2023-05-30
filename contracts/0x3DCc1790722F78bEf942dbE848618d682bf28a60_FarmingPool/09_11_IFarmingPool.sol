// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "./IFungibleToken.sol";

interface IFarmingPool {
    function initialize(
        IFungibleToken _depositToken,
        IFungibleToken _rewardToken,
        address _mintFromWallet,
        address _admin,
        uint256 _tokensPerBlock,
        uint256 _startBlock
    ) external;
}