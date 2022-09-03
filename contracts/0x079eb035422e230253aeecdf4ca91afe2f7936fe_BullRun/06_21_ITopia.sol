// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITopia {

    function burn(uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;  
    function burnFrom(address _from, uint256 _amount) external;
    function decimals() external pure returns (uint8);
    function balanceOf(address owner) external view returns (uint);
}