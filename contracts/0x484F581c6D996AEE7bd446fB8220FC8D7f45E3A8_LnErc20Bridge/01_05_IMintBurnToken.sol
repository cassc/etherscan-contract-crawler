// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IMintBurnToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}
