// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

library Errors {
    error InsufficientFunds();
    error NothingToWithdraw();
    error MintNotStarted();
    error MintOver();
    error DataTaken();
    error DataInvalid();
    error TokenNotMinted();
    error ArrayLengthInvalid();
    error NewAddressCantBeZero();
}