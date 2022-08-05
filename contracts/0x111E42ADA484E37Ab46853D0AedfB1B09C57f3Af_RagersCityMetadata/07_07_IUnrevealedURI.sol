// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// @title:  Ragers City
// @desc:   Ragers City is a next-gen decentralized Manga owned by the community, featuring a collection of 5000 NFTs.
// @team:   https://twitter.com/RagersCity
// @author: https://linkedin.com/in/antoine-andrieux
// @url:    https://ragerscity.com

interface IUnrevealedURI {
    
    event TokenURIRevealed(string revealedURI);

    // Reveal an unrevealed URI
    function reveal(bytes calldata key) external returns (string memory revealedURI);

    // Encrypt/decrypt data (CTR encryption mode)
    function encryptDecrypt(bytes memory data, bytes calldata key) external pure returns (bytes memory result);
}