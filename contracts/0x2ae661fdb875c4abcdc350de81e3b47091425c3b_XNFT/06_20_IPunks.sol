// SPDX-License-Identifier: MIT
pragma solidity ^   0.8.2;

interface IPunks {
    
    function balanceOf(address account) external view returns (uint256);

    function punkIndexToAddress(uint256 punkIndex) external view returns (address owner);

    function buyPunk(uint256 punkIndex) external;

    function transferPunk(address to, uint256 punkIndex) external;
}