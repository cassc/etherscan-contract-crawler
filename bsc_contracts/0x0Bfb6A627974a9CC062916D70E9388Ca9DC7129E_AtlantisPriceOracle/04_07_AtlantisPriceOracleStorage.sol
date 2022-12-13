// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.13;

import "./interfaces/AggregatorV2V3Interface.sol";

contract AtlantisPriceOracleAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;

    /**
     * @notice Active brains of Atlantis Binance Oracle
     */
    address public implementation;

    /**
     * @notice Pending brains of Atlantis Binance Oracle
     */
    address public pendingAtlantisPriceOracleImplementation;
}

contract AtlantisPriceOracleStorage is AtlantisPriceOracleAdminStorage {
    enum OracleType {
        CHAINLINK,
        BINANCE
    }

    mapping(uint8 => mapping(bytes32 => AggregatorV2V3Interface)) internal feeds;

    mapping(address => uint) internal prices;
}