// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IUnpacker {
    function unpack(
        uint256, // bag token ID
        address // receipient
    ) external;

    function supportsInterface(bytes4 interfaceId) external returns (bool);
}