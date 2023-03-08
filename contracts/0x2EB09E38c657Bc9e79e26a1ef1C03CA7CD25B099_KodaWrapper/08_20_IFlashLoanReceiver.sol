// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IFlashLoanReceiver {
    function executeOperation(
        address asset,
        uint256[] calldata tokenIds,
        address initiator,
        address operator,
        bytes calldata params
    ) external returns (bool);
}