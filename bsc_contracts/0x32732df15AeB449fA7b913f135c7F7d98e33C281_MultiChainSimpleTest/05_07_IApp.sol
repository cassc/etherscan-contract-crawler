// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IApp {
    function anyExecute(bytes calldata _data) external returns (bool success, bytes memory result);

    function anyFallback(address _to, bytes calldata _data) external;
}