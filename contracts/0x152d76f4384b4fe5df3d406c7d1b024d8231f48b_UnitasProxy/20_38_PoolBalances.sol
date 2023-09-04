// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./utils/AddressUtils.sol";
import "./utils/Errors.sol";

/**
 * @title PoolBalances
 * @notice The abstract contract includes some generic functions and states that are used to manage pool assets
 *
 * @custom:storage-size 50
 */
abstract contract PoolBalances {
    using MathUpgradeable for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice Maps the address to the balance of the token
     */
    mapping(address => uint256) internal _balance;
    /**
     * @notice Maps the address to the portfolio of the token
     */
    mapping(address => uint256) internal _portfolio;

    /**
     * @notice Emitted when the balance of `token` is updated to `newBalance`
     */
    event BalanceUpdated(address indexed token, uint256 newBalance);
    /**
     * @notice Emitted when portfolio `amount` of `token` is received from `sender`
     */
    event PortfolioReceived(address indexed token, address indexed sender, uint256 amount);
    /**
     * @notice Emitted when portfolio `amount` of `token` is sent to `receiver`
     */
    event PortfolioSent(address indexed token, address indexed receiver, uint256 amount);
    /**
     * @notice Emitted when the portfolio of `token` is updated to `newPortfolio`
     */
    event PortfolioUpdated(address indexed token, uint256 newPortfolio);

    /**
     * @notice Updates the balance of `token` to `newBalance`
     */
    function _setBalance(address token, uint256 newBalance) internal virtual {
        _balance[token] = newBalance;
        emit BalanceUpdated(token, newBalance);
    }

    /**
     * @notice Updates the portfolio of `token` to `newPortfolio`
     */
    function _setPortfolio(address token, uint256 newPortfolio) internal virtual {
        _portfolio[token] = newPortfolio;
        emit PortfolioUpdated(token, newPortfolio);
    }

    /**
     * @notice Receives portfolio `amount` of `token` from `sender`
     */
    function _receivePortfolio(address token, address sender, uint256 amount) internal virtual {
        AddressUtils.checkNotZero(token);
        AddressUtils.checkNotZero(sender);
        _checkAmountPositive(amount);
        _require(sender != address(this), Errors.SENDER_INVALID);

        uint256 portfolio = _getPortfolio(token);
        _require(amount <= portfolio, Errors.AMOUNT_INVALID);

        _setPortfolio(token, portfolio - amount);

        IERC20(token).safeTransferFrom(sender, address(this), amount);

        emit PortfolioReceived(token, sender, amount);
    }

    /**
     * @notice Sends portfolio `amount` of `token` to `receiver`
     */
    function _sendPortfolio(address token, address receiver, uint256 amount) internal virtual {
        AddressUtils.checkNotZero(token);
        AddressUtils.checkNotZero(receiver);
        _checkAmountPositive(amount);
        _require(receiver != address(this), Errors.RECEIVER_INVALID);

        uint256 portfolio = _getPortfolio(token);
        amount = amount.min(_getBalance(token) - portfolio);

        _require(amount > 0, Errors.POOL_BALANCE_INSUFFICIENT);

        _setPortfolio(token, portfolio + amount);

        IERC20(token).safeTransfer(receiver, amount);

        emit PortfolioSent(token, receiver, amount);
    }

    /**
     * @notice Gets the current balance of `token`
     */
    function _getBalance(address token) internal view virtual returns (uint256) {
        return _balance[token];
    }

    /**
     * @notice Gets the current portfolio of `token`
     */
    function _getPortfolio(address token) internal view virtual returns (uint256) {
        return _portfolio[token];
    }

    /**
     * @notice Reverts if `amount` is zero or negative
     */
    function _checkAmountPositive(uint256 amount) internal pure {
        _require(amount > 0, Errors.AMOUNT_INVALID);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}