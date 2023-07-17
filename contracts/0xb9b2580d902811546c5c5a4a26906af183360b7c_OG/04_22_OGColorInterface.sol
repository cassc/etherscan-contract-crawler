// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title The interface to access the OGColor contract to get the colors to render OG svgs
 * @author nfttank.eth
 */
interface OGColorInterface {
    function getColors(address forAddress, uint256 tokenId) external view returns (string memory back, string memory frame, string memory digit, string memory slug);
    function getOgAttributes(address forAddress, uint256 tokenId) external view returns (string memory);
}