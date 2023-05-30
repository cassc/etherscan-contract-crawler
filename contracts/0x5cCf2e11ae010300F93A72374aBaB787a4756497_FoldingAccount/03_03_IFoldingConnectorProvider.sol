// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IFoldingConnectorProvider {
    function getImplementation(bytes4 functionSignature) external view returns (address implementation);
}