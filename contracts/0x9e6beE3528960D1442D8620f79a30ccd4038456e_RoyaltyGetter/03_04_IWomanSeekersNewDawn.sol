// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;


interface IWomanSeekersNewDawn {

      function lastTokenIdTransfer() external view returns (uint);

      function ownerOf(uint256 tokenId) external view returns (address);

      function totalSupply() external  view  returns (uint256);

      function tokensOfOwner(address owner) external view returns (uint256[] memory);

          function balanceOf(address owner) external view returns (uint256 balance);




}