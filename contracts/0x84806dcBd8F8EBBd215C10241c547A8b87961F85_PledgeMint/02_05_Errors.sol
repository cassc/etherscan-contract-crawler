// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

library Errors {
    // PledgeMint.sol
    error CallerIsContract();
    error CallerIsNotOwner();
    error NFTAmountNotAllowed();
    error PhaseNotActive();
    error OverPhaseCap();
    error AmountNeedsToBeGreaterThanZero();
    error AmountMismatch();
    error AlreadyPledged();
    error NothingWasPledged();
    error UnableToSendValue();
    error ContractCannotBeChanged();
}