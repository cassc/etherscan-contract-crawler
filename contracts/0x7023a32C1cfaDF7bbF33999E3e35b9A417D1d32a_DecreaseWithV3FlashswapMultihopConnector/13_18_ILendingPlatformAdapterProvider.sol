// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ILendingPlatformAdapterProvider {
    function getPlatformAdapter(address platform) external view returns (address platformAdapter);
}