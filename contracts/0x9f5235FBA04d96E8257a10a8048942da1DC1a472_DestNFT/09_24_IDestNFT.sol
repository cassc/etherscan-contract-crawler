//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IDestNFT is IERC721 {

    function randomMint(address to) external;

    function randomMintCallback(uint256 randomness, address recipient) external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function snapshotId() external view returns (uint256);

    function snapshot() external returns (uint256);

    function setRoyalty(address royaltyReceiver_, uint24 royaltyFeesInBips_) external;

    function updateMetadataHashList(string[] memory metahashes) external;
}