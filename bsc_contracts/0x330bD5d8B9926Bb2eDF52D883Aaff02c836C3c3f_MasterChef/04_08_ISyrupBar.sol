// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ISyrupBar {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function safeKSwapTransfer(address _to, uint256 _amount) external;
}