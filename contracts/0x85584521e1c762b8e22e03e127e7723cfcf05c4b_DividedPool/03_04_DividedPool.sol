// SPDX-License-Identifier: MIT
// Author: Daniel Von Fange (@DanielVF)

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {IDividedFactory} from "./interfaces/IDividedFactory.sol";

pragma solidity ^0.8.16;

contract DividedPool is ERC20 {
    // You probably want to use a router to interact with this pool contract.

    ERC721 public immutable collection;
    uint256 public constant LP_PER_NFT = 100e18;

    event NftOut(address indexed collection, uint256 indexed tokenId, address indexed user);
    event Swap();

    constructor() ERC20("", "", 18) {
        ERC721 _collection = ERC721(IDividedFactory(msg.sender).deployNftContract());
        collection = _collection;
        name = string.concat("Divided ", _collection.name());
        symbol = string.concat("d", _collection.symbol());
    }

    function swap(uint256[] calldata tokensOut, address from, address to) external returns (int128) {
        // NFTs are moved in before call to swap
        for (uint256 i = 0; i < tokensOut.length; i++) {
            uint256 tokenId = tokensOut[i];
            collection.transferFrom(address(this), to, tokenId);
            emit NftOut(address(collection), tokenId, to);
        }
        // Balance LP tokens to/from user according to NFT change
        uint256 expected = LP_PER_NFT * collection.balanceOf(address(this));
        require(expected < type(uint128).max);
        uint256 actual = totalSupply;
        if (actual < expected) {
            uint256 amount = expected - actual;
            _mint(to, amount);
            return int128(uint128(amount));
        } else if (actual > expected) {
            uint256 amount = actual - expected;
            if (from != msg.sender) {
                uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
                if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
            }
            _burn(from, amount);
            return int128(uint128(amount)) * -1;
        } else {
            emit Swap();
            return 0;
        }
    }
}