// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IBaseNFT is IERC721Upgradeable {
    function setBaseTokenURI(string calldata baseTokenURI) external;

    function setCollectionURI(string calldata baseTokenURI) external;

    function contractURI() external view returns (string memory);
}