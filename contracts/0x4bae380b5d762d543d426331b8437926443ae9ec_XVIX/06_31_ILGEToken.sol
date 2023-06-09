// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ILGEToken {
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external returns (bool);

    function token() external view returns (address);

    function refBalance() external view returns (uint256);
    function setRefBalance(uint256 balance) external returns (bool);

    function refSupply() external view returns (uint256);
    function setRefSupply(uint256 supply) external returns (bool);
}