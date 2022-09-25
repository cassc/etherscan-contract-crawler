// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface INeuronPoolsController {
    function nPools(address) external view returns (address);

    function rewards() external view returns (address);

    function treasury() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function withdraw(address, uint256) external;

    function earn(address, uint256) external;
}