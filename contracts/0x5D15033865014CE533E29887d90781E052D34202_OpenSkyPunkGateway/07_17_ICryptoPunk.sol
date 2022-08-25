// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface ICryptoPunk {
    function balanceOf(address account) external view returns (uint256);
    function punkIndexToAddress(uint256 punkIndex) external view returns (address);
    function punksOfferedForSale(uint256 punkIndex) external view returns (bool, uint256, address, uint256, address);
    function buyPunk(uint punkIndex) external payable;
    function transferPunk(address to, uint punkIndex) external;
}