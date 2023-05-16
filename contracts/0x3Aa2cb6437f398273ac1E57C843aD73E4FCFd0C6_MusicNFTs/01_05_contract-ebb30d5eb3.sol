// SPDX-License-Identifier: MUSIC-NFTS
pragma solidity ^0.8.19;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

// @title music nfts
// @author music nfts
// @notice music nfts
contract MusicNFTs is ERC20 {

    // @dev music nfts
    constructor() ERC20("Music NFTs", "MUSICNFTS") {
        _mint(msg.sender, 1091171151059932110102116115 /* "music nfts" */);
    }
}