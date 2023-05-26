// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ILL420GreenPass {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}