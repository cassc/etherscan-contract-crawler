//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ITreasureBox {
    function mint(address _to, uint8 _type, uint256 _amount) external;
}