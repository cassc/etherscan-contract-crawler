// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity 0.8.11;
pragma abicoder v2;

import "./openzeppelin/Address.sol";

contract WorkerConfig {
    using Address for address;

    struct OracleUpdate {
        address contractAddr;
        address newOracle;
    }

    /// @notice emitted when the rng oracles are changed to a new address
    event OracleChanged(address indexed contractAddr, address indexed oldOracle, address indexed newOracle);

    /// @notice emitted when an emergency is declared!
    event Emergency(bool indexed enabled);

    /// @dev if false, emergency mode is active!
    bool private noGlobalEmergency_;

    /// @dev for migrations
    uint256 private version_;

    /// @dev can set emergency mode
    address private emergencyCouncil_;

    /// @dev can set emergency mode and update contract props
    address private operator_;

    /// @dev token => oracle
    mapping(address => address) private oracles_;

    /**
     * @notice intialise the worker config for each of the tokens in the map
     *
     * @param _operator to use that can update the worker config
     * @param _emergencyCouncil to use that can set emergency mode
     */
    function init(
        address _operator,
        address _emergencyCouncil
    ) public {
        require(version_ == 0, "contract is already initialised");
        version_ = 1;

        operator_ = _operator;

        emergencyCouncil_ = _emergencyCouncil;

        noGlobalEmergency_ = true;
    }

    function noGlobalEmergency() public view returns (bool) {
        return noGlobalEmergency_;
    }

    /// @notice updates the trusted oracle to a new address
    function updateOracles(OracleUpdate[] memory newOracles) public {
        require(noGlobalEmergency(), "emergency mode!");
        require(msg.sender == operator_, "only operator account can use this");

        for (uint i = 0; i < newOracles.length; i++) {
            OracleUpdate memory oracle = newOracles[i];

            emit OracleChanged(oracle.contractAddr, oracles_[oracle.contractAddr], oracle.newOracle);

            oracles_[oracle.contractAddr] = oracle.newOracle;
        }
    }

    function getWorkerAddress(address contractAddr) public view returns (address) {
        require(noGlobalEmergency(), "emergency mode!");

        return oracles_[contractAddr];
    }

    function getWorkerAddress() public view returns (address) {
        require(noGlobalEmergency(), "emergency mode!");

        return oracles_[msg.sender];
    }

    function enableEmergencyMode() public {
        bool authorised = msg.sender == operator_ || msg.sender == emergencyCouncil_;
        require(authorised, "only the operator or emergency council can use this");

        noGlobalEmergency_ = false;
        emit Emergency(true);
    }

    /**
     * @notice disables emergency mode, following presumably a contract upgrade
     * @notice (operator only)
     */
    function disableEmergencyMode() public {
        require(msg.sender == operator_, "only the operator account can use this");

        noGlobalEmergency_ = true;

        emit Emergency(false);
    }
}