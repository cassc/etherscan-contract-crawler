// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Hashes } from "./Hashes.sol";

contract TestHashes is Hashes(1000000000000000000, 100, 1000, "https://example.com/") {
    function setNonce(uint256 _nonce) public nonReentrant {
        nonce = _nonce;
    }
}