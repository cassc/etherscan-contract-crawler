// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IDealeable {
    function deal(address _to, uint8 _amount, uint256 _rarityModifier) external returns(bool);
}
