// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IFlypeNFT{
    function allowList(address user) external view returns(bool); 
}