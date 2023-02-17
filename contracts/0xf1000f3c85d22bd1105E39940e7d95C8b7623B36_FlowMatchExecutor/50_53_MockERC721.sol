// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract MockERC721 is ERC721URIStorage, Ownable {
    uint256 public numMints;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        for (uint256 i = 0; i < 100; i++) {
            _safeMint(msg.sender, numMints++);
        }
    }
}