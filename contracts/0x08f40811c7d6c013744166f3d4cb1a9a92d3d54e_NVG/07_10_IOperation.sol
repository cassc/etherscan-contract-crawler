// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IOperation {
    function applicationOperation(bytes32 opHash) external;

    function authorizedOperation(bytes32 opHash) external;

    event ApplicationOperation(address from, bytes32 opHash);

    event AuthorizedOperation(address from, bytes32 opHash);

    event AllDone(bytes32 opHash);
}