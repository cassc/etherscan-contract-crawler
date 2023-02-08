// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

// author: jolan.eth
abstract contract Registry {
    struct RCSA {
        address NFTContract;
        uint256 id;
    }

    mapping(uint256 => RCSA) REKTRegistry;
    
    function getREKTRegistry(uint256 id)
    public view returns (RCSA memory) {
        RCSA storage Object = REKTRegistry[id];
        return Object;
    }

    function setRCSARegistration(uint256 tokenId, address NFTContract, uint256 id)
    internal {
        REKTRegistry[tokenId] = RCSA(
            NFTContract, id
        );
    }
}