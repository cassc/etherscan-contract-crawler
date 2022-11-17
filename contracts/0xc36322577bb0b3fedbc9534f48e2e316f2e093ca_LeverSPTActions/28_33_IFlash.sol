// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
pragma solidity ^0.8.4;

import "./ICodex.sol";
import "./IFIAT.sol";
import "./IMoneta.sol";

interface IERC3156FlashBorrower {
    /// @dev Receive `amount` of `token` from the flash lender
    /// @param initiator The initiator of the loan
    /// @param token The loan currency
    /// @param amount The amount of tokens lent
    /// @param fee The additional amount of tokens to repay
    /// @param data Arbitrary data structure, intended to contain user-defined parameters
    /// @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IERC3156FlashLender {
    /// @dev The amount of currency available to be lent
    /// @param token The loan currency
    /// @return The amount of `token` that can be borrowed
    function maxFlashLoan(address token) external view returns (uint256);

    /// @dev The fee to be charged for a given loan
    /// @param token The loan currency
    /// @param amount The amount of tokens lent
    /// @return The amount of `token` to be charged for the loan, on top of the returned principal
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /// @dev Initiate a flash loan
    /// @param receiver The receiver of the tokens in the loan, and the receiver of the callback
    /// @param token The loan currency
    /// @param amount The amount of tokens lent
    /// @param data Arbitrary data structure, intended to contain user-defined parameters
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface ICreditFlashBorrower {
    /// @dev Receives `amount` of internal Credit from the Credit flash lender
    /// @param initiator The initiator of the loan
    /// @param amount The amount of tokens lent [wad]
    /// @param fee The additional amount of tokens to repay [wad]
    /// @param data Arbitrary data structure, intended to contain user-defined parameters.
    /// @return The keccak256 hash of "ICreditFlashLoanReceiver.onCreditFlashLoan"
    function onCreditFlashLoan(
        address initiator,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface ICreditFlashLender {
    /// @notice Flash lends internal Credit to `receiver`
    /// @dev Reverts if `Flash` gets reentered in the same transaction
    /// @param receiver Address of the receiver of the flash loan [ICreditFlashBorrower]
    /// @param amount Amount of `token` to borrow [wad]
    /// @param data Arbitrary data structure, intended to contain user-defined parameters
    /// @return true if flash loan
    function creditFlashLoan(
        ICreditFlashBorrower receiver,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface IFlash is IERC3156FlashLender, ICreditFlashLender {
    function codex() external view returns (ICodex);

    function moneta() external view returns (IMoneta);

    function fiat() external view returns (IFIAT);

    function max() external view returns (uint256);

    function CALLBACK_SUCCESS() external view returns (bytes32);

    function CALLBACK_SUCCESS_CREDIT() external view returns (bytes32);

    function setParam(bytes32 param, uint256 data) external;

    function maxFlashLoan(address token) external view override returns (uint256);

    function flashFee(address token, uint256 amount) external view override returns (uint256);

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    function creditFlashLoan(
        ICreditFlashBorrower receiver,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}