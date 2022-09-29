// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
pragma solidity ^0.8.4;

import {ICodex} from "./interfaces/ICodex.sol";
import {IFIAT} from "./interfaces/IFIAT.sol";
import {IFlash, IERC3156FlashBorrower, ICreditFlashBorrower} from "./interfaces/IFlash.sol";
import {IMoneta} from "./interfaces/IMoneta.sol";

import {Guarded} from "./utils/Guarded.sol";
import {WAD, add, sub, wmul} from "./utils/Math.sol";

/// @title Flash
/// @notice `Flash` enables flash minting / borrowing of FIAT and internal Credit
/// Uses DssFlash.sol from DSS (MakerDAO) as a blueprint
contract Flash is Guarded, IFlash {
    /// ======== Custom Errors ======== ///

    error Flash__lock_reentrancy();
    error Flash__setParam_ceilingTooHigh();
    error Flash__setParam_unrecognizedParam();
    error Flash__flashFee_unsupportedToken();
    error Flash__flashLoan_unsupportedToken();
    error Flash__flashLoan_ceilingExceeded();
    error Flash__flashLoan_codexNotLive();
    error Flash__flashLoan_callbackFailed();
    error Flash__creditFlashLoan_ceilingExceeded();
    error Flash__creditFlashLoan_codexNotLive();
    error Flash__creditFlashLoan_callbackFailed();

    /// ======== Storage ======== ///

    ICodex public immutable codex;
    IMoneta public immutable moneta;
    IFIAT public immutable fiat;

    // Maximum borrowable FIAT [wad]
    uint256 public max;
    // Reentrancy guard
    uint256 private locked = 1;

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    bytes32 public constant CALLBACK_SUCCESS_CREDIT = keccak256("CreditFlashBorrower.onCreditFlashLoan");

    /// ======== Events ======== ///

    event SetParam(bytes32 indexed param, uint256 data);
    event FlashLoan(address indexed receiver, address token, uint256 amount, uint256 fee);
    event CreditFlashLoan(address indexed receiver, uint256 amount, uint256 fee);

    modifier lock() {
        if (locked != 1) revert Flash__lock_reentrancy();
        locked = 2;
        _;
        locked = 1;
    }

    constructor(address moneta_) Guarded() {
        ICodex codex_ = codex = ICodex(IMoneta(moneta_).codex());
        moneta = IMoneta(moneta_);
        IFIAT fiat_ = fiat = IFIAT(IMoneta(moneta_).fiat());

        codex_.grantDelegate(moneta_);
        fiat_.approve(moneta_, type(uint256).max);
    }

    /// ======== Configuration ======== ///

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(bytes32 param, uint256 data) external checkCaller {
        if (param == "max") {
            // Add an upper limit of 10^45 FIAT to avoid breaking technical assumptions of FIAT << 2^256 - 1
            if (data > 1e45) revert Flash__setParam_ceilingTooHigh();
            max = data;
        } else revert Flash__setParam_unrecognizedParam();
        emit SetParam(param, data);
    }

    /// ======== Flash Loan ======== ///

    /// @notice Returns the maximum borrowable amount for `token`
    /// @dev If `token` is not FIAT then 0 is returned
    /// @param token Address of the token to borrow (has to be the address of FIAT)
    /// @return maximum borrowable amount [wad]
    function maxFlashLoan(address token) external view override returns (uint256) {
        return (token == address(fiat) && locked == 1) ? max : 0;
    }

    /// @notice Returns the current borrow fee for borrowing `amount` of `token`
    /// @dev If `token` is not FIAT then this method will revert
    /// @param token Address of the token to borrow (has to be the address of FIAT)
    /// @param *amount Amount to borrow [wad]
    /// @return fee to borrow `amount` of `token`
    function flashFee(
        address token,
        uint256 /* amount */
    ) external view override returns (uint256) {
        if (token != address(fiat)) revert Flash__flashFee_unsupportedToken();
        return 0;
    }

    /// @notice Flash lends `token` (FIAT) to `receiver`
    /// @dev Reverts if `Flash` gets reentered in the same transaction or if token is not FIAT
    /// @param receiver Address of the receiver of the flash loan
    /// @param token Address of the token to borrow (has to be the address of FIAT)
    /// @param amount Amount of `token` to borrow [wad]
    /// @param data Arbitrary data structure, intended to contain user-defined parameters
    /// @return true if flash loan
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override lock returns (bool) {
        if (token != address(fiat)) revert Flash__flashLoan_unsupportedToken();
        if (amount > max) revert Flash__flashLoan_ceilingExceeded();
        if (codex.live() == 0) revert Flash__flashLoan_codexNotLive();

        codex.createUnbackedDebt(address(this), address(this), amount);
        moneta.exit(address(receiver), amount);

        emit FlashLoan(address(receiver), token, amount, 0);

        if (receiver.onFlashLoan(msg.sender, token, amount, 0, data) != CALLBACK_SUCCESS)
            revert Flash__flashLoan_callbackFailed();

        fiat.transferFrom(address(receiver), address(this), amount);
        moneta.enter(address(this), amount);
        codex.settleUnbackedDebt(amount);

        return true;
    }

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
    ) external override lock returns (bool) {
        if (amount > max) revert Flash__creditFlashLoan_ceilingExceeded();
        if (codex.live() == 0) revert Flash__creditFlashLoan_codexNotLive();

        codex.createUnbackedDebt(address(this), address(receiver), amount);

        emit CreditFlashLoan(address(receiver), amount, 0);

        if (receiver.onCreditFlashLoan(msg.sender, amount, 0, data) != CALLBACK_SUCCESS_CREDIT)
            revert Flash__creditFlashLoan_callbackFailed();

        codex.settleUnbackedDebt(amount);

        return true;
    }
}

abstract contract FlashLoanReceiverBase is ICreditFlashBorrower, IERC3156FlashBorrower {
    Flash public immutable flash;

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    bytes32 public constant CALLBACK_SUCCESS_CREDIT = keccak256("CreditFlashBorrower.onCreditFlashLoan");

    constructor(address flash_) {
        flash = Flash(flash_);
    }

    function approvePayback(uint256 amount) internal {
        // Lender takes back the FIAT as per ERC3156 spec
        flash.fiat().approve(address(flash), amount);
    }

    function payBackCredit(uint256 amount) internal {
        // Lender takes back the FIAT as per ERC3156 spec
        flash.codex().transferCredit(address(this), address(flash), amount);
    }
}