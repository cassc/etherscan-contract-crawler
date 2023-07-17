// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWorkQuestToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}