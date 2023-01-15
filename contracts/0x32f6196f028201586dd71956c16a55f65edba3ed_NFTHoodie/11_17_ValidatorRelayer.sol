// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract ValidatorRelayer is Ownable {
    address public relayer;

    error InvalidHash();
    error InvalidSignature();

    constructor(address relayer_) {
        relayer = relayer_;
    }

    function _validate(
        bytes32 hash,
        bytes memory signature,
        bytes memory request
    ) internal view {
        if (hash != keccak256(request)) revert InvalidHash();
        if (ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature) != relayer) revert InvalidSignature();
    }

    function setRelayer(address relayer_) public onlyOwner {
        relayer = relayer_;
    }
}