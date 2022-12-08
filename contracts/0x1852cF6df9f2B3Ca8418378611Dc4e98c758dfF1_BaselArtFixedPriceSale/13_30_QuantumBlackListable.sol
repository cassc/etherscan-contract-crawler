// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./QuantumBlackList.sol";

// contracts that want to implement blackListing on specific methods (e.g. minting) can and use the functions in this library
// due to issues with upgrading storage on already deployed contracts, the blackListContractAddress must be stored in the contract itself

library QuantumBlackListable {
    error BlackListedAddress(address _address);
    error InvalidBlackListAddress();
    error BlackListedAddressNotSet();

    function isBlackListed(address user, address blContractAddress)
        internal
        view
        returns (bool)
    {
        QuantumBlackList qbl = QuantumBlackList(blContractAddress);

        if (blContractAddress == address(0)) {
            revert BlackListedAddressNotSet();
        }

        if (qbl.isBlackListed(user)) {
            return true;
        }
        return false;
    }
}