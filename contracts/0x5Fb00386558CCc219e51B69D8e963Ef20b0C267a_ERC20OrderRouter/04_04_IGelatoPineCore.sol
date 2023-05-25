// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

interface IGelatoPineCore {
    function vaultOfOrder(
        address _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external view returns (address);

    function keyOf(
        address _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external pure returns (bytes32);
}