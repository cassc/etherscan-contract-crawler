// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title container of the data types
 * @author
 */
library DataTypes {
    /**
     * @notice
     * @dev
     * @param
     * @param
     */
    struct Tier {
        uint256 from;
        uint256 to;
        uint256 pieces;
        Counters.Counter tokenCount;
    }
}