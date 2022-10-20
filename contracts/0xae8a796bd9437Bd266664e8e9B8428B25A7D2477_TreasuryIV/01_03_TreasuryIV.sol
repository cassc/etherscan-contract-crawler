pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Set and query IV
 */
contract TreasuryIV is Ownable {
    struct Price {
        uint256 frax;
        uint256 temple;
    }

    /// @notice intrinsinc value gauranteed by the protocol
    Price public intrinsicValueRatio;

    constructor(uint256 frax, uint256 temple) {
        intrinsicValueRatio.frax = frax;
        intrinsicValueRatio.temple = temple;
    }

    function setIV(uint256 frax, uint256 temple) external onlyOwner {
        intrinsicValueRatio.frax = frax;
        intrinsicValueRatio.temple = temple;
    }
}