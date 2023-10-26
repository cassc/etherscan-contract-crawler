// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPrismaCore {
    function owner() external view returns (address);

    function guardian() external view returns (address);

    function feeReceiver() external view returns (address);

    function priceFeed() external view returns (address);

    function paused() external view returns (bool);

    function startTime() external view returns (uint256);

    function acceptTransferOwnership() external;

    function setGuardian(address guardian) external;
}