// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { HashnoteWhitelistManager } from "../utils/HashnoteWhitelistManager.sol";

/**
 * @title   MockWhitelistV2
 * @notice  Mock contract to test upgradability
 */
contract MockWhitelistV2 is HashnoteWhitelistManager {
    constructor() HashnoteWhitelistManager() { }

    function version() external pure returns (uint256) {
        return 2;
    }
}