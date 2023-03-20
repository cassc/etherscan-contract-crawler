// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/**
 * @title IFlashClaimReceiver interface
 * @dev implement this interface to develop a flashclaim-compatible flashClaimReceiver contract
 **/
interface IFlashClaimReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[][] calldata tokenIds,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}