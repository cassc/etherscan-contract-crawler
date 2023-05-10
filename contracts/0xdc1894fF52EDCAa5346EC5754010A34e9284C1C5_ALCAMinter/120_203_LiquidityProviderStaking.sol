// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/StakingNFT/StakingNFT.sol";

/// @custom:salt LiquidityProviderStaking
/// @custom:deploy-type deployUpgradeable
contract LiquidityProviderStaking is StakingNFT {
    constructor() StakingNFT() {}

    function initialize() public onlyFactory initializer {
        __stakingNFTInit("ALQSNFT", "ALQS");
    }
}