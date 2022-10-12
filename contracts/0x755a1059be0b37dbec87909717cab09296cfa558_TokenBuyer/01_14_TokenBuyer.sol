// SPDX-License-Identifier: GPL-3.0

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.15;

import { Ownable } from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import { Pausable } from 'openzeppelin-contracts/contracts/security/Pausable.sol';
import { IERC20Metadata } from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import { SafeERC20 } from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import { ReentrancyGuard } from 'openzeppelin-contracts/contracts/security/ReentrancyGuard.sol';
import { Math } from 'openzeppelin-contracts/contracts/utils/math/Math.sol';
import { IPriceFeed } from './IPriceFeed.sol';
import { IBuyETHCallback } from './IBuyETHCallback.sol';
import { IPayer } from './IPayer.sol';

/// @title TokenBuyer
/// @notice Buys ERC20 tokens for ETH at oracle prices
/// It limits the amount of tokens it wants to buy using 2 factors:
///     1. The amount of debt registered in a `Payer` contract
///     2. A minimal "buffer" amount of tokens it wants to maintain
/// @dev Inspired by https://github.com/banteg/yfi-buyer
contract TokenBuyer is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      ERRORS
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    error FailedSendingETH(bytes data);
    error FailedWithdrawingETH(bytes data);
    error ReceivedInsufficientTokens(uint256 expected, uint256 actual);
    error OnlyAdmin();
    error OnlyAdminOrOwner();
    error InvalidBotDiscountBPs();
    error InvalidBaselinePaymentTokenAmount();

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      EVENTS
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    event SoldETH(address indexed to, uint256 ethOut, uint256 tokenIn);
    event BotDiscountBPsSet(uint16 oldBPs, uint16 newBPs);
    event BaselinePaymentTokenAmountSet(uint256 oldAmount, uint256 newAmount);
    event ETHWithdrawn(address indexed to, uint256 amount);
    event MinAdminBotDiscountBPsSet(uint16 oldBPs, uint16 newBPs);
    event MaxAdminBotDiscountBPsSet(uint16 oldBPs, uint16 newBPs);
    event MinAdminBaselinePaymentTokenAmountSet(uint256 oldAmount, uint256 newAmount);
    event MaxAdminBaselinePaymentTokenAmountSet(uint256 oldAmount, uint256 newAmount);
    event PriceFeedSet(address oldFeed, address newFeed);
    event PayerSet(address oldPayer, address newPayer);
    event AdminSet(address oldAdmin, address newAdmin);

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      IMMUTABLES
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice The ERC20 token the owner of this contract wants to exchange for ETH
    IERC20Metadata public immutable paymentToken;

    /// @notice 10**paymentTokenDecimals, for the calculation for ETH price
    uint256 public immutable paymentTokenDecimalsDigits;

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      STORAGE VARIABLES
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice a `Payer` contract to which `TokenBuyer` sends the ERC20 tokens. Also used for checking how much debt there is
    IPayer public payer;

    /// @notice The contract used to fetch the price of ETH in `paymentToken`
    IPriceFeed public priceFeed;

    /// @notice The minimum `paymentToken` balance the `payer` contract should have
    uint256 public baselinePaymentTokenAmount;

    /// @notice The minimum allowed value for `baselinePaymentTokenAmount`
    uint256 public minAdminBaselinePaymentTokenAmount;

    /// @notice The maximum allowed value for `baselinePaymentTokenAmount`
    uint256 public maxAdminBaselinePaymentTokenAmount;

    /// @notice the amount of basis points to decrease the price by, to increase the incentive to transact with this contract
    uint16 public botDiscountBPs;

    /// @notice The minimum discount allowed in bps
    uint16 public minAdminBotDiscountBPs;

    /// @notice The maximum discount allowed in bps
    uint16 public maxAdminBotDiscountBPs;

    /// @notice Contract admin, allowed to do certain lower risk operations
    address public admin;

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      MODIFIERS
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    modifier onlyAdmin() {
        if (admin != msg.sender) {
            revert OnlyAdmin();
        }
        _;
    }

    modifier onlyAdminOrOwner() {
        if (admin != msg.sender && owner() != msg.sender) {
            revert OnlyAdminOrOwner();
        }
        _;
    }

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      CONSTRUCTOR
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    constructor(
        address _paymentToken,
        IPriceFeed _priceFeed,
        uint256 _baselinePaymentTokenAmount,
        uint256 _minAdminBaselinePaymentTokenAmount,
        uint256 _maxAdminBaselinePaymentTokenAmount,
        uint16 _botDiscountBPs,
        uint16 _minAdminBotDiscountBPs,
        uint16 _maxAdminBotDiscountBPs,
        address _owner,
        address _admin,
        address _payer
    ) {
        paymentToken = IERC20Metadata(_paymentToken);
        paymentTokenDecimalsDigits = 10**IERC20Metadata(_paymentToken).decimals();
        priceFeed = _priceFeed;

        baselinePaymentTokenAmount = _baselinePaymentTokenAmount;
        minAdminBaselinePaymentTokenAmount = _minAdminBaselinePaymentTokenAmount;
        maxAdminBaselinePaymentTokenAmount = _maxAdminBaselinePaymentTokenAmount;

        botDiscountBPs = _botDiscountBPs;
        minAdminBotDiscountBPs = _minAdminBotDiscountBPs;
        maxAdminBotDiscountBPs = _maxAdminBotDiscountBPs;

        _transferOwnership(_owner);
        admin = _admin;

        payer = IPayer(_payer);
    }

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      EXTERNAL TRANSACTIONS
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Allow ETH top ups
    receive() external payable {}

    /// @notice Buy ETH from this contract in exchange for `paymentToken` tokens.
    /// The price is determined using `priceFeed` plus `botDiscountBPs`
    /// Immediately invokes `payer` to pay back outstanding debt
    /// @dev Caps `tokenAmount` by the amount of tokens the contract needs
    /// @param tokenAmount the amount of ERC20 tokens msg.sender wishes to sell to this contract in exchange for ETH
    function buyETH(uint256 tokenAmount) external nonReentrant whenNotPaused {
        uint256 amount = Math.min(tokenAmount, tokenAmountNeeded());

        // Cache payer
        IPayer _payer = payer;

        // Transfer tokens from msg.sender to `payer`
        paymentToken.safeTransferFrom(msg.sender, address(_payer), amount);

        // Invoke `payer` to pay back outstanding debt
        _payer.payBackDebt(amount);

        // Send msg.sender ETH
        uint256 ethAmount = ethAmountPerTokenAmount(amount);
        safeSendETH(msg.sender, ethAmount, '');

        emit SoldETH(msg.sender, ethAmount, amount);
    }

    /// @notice Buy ETH from this contract in exchange for `paymentToken` tokens.
    /// The price is determined using `priceFeed` plus `botDiscountBPs`
    /// Immediately invokes `payer` to pay back outstanding debt
    /// @dev First sends ETH by calling a callback, and then checks it received tokens.
    /// This allowed the caller to swap the ETH for tokens instead of holding tokens in advance
    /// @param tokenAmount the amount of ERC20 tokens msg.sender wishes to sell to this contract in exchange for ETH
    /// @param to the address to send ETH to by calling the callback function on it
    /// @param data arbitrary data passed through by the caller, usually used for callback verification
    function buyETH(
        uint256 tokenAmount,
        address to,
        bytes calldata data
    ) external nonReentrant whenNotPaused {
        uint256 amount = Math.min(tokenAmount, tokenAmountNeeded());

        IPayer _payer = payer;

        // Starting balance of `payer`
        uint256 balanceBefore = paymentToken.balanceOf(address(_payer));

        // Send ETH to `to`
        uint256 ethAmount = ethAmountPerTokenAmount(amount);
        IBuyETHCallback(to).buyETHCallback{ value: ethAmount }(msg.sender, amount, data);

        // Check that `payers` balance increased by the expected amount
        uint256 tokensReceived = paymentToken.balanceOf(address(_payer)) - balanceBefore;
        if (tokensReceived < amount) {
            revert ReceivedInsufficientTokens(amount, tokensReceived);
        }

        // Invoke `payer` to pay back outstanding debt
        _payer.payBackDebt(amount);

        emit SoldETH(to, ethAmount, amount);
    }

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      VIEW FUNCTIONS
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Get how much ETH this contract needs in order to fund its current obligations plus `additionalTokens`, with
    /// a safety buffer `bufferBPs` basis points.
    /// @param additionalTokens an additional amount of `paymentToken` liability to use in this ETH requirement calculation, in payment token decimals.
    /// @param bufferBPs the number of basis points to add on top of the token liability price in ETH as a safety buffer, e.g.
    /// if `bufferBPs` is 10K, the function will return twice the amount it needs according to price alone.
    /// @return the amount of ETH needed
    function ethNeeded(uint256 additionalTokens, uint256 bufferBPs) public view returns (uint256) {
        uint256 tokenAmount = tokenAmountNeeded() + additionalTokens;
        uint256 ethCostOfTokens = ethAmountPerTokenAmount(tokenAmount);
        uint256 ethCostWithBuffer = (ethCostOfTokens * (bufferBPs + 10_000)) / 10_000;

        return ethCostWithBuffer - address(this).balance;
    }

    /// @notice Returns the amount of tokens this contract is willing to exchange of ETH
    /// @return amount of tokens
    function tokenAmountNeeded() public view returns (uint256) {
        IPayer _payer = payer;
        uint256 _tokensAvailable = paymentToken.balanceOf(address(_payer));
        uint256 totalDebt = _payer.totalDebt();
        unchecked {
            uint256 neededTokens = baselinePaymentTokenAmount + totalDebt;
            if (_tokensAvailable > neededTokens) {
                return 0;
            }
            return neededTokens - _tokensAvailable;
        }
    }

    /// @notice Returns the ETH/`paymentToken` price this contract is willing to exchange ETH at, including the discount
    /// @return The price, in 18 decimal format
    function price() public view returns (uint256) {
        unchecked {
            return (priceFeed.price() * (10_000 - botDiscountBPs)) / 10_000;
        }
    }

    /// @notice Returns the amount of ETH this contract will send in exchange for `tokenAmount` tokens
    /// @param tokenAmount the amount of tokens
    /// @return amount of ETH the contract will sell for `tokenAmount` of tokens
    function ethAmountPerTokenAmount(uint256 tokenAmount) public view returns (uint256) {
        unchecked {
            // Example:
            // if tokenAmount == 3400000000 (3400 USDC) (6 decimals)
            // and price() == 1745910000000000000000 (1745.91) (18 decimals)
            // ((3400000000 * 1e36) / 1745910000000000000000) / 1e6 = 1.947408515e18 (3400/1745.91)
            return ((tokenAmount * 1e36) / price()) / paymentTokenDecimalsDigits;
        }
    }

    /// @notice Returns the amount of tokens the contract can buy and the amount of ETH it will pay for it
    /// This takes into account the current ETH balance this contract has
    /// @return tokenAmount amount of tokens the contract can buy
    /// @return ethAmount amount of ETH it will pay for the tokens
    function tokenAmountNeededAndETHPayout() public view returns (uint256, uint256) {
        uint256 tokenAmount = tokenAmountNeeded();
        uint256 ethAmount = ethAmountPerTokenAmount(tokenAmount);
        uint256 ethAvailable = address(this).balance;

        if (ethAvailable >= ethAmount) {
            return (tokenAmount, ethAmount);
        } else {
            // Tokens amount will be rounded down to avoid trying to buy more eth than available
            tokenAmount = tokenAmountPerEthAmount(ethAvailable);

            // Recalculate eth amount because tokens amount are rounded down
            ethAmount = ethAmountPerTokenAmount(tokenAmount);

            return (tokenAmount, ethAmount);
        }
    }

    /// @notice Returns the amount of tokens the contract expects in return for eth
    /// @param ethAmount amount of ETH contract to be swapped
    /// @return amount of tokens the contract will sell the ETH for
    /// @dev result is rounded down
    function tokenAmountPerEthAmount(uint256 ethAmount) public view returns (uint256) {
        return (ethAmount * price() * paymentTokenDecimalsDigits) / 1e36;
    }

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      ADMIN or OWNER TRANSACTIONS
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Update `botDiscountBPs`
    function setBotDiscountBPs(uint16 newBotDiscountBPs) external onlyAdminOrOwner {
        // Admin is limited to min-max range, owner is not
        if (
            admin == msg.sender &&
            (newBotDiscountBPs < minAdminBotDiscountBPs || newBotDiscountBPs > maxAdminBotDiscountBPs)
        ) {
            revert InvalidBotDiscountBPs();
        }

        emit BotDiscountBPsSet(botDiscountBPs, newBotDiscountBPs);

        botDiscountBPs = newBotDiscountBPs;
    }

    /// @notice Update `baselinePaymentTokenAmount`
    /// @param newBaselinePaymentTokenAmount the new `baselinePaymentTokenAmount` in token decimals.
    function setBaselinePaymentTokenAmount(uint256 newBaselinePaymentTokenAmount) external onlyAdminOrOwner {
        // Admin is limited to min-max range, owner is not
        if (
            admin == msg.sender &&
            (newBaselinePaymentTokenAmount < minAdminBaselinePaymentTokenAmount ||
                newBaselinePaymentTokenAmount > maxAdminBaselinePaymentTokenAmount)
        ) {
            revert InvalidBaselinePaymentTokenAmount();
        }

        emit BaselinePaymentTokenAmountSet(baselinePaymentTokenAmount, newBaselinePaymentTokenAmount);

        baselinePaymentTokenAmount = newBaselinePaymentTokenAmount;
    }

    /// @notice pause ETH buying
    function pause() external onlyAdminOrOwner {
        _pause();
    }

    /// @notice unpause ETH buying
    function unpause() external onlyAdminOrOwner {
        _unpause();
    }

    /// @notice Withdraw all ETH to the contract owner
    function withdrawETH() external onlyAdminOrOwner {
        uint256 amount = address(this).balance;
        address to = owner();

        (bool sent, bytes memory data) = to.call{ value: amount }('');
        if (!sent) {
            revert FailedWithdrawingETH(data);
        }

        emit ETHWithdrawn(to, amount);
    }

    /// @notice set a new Admin
    function setAdmin(address newAdmin) external onlyAdminOrOwner {
        emit AdminSet(admin, newAdmin);

        admin = newAdmin;
    }

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      OWNER TRANSACTIONS
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    /// @notice Update minAdminBotDiscountBPs
    function setMinAdminBotDiscountBPs(uint16 newMinAdminBotDiscountBPs) external onlyOwner {
        emit MinAdminBotDiscountBPsSet(minAdminBotDiscountBPs, newMinAdminBotDiscountBPs);

        minAdminBotDiscountBPs = newMinAdminBotDiscountBPs;
    }

    /// @notice Update maxAdminBotDiscountBPs
    function setMaxAdminBotDiscountBPs(uint16 newMaxAdminBotDiscountBPs) external onlyOwner {
        emit MaxAdminBotDiscountBPsSet(maxAdminBotDiscountBPs, newMaxAdminBotDiscountBPs);

        maxAdminBotDiscountBPs = newMaxAdminBotDiscountBPs;
    }

    /// @notice Update minAdminBaselinePaymentTokenAmount
    function setMinAdminBaselinePaymentTokenAmount(uint256 newMinAdminBaselinePaymentTokenAmount) external onlyOwner {
        emit MinAdminBaselinePaymentTokenAmountSet(
            minAdminBaselinePaymentTokenAmount,
            newMinAdminBaselinePaymentTokenAmount
        );

        minAdminBaselinePaymentTokenAmount = newMinAdminBaselinePaymentTokenAmount;
    }

    /// @notice Update maxAdminBaselinePaymentTokenAmount
    function setMaxAdminBaselinePaymentTokenAmount(uint256 newMaxAdminBaselinePaymentTokenAmount) external onlyOwner {
        emit MaxAdminBaselinePaymentTokenAmountSet(
            maxAdminBaselinePaymentTokenAmount,
            newMaxAdminBaselinePaymentTokenAmount
        );

        maxAdminBaselinePaymentTokenAmount = newMaxAdminBaselinePaymentTokenAmount;
    }

    /// @notice Update priceFeed
    function setPriceFeed(IPriceFeed newPriceFeed) external onlyOwner {
        emit PriceFeedSet(address(priceFeed), address(newPriceFeed));

        priceFeed = newPriceFeed;
    }

    /// @notice Update `payer`
    function setPayer(address newPayer) external onlyOwner {
        emit PayerSet(address(payer), newPayer);

        payer = IPayer(newPayer);
    }

    /**
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      INTERNAL FUNCTIONS
     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
     */

    function safeSendETH(
        address to,
        uint256 ethAmount,
        bytes memory data
    ) internal {
        // If contract balance is insufficient it reverts
        (bool sent, bytes memory returnData) = to.call{ value: ethAmount }(data);
        if (!sent) {
            revert FailedSendingETH(returnData);
        }
    }
}