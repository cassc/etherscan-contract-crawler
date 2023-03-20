// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title INote
 * @author Spice Finance Inc
 */
interface INote is IERC721 {
    function mint(address to, uint256 tokenId) external returns (uint256);

    function burn(uint256 tokenId) external;
}