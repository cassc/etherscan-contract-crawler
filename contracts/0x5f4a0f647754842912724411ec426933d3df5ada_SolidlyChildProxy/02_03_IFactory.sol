// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IFactory {
    function governanceAddress() external view returns (address);

    function childSubImplementationAddress() external view returns (address);

    function childInterfaceAddress() external view returns (address);
}