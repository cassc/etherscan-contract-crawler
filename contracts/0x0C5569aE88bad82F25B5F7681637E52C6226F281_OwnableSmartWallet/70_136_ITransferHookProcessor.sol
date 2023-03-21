pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

interface ITransferHookProcessor {
    function beforeTokenTransfer(address _from, address _to, uint256 _amount) external;
    function afterTokenTransfer(address _from, address _to, uint256 _amount) external;
}