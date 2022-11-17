// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IAdapterManager {
    function execute(bytes calldata callArgs)
        external
        payable
        returns (bytes memory);

    function maxReservedBits() external view returns (uint256);

    function adaptersIndex(address adapter) external view returns (uint256);

    function maxIndex() external view returns (uint256);

    function adapterIsAvailable(address) external view returns (bool);
}