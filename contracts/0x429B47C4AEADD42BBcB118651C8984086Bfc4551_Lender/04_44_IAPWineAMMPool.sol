// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface IAPWineAMMPool {
    function getUnderlyingOfIBTAddress() external view returns (address);

    function getPTAddress() external view returns (address);
}