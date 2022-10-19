// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IWzNFT{
    function mint(address _owner) external returns(uint256 tokenId);

    function getSurplusQuantity() external view returns(uint256);
}