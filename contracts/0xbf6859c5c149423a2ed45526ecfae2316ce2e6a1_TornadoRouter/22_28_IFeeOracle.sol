// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// OZ Imports

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Tornado imports

import { ITornadoInstance } from "tornado-anonymity-mining/contracts/interfaces/ITornadoInstance.sol";

// Local imports

import { InstanceState } from "../InstanceRegistry.sol";

/**
 * @notice Fee data which is valid across all instances, stored in the fee oracle manager.
 */
struct FeeData {
    uint160 amount;
    uint32 percent;
    uint32 updateInterval;
    uint32 lastUpdateTime;
}

/**
 * @notice Fee data which is only used and constructed when updating and oracle fee or getting it.
 */
struct FeeDataForOracle {
    uint160 amount;
    uint32 percent;
    uint32 divisor;
    uint32 updateInterval;
    uint32 lastUpdateTime;
}

/**
 * @notice This is the full bundled data for an instance.
 */
struct InstanceWithFee {
    ITornadoInstance logic;
    InstanceState state;
    FeeDataForOracle fee;
}

/**
 * @title IFeeOracle
 * @author AlienTornadosaurusHex
 * @notice The interface which all fee oracles for Tornado should implement.
 */
interface IFeeOracle {
    /**
     * @dev This function is intended to allow oracles to configure their state
     */
    function update(IERC20 _torn, InstanceWithFee memory _instance) external;

    /**
     * @dev This function must return a uint160 compatible TORN fee
     */
    function getFee(IERC20 _torn, InstanceWithFee memory _instance) external view returns (uint160);
}