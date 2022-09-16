// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/StakingNFT/StakingNFT.sol";

/// @custom:salt PublicStaking
/// @custom:deploy-type deployUpgradeable
contract PublicStaking is StakingNFT {
    constructor() StakingNFT() {}

    function initialize() public onlyFactory initializer {
        __stakingNFTInit("APSNFT", "APS");
    }
}