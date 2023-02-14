// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./base/RolesManager.sol";
import "./interfaces/IPausable.sol";

contract SystemStopper is RolesManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _contracts;

    /**
    * @notice Configures the contract.
    * @dev Could be called by the owner in case of resetting addresses.
    * @param newContracts_ Contract addresses which can be paused.
    */
    function configure(address[] calldata newContracts_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address[] memory temp = new address[](_contracts.length());
        for (uint256 i = 0; i < _contracts.length(); i++) {
            temp[i] = _contracts.at(i);
        }
        for (uint256 j = 0; j < temp.length; j++) {
            _contracts.remove(temp[j]);
        }
        for (uint256 k = 0; k < newContracts_.length; k++) {
            _contracts.add(newContracts_[k]);
        }
    }

    /**
    * @notice Pauses all contracts that not yet paused.
    * @dev Could be called only by pausers.
    */
    function pauseAllContracts() external onlyRole(PAUSER_ROLE) {
        for (uint256 i = 0; i < _contracts.length(); i++) {
            address contractAddress = _contracts.at(i);
            if (!IPausable(contractAddress).paused()) {
                IPausable(contractAddress).pause();
            }
        }
    }

    /**
    * @notice Unpauses all contracts that not yet unpaused.
    * @dev Could be called only by pausers.
    */
    function unpauseAllContracts() external onlyRole(PAUSER_ROLE) {
        for (uint256 i = 0; i < _contracts.length(); i++) {
            address contractAddress = _contracts.at(i);
            if (IPausable(contractAddress).paused()) {
                IPausable(contractAddress).unpause();
            }
        }
    }

    /** 
    * @notice Returns an address of a specific contract in the list.
    * @dev The time complexity of this function is derived from EnumerableSet.Bytes32Set set so it's
    * able to be used freely in any internal operations (like DELEGATECALL use cases).
    * @param index_ Index.
    * @return Address of a contract.
    */
    function getContractAddressAt(uint256 index_) external view returns (address) {
        return _contracts.at(index_);
    }

    /** 
    * @notice Returns the amount of contracts in the list.
    * @dev The time complexity of this function is derived from EnumerableSet.Bytes32Set set so it's
    * able to be used in some small count iteration operations.
    * @return The exact amount of contracts in the list.
    */
    function getContractsLength() external view returns (uint256) {
        return _contracts.length();
    }

    /** 
    * @notice Checks whether `account_` is in the list on pause.
    * @dev The time complexity of this function is derived from EnumerableSet.Bytes32Set set so it's
    * able to be used in some small count iteration operations.
    * @param contract_ Contract address.
    * @return Boolean value indicating whether `account_` is in the list.
    */
    function isInListOnPause(address contract_) external view returns (bool) {
        return _contracts.contains(contract_);
    }
}