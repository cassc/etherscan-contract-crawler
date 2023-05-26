// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/// All the whitelists logics that want to be used in the NFTs contracts must implement this interface.
///
/// By implementing this interface, can be transfered.
///

interface IWhitelist {
    /**
     * @param _who the address that wants to transfer a NFT
     * @dev Returns true if address has permission to transfer a NFT
     */
    function canTransfer(address _who) external returns (bool);
}