// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IOracle} from "./interfaces/IOracle.sol";
import {IERC20Mintable} from "./interfaces/IERC20Mintable.sol";

/// @title Options Token
/// @author zefram.eth
/// @notice Options token representing the right to purchase the underlying token
/// at an oracle-specified rate. Similar to call options but with a variable strike
/// price that's always at a certain discount to the market price.
/// @dev Assumes the underlying token and the payment token both use 18 decimals.
contract OptionsToken is ERC20, Owned, IERC20Mintable {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error OptionsToken__PastDeadline();
    error OptionsToken__NotTokenAdmin();
    error OptionsToken__SlippageTooHigh();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Exercise(address indexed sender, address indexed recipient, uint256 amount, uint256 paymentAmount);
    event SetOracle(IOracle indexed newOracle);
    event SetTreasury(address indexed newTreasury);

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The contract that has the right to mint options tokens
    address public immutable tokenAdmin;

    /// @notice The token paid by the options token holder during redemption
    ERC20 public immutable paymentToken;

    /// @notice The underlying token purchased during redemption
    IERC20Mintable public immutable underlyingToken;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice The oracle contract that provides the current price to purchase
    /// the underlying token while exercising options (the strike price)
    IOracle public oracle;

    /// @notice The treasury address which receives tokens paid during redemption
    address public treasury;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_,
        address tokenAdmin_,
        ERC20 paymentToken_,
        IERC20Mintable underlyingToken_,
        IOracle oracle_,
        address treasury_
    ) ERC20(name_, symbol_, 18) Owned(owner_) {
        tokenAdmin = tokenAdmin_;
        paymentToken = paymentToken_;
        underlyingToken = underlyingToken_;
        oracle = oracle_;
        treasury = treasury_;

        emit SetOracle(oracle_);
        emit SetTreasury(treasury_);
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Called by the token admin to mint options tokens
    /// @param to The address that will receive the minted options tokens
    /// @param amount The amount of options tokens that will be minted
    function mint(address to, uint256 amount) external virtual override {
        /// -----------------------------------------------------------------------
        /// Verification
        /// -----------------------------------------------------------------------

        if (msg.sender != tokenAdmin) revert OptionsToken__NotTokenAdmin();

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // skip if amount is zero
        if (amount == 0) return;

        // mint options tokens
        _mint(to, amount);
    }

    /// @notice Exercises options tokens to purchase the underlying tokens.
    /// @dev The options tokens are not burnt but sent to address(0) to avoid messing up the
    /// inflation schedule.
    /// The oracle may revert if it cannot give a secure result.
    /// @param amount The amount of options tokens to exercise
    /// @param maxPaymentAmount The maximum acceptable amount to pay. Used for slippage protection.
    /// @param recipient The recipient of the purchased underlying tokens
    /// @return paymentAmount The amount paid to the treasury to purchase the underlying tokens
    function exercise(uint256 amount, uint256 maxPaymentAmount, address recipient)
        external
        virtual
        returns (uint256 paymentAmount)
    {
        return _exercise(amount, maxPaymentAmount, recipient);
    }

    /// @notice Exercises options tokens to purchase the underlying tokens.
    /// @dev The options tokens are not burnt but sent to address(0) to avoid messing up the
    /// inflation schedule.
    /// The oracle may revert if it cannot give a secure result.
    /// @param amount The amount of options tokens to exercise
    /// @param maxPaymentAmount The maximum acceptable amount to pay. Used for slippage protection.
    /// @param recipient The recipient of the purchased underlying tokens
    /// @param deadline The Unix timestamp (in seconds) after which the call will revert
    /// @return paymentAmount The amount paid to the treasury to purchase the underlying tokens
    function exercise(uint256 amount, uint256 maxPaymentAmount, address recipient, uint256 deadline)
        external
        virtual
        returns (uint256 paymentAmount)
    {
        if (block.timestamp > deadline) revert OptionsToken__PastDeadline();
        return _exercise(amount, maxPaymentAmount, recipient);
    }

    /// -----------------------------------------------------------------------
    /// Owner functions
    /// -----------------------------------------------------------------------

    /// @notice Sets the oracle contract. Only callable by the owner.
    /// @param oracle_ The new oracle contract
    function setOracle(IOracle oracle_) external onlyOwner {
        oracle = oracle_;
        emit SetOracle(oracle_);
    }

    /// @notice Sets the treasury address. Only callable by the owner.
    /// @param treasury_ The new treasury address
    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
        emit SetTreasury(treasury_);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _exercise(uint256 amount, uint256 maxPaymentAmount, address recipient)
        internal
        virtual
        returns (uint256 paymentAmount)
    {
        // skip if amount is zero
        if (amount == 0) return 0;

        // transfer options tokens from msg.sender to address(0)
        // we transfer instead of burn because TokenAdmin cares about totalSupply
        // which we don't want to change in order to follow the emission schedule
        transfer(address(0), amount);

        // transfer payment tokens from msg.sender to the treasury
        paymentAmount = amount.mulWadUp(oracle.getPrice());
        if (paymentAmount > maxPaymentAmount) revert OptionsToken__SlippageTooHigh();
        paymentToken.safeTransferFrom(msg.sender, treasury, paymentAmount);

        // mint underlying tokens to recipient
        underlyingToken.mint(recipient, amount);

        emit Exercise(msg.sender, recipient, amount, paymentAmount);
    }
}