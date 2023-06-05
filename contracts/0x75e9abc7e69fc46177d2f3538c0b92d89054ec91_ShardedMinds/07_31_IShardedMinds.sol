// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IShardedMinds is IERC721 {
    function geneOf(uint256 tokenId) external view returns (uint256 gene);

    function mint() external payable;

    function presaleMint(uint256 amount) external payable;

    function reserveMint(uint256 amount) external;

    function bulkBuy(uint256 amount) external payable;

    function lastTokenId() external view returns (uint256 tokenId);

    function setShardedMindsPrice(uint256 newLobsterPrice) external;

    function setMaxSupply(uint256 maxSupply) external;

    function setBulkBuyLimit(uint256 bulkBuyLimit) external;

    function setBaseURI(string memory _baseURI) external;
}