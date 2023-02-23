// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IAddressResolver {
    event AddressChanged(
        bytes32 indexed node,
        uint256 coinType,
        bytes newAddress
    );

    function addr(bytes32 node)
        external
        view
        returns (address);

    function addr(bytes32 node, uint256 coinType)
        external
        view
        returns (bytes memory);
}