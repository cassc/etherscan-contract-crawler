// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface IExtensionPayee {
    function payeeOf(bytes32 node) external view returns (address);
}