// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ISalesItem.sol";

interface IERC721SalesItem is ISalesItem{
    function ownerOf(uint256 tokenId) external view returns(address);
    function totalSupply() external view returns(uint256);
    // lock
   function setTokenLockEx(uint256[] calldata tokenIds, uint256 lockStatus) external;
//    function setWalletLockEx(address to, uint256 lockStatus) external;
   function getTokensUnderLock(uint256 start, uint256 end) external view returns (uint256[] memory);
}