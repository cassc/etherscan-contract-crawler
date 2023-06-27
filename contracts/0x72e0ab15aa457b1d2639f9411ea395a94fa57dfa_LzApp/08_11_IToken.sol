// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IToken {
    function mint(address _addr, uint256 _amount) external;

    function burn(uint256 _amount) external;
    
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}