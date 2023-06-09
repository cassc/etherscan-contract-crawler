// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IWrappedToken {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}