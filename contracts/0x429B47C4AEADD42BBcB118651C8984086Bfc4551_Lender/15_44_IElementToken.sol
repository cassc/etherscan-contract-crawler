// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface IElementToken {
    function unlockTimestamp() external view returns (uint256);

    function underlying() external returns (address);

    function withdrawPrincipal(uint256 amount, address destination)
        external
        returns (uint256);
}