// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./ILyfeblocHistory.sol";
import "./PermissionGroupsNoModifiers.sol";

/**
 *   @title lyfeblocHistory contract
 *   The contract provides the following functions for lyfeblocStorage contract:
 *   - Record contract changes for a set of contracts
 */
contract LyfeblocHistory is ILyfeblocHistory, PermissionGroupsNoModifiers {
    address public lyfeblocStorage;
    address[] internal contractsHistory;

    constructor(address _admin) public PermissionGroupsNoModifiers(_admin) {}

    event LyfeblocStorageUpdated(address newStorage);

    modifier onlyStorage() {
        require(msg.sender == lyfeblocStorage, "only storage");
        _;
    }

    function setStorageContract(address _lyfeblocStorage) external {
        onlyAdmin();
        require(_lyfeblocStorage != address(0), "storage 0");
        emit LyfeblocStorageUpdated(_lyfeblocStorage);
        lyfeblocStorage = _lyfeblocStorage;
    }

    function saveContract(address _contract) external override onlyStorage {
        if (contractsHistory.length > 0) {
            // if same address, don't do anything
            if (contractsHistory[0] == _contract) return;
            // otherwise, update history
            contractsHistory.push(contractsHistory[0]);
            contractsHistory[0] = _contract;
        } else {
            contractsHistory.push(_contract);
        }
    }

    /// @notice Should be called off chain
    /// @dev Index 0 is currently used contract address, indexes > 0 are older versions
    function getContracts() external override view returns (address[] memory) {
        return contractsHistory;
    }
}