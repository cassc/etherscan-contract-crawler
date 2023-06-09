//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
IGoblinRenderer.sol

Contract by @NftDoyler
*/

interface IGoblinRenderer {
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function tokenIdToSVG(uint256 _tokenId) external view returns (string memory);
}