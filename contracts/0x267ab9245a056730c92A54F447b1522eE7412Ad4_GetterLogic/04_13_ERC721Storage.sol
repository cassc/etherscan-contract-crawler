//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct ERC721State {
    // Token name
    string _name;
    // Token symbol
    string _symbol;
    // Mapping from token ID to owner address
    mapping(uint256 => address) _owners;
    // Mapping owner address to token count
    mapping(address => uint256) _balances;
    // Mapping from token ID to approved address
    mapping(uint256 => address) _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;
}

library ERC721Storage {
    bytes32 constant STORAGE_NAME = keccak256("extendable:erc721:base");

    function _getState() internal view returns (ERC721State storage erc721State) {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            erc721State.slot := position
        }
    }
}