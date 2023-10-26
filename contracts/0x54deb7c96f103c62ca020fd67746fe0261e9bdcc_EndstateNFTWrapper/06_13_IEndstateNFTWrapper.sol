// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IEndstateNFTWrapper {
    struct DropInfo {
        address dropAddress;
        uint256 totalSupply;
    }

    event DropAdded(address dropAddress, uint256 totalSupply);
    event DropRemoved(address dropAddress);

    function isValidNFT(address dropAddress, uint256 id)
        external
        view
        returns (bool);
}