// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface IPendleToken {
    function SY() external view returns (address);

    function YT() external view returns (address);

    function expiry() external view returns (uint256);
}