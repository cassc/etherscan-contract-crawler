// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IGmDao is IERC721, IERC721Metadata {
    function balanceOf(address owner) external override view returns (uint256 balance);
}