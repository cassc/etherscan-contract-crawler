// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC6551Registry} from './ERC6551Registry.sol';

contract CNPYRegistry {
    ERC6551Registry public immutable registory;
    address public immutable implementation;
    address public immutable tokenContract;

    constructor(ERC6551Registry _registory, address _implementation, address _tokenContract) {
        registory = _registory;
        implementation = _implementation;
        tokenContract = _tokenContract;
    }

    function account(uint256 tokenId) external view returns (address) {
        return registory.account(implementation, block.chainid, tokenContract, tokenId, 0);
    }

    function createAccount(uint256 tokenId) external returns (address) {
        return registory.createAccount(implementation, block.chainid, tokenContract, tokenId, 0, '');
    }
}