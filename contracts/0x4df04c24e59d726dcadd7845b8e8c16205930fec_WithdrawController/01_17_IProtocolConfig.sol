// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IProtocolConfig {
    function protocolFeeRate() external view returns (uint256);

    function protocolAdmin() external view returns (address);

    function protocolTreasury() external view returns (address);

    function pauserAddress() external view returns (address);
}