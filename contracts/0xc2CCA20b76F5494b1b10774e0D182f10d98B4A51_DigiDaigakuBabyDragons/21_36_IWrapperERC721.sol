// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IWrapperERC721 is IERC165 {
    function getWrappedCollectionAddress() external view returns (address);
    function canUnstake(uint256 tokenId) external view returns (bool);
    function stake(uint256 tokenId) external payable;
    function unstake(uint256 tokenId) external payable;
}