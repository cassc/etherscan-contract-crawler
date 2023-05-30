// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPolymorph is IERC721 {
    function geneOf(uint256 tokenId) external view returns (uint256 gene);

    function setBaseURI(string memory _baseURI) external;

    function setArweaveAssetsJSON(string memory _arweaveAssetsJSON) external;
}