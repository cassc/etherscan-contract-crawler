// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IDispatcher {
    function setContract(string calldata _contractKey, address _contractAddress) external;

    function getContract(bytes32 _contractKey) external view returns (address);
}