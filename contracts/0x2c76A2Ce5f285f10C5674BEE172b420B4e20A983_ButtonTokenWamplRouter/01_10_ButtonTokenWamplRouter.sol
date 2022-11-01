// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IButtonWrapper.sol";
import "./interfaces/IWAMPL.sol";
import "./interfaces/IButtonToken.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Router to automatically wrap AMPL into WAMPL for ButtonToken actions
 */
contract ButtonTokenWamplRouter is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice ButtonToken underlying doesn't match wampl address
    error InvalidButtonAsset();

    /// @notice Zero amount provided
    error ZeroAmount();

    IWAMPL public immutable wampl;

    constructor(address _wampl) {
        wampl = IWAMPL(_wampl);
        // Pre-approving contract's AMPL balance to be used by WAMPL contract
        IERC20(IWAMPL(_wampl).underlying()).safeApprove(_wampl, type(uint256).max);
    }

    /**
     * @notice Deposit the given amount of AMPL into the given WAMPL ButtonToken
     *  Returns the output buttonTokens to the user.
     * @dev Validates amount > 0
     * @dev Validates buttonToken has WAMPL as underlying to prevent asset loss
     * @dev buttonToken is kept as parameter to support multiple buttonToken implementations
     *
     * @param buttonToken the button token to deposit into
     * @param amplAmount The amount of AMPL being deposited
     * @return The amount of ButtonTokens created
     */
    function wamplWrapAndDeposit(IButtonToken buttonToken, uint256 amplAmount)
        external
        nonReentrant
        returns (uint256)
    {
        if (amplAmount == 0) revert ZeroAmount();
        if (buttonToken.underlying() != address(wampl)) revert InvalidButtonAsset();
        // Transfer ampl to router
        IERC20(wampl.underlying()).transferFrom(msg.sender, address(this), amplAmount);
        // Router's ampl balance is already approved to WAMPL contract by constructor
        // Depositing ampl for wampl
        uint256 wamplAmount = wampl.deposit(amplAmount);
        // Approving wampl to buttonToken contract
        IERC20(wampl).safeApprove(address(buttonToken), wamplAmount);
        // Depositing wampl for buttonToken sent to user
        return buttonToken.depositFor(msg.sender, wamplAmount);
    }

    /**
     * @notice Withdraw the given amount of button tokens from the given ButtonToken and convert to AMPL
     *  Returns the output AMPL to the user
     *
     * @param buttonToken the button token to burn from
     * @param amount The amount of ButtonTokens to burn
     * @return The amount of ampl tokens returned
     */
    function wamplBurnAndUnwrap(IButtonToken buttonToken, uint256 amount)
        external
        nonReentrant
        returns (uint256)
    {
        // Transfer buttonToken to router
        buttonToken.transferFrom(msg.sender, address(this), amount);
        // Burn buttonToken to wampl
        buttonToken.burn(amount);
        // Burn wampl to ampl, directly send to user
        return wampl.burnAllTo(msg.sender);
    }

    /**
     * @dev Withdraw all button tokens from the given ButtonToken and convert to AMPL
     *  Returns the output AMPL to the user
     *
     * @param buttonToken the button token to burn from
     * @return The amount of ampl tokens returned
     */
    function wamplBurnAndUnwrapAll(IButtonToken buttonToken)
        external
        nonReentrant
        returns (uint256)
    {
        // Transfer all buttonToken to router
        buttonToken.transferAllFrom(msg.sender, address(this));
        // Burn all buttonToken to wampl
        IButtonWrapper(buttonToken).burnAll();
        // Burn wampl to ampl, directly send to user
        return wampl.burnAllTo(msg.sender);
    }
}