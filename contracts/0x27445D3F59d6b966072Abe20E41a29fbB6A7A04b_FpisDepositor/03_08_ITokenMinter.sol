// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ITokenMinter{
    function mint(address,uint256) external;
    function burn(address,uint256) external;
    function setOperator(address _operator, bool _active) external;
}