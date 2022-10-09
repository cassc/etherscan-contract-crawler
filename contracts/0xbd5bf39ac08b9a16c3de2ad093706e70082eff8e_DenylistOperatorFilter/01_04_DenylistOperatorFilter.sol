// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IOperatorFilter} from "./interfaces/IOperatorFilter.sol";

contract DenylistOperatorFilter is Ownable, IOperatorFilter {
    mapping(address => bool) private blockedAddresses_;
    mapping(bytes32 => bool) private blockedCodeHashes_;



    function setAddressBlocked(address a, bool blocked) external onlyOwner {
        blockedAddresses_[a] = blocked;
    }

    function setCodeHashBlocked(bytes32 codeHash, bool blocked)
        external
        onlyOwner
    {
        if (codeHash == keccak256(""))
            revert("DenylistOperatorFilter: can't block EOAs");
        blockedCodeHashes_[codeHash] = blocked;
    }

    function mayTransfer(address operator) external view returns (bool) {
        if (blockedAddresses_[operator]) return false;
        if (blockedCodeHashes_[operator.codehash]) return false;
        return true;
    }

    function isAddressBlocked(address a) external view returns (bool) {
        return blockedAddresses_[a];
    }

    function isCodeHashBlocked(bytes32 codeHash) external view returns (bool) {
        return blockedCodeHashes_[codeHash];
    }

    /// Convenience function to compute the code hash of an arbitrary contract;
    /// the result can be passed to `setBlockedCodeHash`.
    function codeHashOf(address a) external view returns (bytes32) {
        return a.codehash;
    }
}