// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IStocking is IERC721{
    function stockingPeriod(uint256 tokenId) external returns(bool, uint64, uint64, uint64);
    function stockingCurrent(uint256 tokenId) external returns(uint64);
    function stockingLevel(uint256 tokenId) external returns(uint64);
    function toggleStocking(uint256[] calldata tokenId) external ;
    function safeTransferWhileStocking(address from, address to, uint256 tokenId) external ;
    function expelFromStock(uint256 tokenId) external ;
}