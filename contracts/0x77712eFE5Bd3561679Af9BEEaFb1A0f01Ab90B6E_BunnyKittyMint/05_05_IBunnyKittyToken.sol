// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBunnyKittyToken {

    function mint(uint256 _amount, address _recipient) external;

    function totalSupply() external view returns (uint256); 

}