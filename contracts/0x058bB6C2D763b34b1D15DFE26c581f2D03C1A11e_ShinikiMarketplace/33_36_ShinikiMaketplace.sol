// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ShinikiMarketplaceCore.sol";
import "./TransferManager.sol";

contract ShinikiMarketplace is
    ShinikiMarketplaceCore,
    TransferManager
{
    function initialize(address operator) external initializer {
        __Context_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __TransferExecutor_init_unchained();
        __TransferManager_init_unchained();
        __OrderValidator_init_unchained();

        TRUSTED_PARTY = 0x86B5E0Db161f38abf70Ace5e02a08F7f2856B80D;
        isOperators[operator] = true;
    }
}