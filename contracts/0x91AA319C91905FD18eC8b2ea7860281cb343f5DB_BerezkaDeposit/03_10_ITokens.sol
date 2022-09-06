//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ITokens {
    
    function burn(address _holder, uint256 _amount) external;

    function mint(address _holder, uint256 _amount) external;
}