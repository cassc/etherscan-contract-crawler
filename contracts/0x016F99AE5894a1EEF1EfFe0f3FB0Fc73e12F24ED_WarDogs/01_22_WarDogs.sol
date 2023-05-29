// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./NftMerkleBase.sol";

contract WarDogs is NftMerkleBase {
    constructor(address payable payeeAddress,
        string memory envBaseURI,
        string memory envContractURI,
        string memory name_,
        string memory symbol_,
        bytes32 merkleRoot) NftMerkleBase(payeeAddress, envBaseURI, envContractURI, name_, symbol_, merkleRoot) {}
}