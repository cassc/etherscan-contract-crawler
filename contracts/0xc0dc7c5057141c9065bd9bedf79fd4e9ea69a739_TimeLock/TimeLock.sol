/**
 *Submitted for verification at Etherscan.io on 2023-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract TimeLock {
    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "onlyOwner: caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function _setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function executeTransactions(address[] calldata _targets, bytes[] calldata _calldatas) external onlyOwner {
        for (uint i = 0; i < _targets.length; i++) {
            (bool _success, ) = _targets[i].call(_calldatas[i]);
            require(_success, "Timelock::executeTransactions: Transaction execution reverted.");
        }
    }
}