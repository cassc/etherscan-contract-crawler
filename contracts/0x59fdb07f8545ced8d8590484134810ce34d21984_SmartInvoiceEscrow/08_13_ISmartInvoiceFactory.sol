// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISmartInvoiceFactory {
    function create(
        address _recipient,
        uint256[] calldata _amounts,
        bytes calldata _data,
        bytes32 _type
    ) external returns (address);

    function createDeterministic(
        address _recipient,
        uint256[] calldata _amounts,
        bytes calldata _data,
        bytes32 _type,
        bytes32 _salt
    ) external returns (address);

    function predictDeterministicAddress(bytes32 _type, bytes32 _salt)
        external
        returns (address);

    function resolutionRateOf(address _resolver)
        external
        view
        returns (uint256);
}