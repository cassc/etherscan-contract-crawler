// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFluentUSPlus {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint amount) external;

    function mint(address to, uint amount) external returns (bool);

    function increaseAllowance(
        address spender,
        uint addedValue
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}