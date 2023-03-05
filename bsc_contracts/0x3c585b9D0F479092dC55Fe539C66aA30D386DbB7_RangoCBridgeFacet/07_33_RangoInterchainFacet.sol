// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibInterchain.sol";

contract RangoInterchainFacet {
    /// Events ///

    /// @notice Notifies that a new contract is whitelisted
    /// @param _dapp The address of the contract
    event MessagingDAppWhitelisted(address _dapp);

    /// @notice Notifies that a new contract is blacklisted
    /// @param _dapp The address of the contract
    event MessagingDAppBlacklisted(address _dapp);

    /// @notice Adds a contract to the whitelisted messaging dApps that can be called
    /// @param _dapp The address of dApp
    function addMessagingDAppContract(address _dapp) public {
        LibDiamond.enforceIsContractOwner();
        LibInterchain.addMessagingDApp(_dapp);
        emit MessagingDAppWhitelisted(_dapp);
    }

    /// @notice Adds a list of contracts to the whitelisted messaging dApps that can be called
    /// @param _dapps The addresses of dApps
    function addMessagingDApps(address[] calldata _dapps) external {
        LibDiamond.enforceIsContractOwner();
        for (uint i = 0; i < _dapps.length; i++)
            addMessagingDAppContract(_dapps[i]);
    }

    /// @notice Removes a contract from dApps that can be called
    /// @param _dapp The address of dApp
    function removeMessagingDAppContract(address _dapp) external {
        LibDiamond.enforceIsContractOwner();
        LibInterchain.removeMessagingDApp(_dapp);
        emit MessagingDAppBlacklisted(_dapp);
    }
}