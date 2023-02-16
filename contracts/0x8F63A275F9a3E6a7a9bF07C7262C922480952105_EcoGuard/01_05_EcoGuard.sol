// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import '@gnosis.pm/zodiac/contracts/guard/BaseGuard.sol';

contract EcoGuard is BaseGuard {
    error NotVoteSplitCall();
    error FunctionSignatureTooShort();
    error TargetAlreadyCalled();

    // caller => target => called
    mapping(address => mapping(address => bool)) internal _targetsCalled;

    function checkTransaction(
        address to,
        uint256,
        bytes memory data,
        Enum.Operation,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes memory,
        address
    ) external override {
        if (data.length != 0 && data.length < 4) {
            revert FunctionSignatureTooShort();
        }

        if (bytes4(data) != 0xce32de2b) {
            revert NotVoteSplitCall();
        }

        if (_targetsCalled[msg.sender][to]) {
            revert TargetAlreadyCalled();
        }

        _targetsCalled[msg.sender][to] = true;
    }

    function checkAfterExecution(bytes32, bool) external override {}
}