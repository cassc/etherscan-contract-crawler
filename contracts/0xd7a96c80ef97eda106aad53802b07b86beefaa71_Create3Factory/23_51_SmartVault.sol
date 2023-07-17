// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';
import '@mimic-fi/v2-helpers/contracts/utils/Denominations.sol';
import '@mimic-fi/v2-price-oracle/contracts/oracle/IPriceOracle.sol';
import '@mimic-fi/v2-price-oracle/contracts/feeds/PriceFeedProvider.sol';
import '@mimic-fi/v2-strategies/contracts/IStrategy.sol';
import '@mimic-fi/v2-bridge-connector/contracts/IBridgeConnector.sol';
import '@mimic-fi/v2-swap-connector/contracts/ISwapConnector.sol';
import '@mimic-fi/v2-registry/contracts/implementations/InitializableAuthorizedImplementation.sol';

import './ISmartVault.sol';
import './IWrappedNativeToken.sol';
import './helpers/StrategyLib.sol';
import './helpers/SwapConnectorLib.sol';
import './helpers/BridgeConnectorLib.sol';

/**
 * @title Smart Vault
 * @dev Smart Vault contract where funds are being held offering a bunch of primitives to allow users model any
 * type of action to manage them, these are: collector, withdraw, swap, bridge, join, exit, bridge, wrap, and unwrap.
 *
 * It inherits from InitializableAuthorizedImplementation which means it's implementation can be cloned
 * from the Mimic Registry and should be initialized depending on each case.
 */
contract SmartVault is ISmartVault, PriceFeedProvider, InitializableAuthorizedImplementation {
    using SafeERC20 for IERC20;
    using FixedPoint for uint256;
    using UncheckedMath for uint256;
    using StrategyLib for address;
    using SwapConnectorLib for address;
    using BridgeConnectorLib for address;

    // Namespace under which the Smart Vault is registered in the Mimic Registry
    bytes32 public constant override NAMESPACE = keccak256('SMART_VAULT');

    /**
     * @dev Fee configuration parameters
     * @param pct Percentage expressed using 16 decimals (1e18 = 100%)
     * @param cap Maximum amount of fees to be charged per period
     * @param token Address of the token to express the cap amount
     * @param period Period length in seconds
     * @param totalCharged Total amount of fees charged in the current period
     * @param nextResetTime Current cap period end date
     */
    struct Fee {
        uint256 pct;
        uint256 cap;
        address token;
        uint256 period;
        uint256 totalCharged;
        uint256 nextResetTime;
    }

    // Price oracle reference
    address public override priceOracle;

    // Swap connector reference
    address public override swapConnector;

    // Bridge connector reference
    address public override bridgeConnector;

    // List of allowed strategies indexed by strategy address
    mapping (address => bool) public override isStrategyAllowed;

    // List of invested values indexed by strategy address
    mapping (address => uint256) public override investedValue;

    // Fee collector address where fees will be deposited
    address public override feeCollector;

    // Withdraw fee configuration
    Fee public override withdrawFee;

    // Performance fee configuration
    Fee public override performanceFee;

    // Swap fee configuration
    Fee public override swapFee;

    // Bridge fee configuration
    Fee public override bridgeFee;

    // Wrapped native token reference
    address public immutable override wrappedNativeToken;

    /**
     * @dev Creates a new Smart Vault implementation with references that should be shared among all implementations
     * @param _wrappedNativeToken Address of the wrapped native token to be used
     * @param _registry Address of the Mimic Registry to be referenced
     */
    constructor(address _wrappedNativeToken, address _registry) InitializableAuthorizedImplementation(_registry) {
        wrappedNativeToken = _wrappedNativeToken;
    }

    /**
     * @dev Initializes the Smart Vault instance
     * @param admin Address that will be granted with admin rights
     */
    function initialize(address admin) external initializer {
        _initialize(admin);
    }

    /**
     * @dev It allows receiving native token transfers
     */
    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Sets a new strategy as allowed or not for a Smart Vault. Sender must be authorized.
     * @param strategy Address of the strategy to be set
     * @param allowed Whether the strategy is allowed or not
     */
    function setStrategy(address strategy, bool allowed) external override auth {
        _setStrategy(strategy, allowed);
    }

    /**
     * @dev Sets a new price oracle to a Smart Vault. Sender must be authorized.
     * @param newPriceOracle Address of the new price oracle to be set
     */
    function setPriceOracle(address newPriceOracle) external override auth {
        _setPriceOracle(newPriceOracle);
    }

    /**
     * @dev Sets a new swap connector to a Smart Vault. Sender must be authorized.
     * @param newSwapConnector Address of the new swap connector to be set
     */
    function setSwapConnector(address newSwapConnector) external override auth {
        _setSwapConnector(newSwapConnector);
    }

    /**
     * @dev Sets a new bridge connector to a Smart Vault. Sender must be authorized.
     * @param newBridgeConnector Address of the new bridge connector to be set
     */
    function setBridgeConnector(address newBridgeConnector) external override auth {
        _setBridgeConnector(newBridgeConnector);
    }

    /**
     * @dev Sets a new fee collector. Sender must be authorized.
     * @param newFeeCollector Address of the new fee collector to be set
     */
    function setFeeCollector(address newFeeCollector) external override auth {
        _setFeeCollector(newFeeCollector);
    }

    /**
     * @dev Sets a new withdraw fee. Sender must be authorized.
     * @param pct Withdraw fee percentage to be set
     * @param cap New maximum amount of withdraw fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the withdraw fee
     */
    function setWithdrawFee(uint256 pct, uint256 cap, address token, uint256 period) external override auth {
        _setFeeConfiguration(withdrawFee, pct, cap, token, period);
        emit WithdrawFeeSet(pct, cap, token, period);
    }

    /**
     * @dev Sets a new performance fee. Sender must be authorized.
     * @param pct Performance fee percentage to be set
     * @param cap New maximum amount of performance fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the performance fee
     */
    function setPerformanceFee(uint256 pct, uint256 cap, address token, uint256 period) external override auth {
        _setFeeConfiguration(performanceFee, pct, cap, token, period);
        emit PerformanceFeeSet(pct, cap, token, period);
    }

    /**
     * @dev Sets a new swap fee. Sender must be authorized.
     * @param pct New swap fee percentage to be set
     * @param cap New maximum amount of swap fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the swap fee
     */
    function setSwapFee(uint256 pct, uint256 cap, address token, uint256 period) external override auth {
        _setFeeConfiguration(swapFee, pct, cap, token, period);
        emit SwapFeeSet(pct, cap, token, period);
    }

    /**
     * @dev Sets a new bridge fee. Sender must be authorized.
     * @param pct New bridge fee percentage to be set
     * @param cap New maximum amount of bridge fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds for the bridge fee
     */
    function setBridgeFee(uint256 pct, uint256 cap, address token, uint256 period) external override auth {
        _setFeeConfiguration(bridgeFee, pct, cap, token, period);
        emit BridgeFeeSet(pct, cap, token, period);
    }

    /**
     * @dev Sets a of price feed
     * @param base Token base to be set
     * @param quote Token quote to be set
     * @param feed Price feed to be set
     */
    function setPriceFeed(address base, address quote, address feed)
        public
        override(IPriceFeedProvider, PriceFeedProvider)
        auth
    {
        super.setPriceFeed(base, quote, feed);
    }

    /**
     * @dev Tells the price of a token (base) in a given quote
     * @param base Token to rate
     * @param quote Token used for the price rate
     */
    function getPrice(address base, address quote) public view override returns (uint256) {
        return IPriceOracle(priceOracle).getPrice(address(this), base, quote);
    }

    /**
     * @dev Tells the last value accrued for a strategy. Note this value can be outdated.
     * @param strategy Address of the strategy querying the last value of
     */
    function lastValue(address strategy) public view override returns (uint256) {
        return IStrategy(strategy).lastValue(address(this));
    }

    /**
     * @dev Execute an arbitrary call from a Smart Vault. Sender must be authorized.
     * @param target Address where the call will be sent
     * @param data Calldata to be used for the call
     * @param value Value in wei that will be attached to the call
     * @return result Call response if it was successful, otherwise it reverts
     */
    function call(address target, bytes memory callData, uint256 value, bytes memory data)
        external
        override
        auth
        returns (bytes memory result)
    {
        result = Address.functionCallWithValue(target, callData, value, 'SMART_VAULT_ARBITRARY_CALL_FAIL');
        emit Call(target, callData, value, result, data);
    }

    /**
     * @dev Collect tokens from an external account to a Smart Vault. Sender must be authorized.
     * @param token Address of the token to be collected
     * @param from Address where the tokens will be transfer from
     * @param amount Amount of tokens to be transferred
     * @param data Extra data only logged
     * @return collected Amount of tokens collected
     */
    function collect(address token, address from, uint256 amount, bytes memory data)
        external
        override
        auth
        returns (uint256 collected)
    {
        require(amount > 0, 'COLLECT_AMOUNT_ZERO');

        uint256 previousBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(from, address(this), amount);
        uint256 currentBalance = IERC20(token).balanceOf(address(this));

        collected = currentBalance - previousBalance;
        emit Collect(token, from, collected, data);
    }

    /**
     * @dev Withdraw tokens to an external account. Sender must be authorized.
     * @param token Address of the token to be withdrawn
     * @param amount Amount of tokens to withdraw
     * @param recipient Address where the tokens will be transferred to
     * @param data Extra data only logged
     * @return withdrawn Amount of tokens transferred to the recipient address
     */
    function withdraw(address token, uint256 amount, address recipient, bytes memory data)
        external
        override
        auth
        returns (uint256 withdrawn)
    {
        require(amount > 0, 'WITHDRAW_AMOUNT_ZERO');
        require(recipient != address(0), 'RECIPIENT_ZERO');

        uint256 withdrawFeeAmount = recipient == feeCollector ? 0 : _payFee(token, amount, withdrawFee);
        withdrawn = amount - withdrawFeeAmount;
        _safeTransfer(token, recipient, withdrawn);
        emit Withdraw(token, recipient, withdrawn, withdrawFeeAmount, data);
    }

    /**
     * @dev Wrap an amount of native tokens to the wrapped ERC20 version of it. Sender must be authorized.
     * @param amount Amount of native tokens to be wrapped
     * @param data Extra data only logged
     * @return wrapped Amount of tokens wrapped
     */
    function wrap(uint256 amount, bytes memory data) external override auth returns (uint256 wrapped) {
        require(amount > 0, 'WRAP_AMOUNT_ZERO');
        require(address(this).balance >= amount, 'WRAP_INSUFFICIENT_AMOUNT');

        IWrappedNativeToken wrappedToken = IWrappedNativeToken(wrappedNativeToken);
        uint256 previousBalance = wrappedToken.balanceOf(address(this));
        wrappedToken.deposit{ value: amount }();
        uint256 currentBalance = wrappedToken.balanceOf(address(this));

        wrapped = currentBalance - previousBalance;
        emit Wrap(amount, wrapped, data);
    }

    /**
     * @dev Unwrap an amount of wrapped native tokens. Sender must be authorized.
     * @param amount Amount of wrapped native tokens to unwrapped
     * @param data Extra data only logged
     * @return unwrapped Amount of tokens unwrapped
     */
    function unwrap(uint256 amount, bytes memory data) external override auth returns (uint256 unwrapped) {
        require(amount > 0, 'UNWRAP_AMOUNT_ZERO');

        uint256 previousBalance = address(this).balance;
        IWrappedNativeToken(wrappedNativeToken).withdraw(amount);
        uint256 currentBalance = address(this).balance;

        unwrapped = currentBalance - previousBalance;
        emit Unwrap(amount, unwrapped, data);
    }

    /**
     * @dev Claim strategy rewards. Sender must be authorized.
     * @param strategy Address of the strategy to claim rewards
     * @param data Extra data passed to the strategy and logged
     * @return tokens Addresses of the tokens received as rewards
     * @return amounts Amounts of the tokens received as rewards
     */
    function claim(address strategy, bytes memory data)
        external
        override
        auth
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        require(isStrategyAllowed[strategy], 'STRATEGY_NOT_ALLOWED');
        (tokens, amounts) = strategy.claim(data);
        emit Claim(strategy, tokens, amounts, data);
    }

    /**
     * @dev Join a strategy with an amount of tokens. Sender must be authorized.
     * @param strategy Address of the strategy to join
     * @param tokensIn List of token addresses to join with
     * @param amountsIn List of token amounts to join with
     * @param slippage Slippage that will be used to compute the join
     * @param data Extra data passed to the strategy and logged
     * @return tokensOut List of token addresses received after the join
     * @return amountsOut List of token amounts received after the join
     */
    function join(
        address strategy,
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        uint256 slippage,
        bytes memory data
    ) external override auth returns (address[] memory tokensOut, uint256[] memory amountsOut) {
        require(isStrategyAllowed[strategy], 'STRATEGY_NOT_ALLOWED');
        require(slippage <= FixedPoint.ONE, 'JOIN_SLIPPAGE_ABOVE_ONE');
        require(tokensIn.length == amountsIn.length, 'JOIN_INPUT_INVALID_LENGTH');

        uint256 value;
        (tokensOut, amountsOut, value) = strategy.join(tokensIn, amountsIn, slippage, data);
        require(tokensOut.length == amountsOut.length, 'JOIN_OUTPUT_INVALID_LENGTH');

        investedValue[strategy] = investedValue[strategy] + value;
        emit Join(strategy, tokensIn, amountsIn, tokensOut, amountsOut, value, slippage, data);
    }

    /**
     * @dev Exit a strategy. Sender must be authorized.
     * @param strategy Address of the strategy to exit
     * @param tokensIn List of token addresses to exit with
     * @param amountsIn List of token amounts to exit with
     * @param slippage Slippage that will be used to compute the exit
     * @param data Extra data passed to the strategy and logged
     * @return tokensOut List of token addresses received after the exit
     * @return amountsOut List of token amounts received after the exit
     */
    function exit(
        address strategy,
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        uint256 slippage,
        bytes memory data
    ) external override auth returns (address[] memory tokensOut, uint256[] memory amountsOut) {
        require(isStrategyAllowed[strategy], 'STRATEGY_NOT_ALLOWED');
        require(investedValue[strategy] > 0, 'EXIT_NO_INVESTED_VALUE');
        require(slippage <= FixedPoint.ONE, 'EXIT_SLIPPAGE_ABOVE_ONE');
        require(tokensIn.length == amountsIn.length, 'EXIT_INPUT_INVALID_LENGTH');

        uint256 value;
        (tokensOut, amountsOut, value) = strategy.exit(tokensIn, amountsIn, slippage, data);
        require(tokensOut.length == amountsOut.length, 'EXIT_OUTPUT_INVALID_LENGTH');
        uint256[] memory performanceFeeAmounts = new uint256[](amountsOut.length);

        // It can rely on the last updated value since we have just exited, no need to compute current value
        uint256 valueBeforeExit = lastValue(strategy) + value;
        if (valueBeforeExit <= investedValue[strategy]) {
            // There were losses, invested value is simply reduced using the exited ratio compared to the value
            // before exit. Invested value is round up to avoid interpreting losses due to rounding errors
            investedValue[strategy] -= investedValue[strategy].mulUp(value).divUp(valueBeforeExit);
        } else {
            // If value gains are greater than the exit value, it means only gains are being withdrawn. In that case
            // the taxable amount is the entire exited amount, otherwise it should be the equivalent gains ratio of it.
            uint256 valueGains = valueBeforeExit.uncheckedSub(investedValue[strategy]);
            bool onlyGains = valueGains >= value;

            // If the exit value is greater than the value gains, the invested value should be reduced by the portion
            // of the invested value being exited. Otherwise, it's still the same, only gains are being withdrawn.
            // No need for checked math as we are checking it manually beforehand
            uint256 decrement = onlyGains ? 0 : value.uncheckedSub(valueGains);
            investedValue[strategy] = investedValue[strategy] - decrement;

            // Compute performance fees per token out
            for (uint256 i = 0; i < tokensOut.length; i = i.uncheckedAdd(1)) {
                address token = tokensOut[i];
                uint256 amount = amountsOut[i];
                uint256 taxableAmount = onlyGains ? amount : ((amount * valueGains) / value);
                uint256 feeAmount = _payFee(token, taxableAmount, performanceFee);
                amountsOut[i] = amount - feeAmount;
                performanceFeeAmounts[i] = feeAmount;
            }
        }

        emit Exit(strategy, tokensIn, amountsIn, tokensOut, amountsOut, value, performanceFeeAmounts, slippage, data);
    }

    /**
     * @dev Swaps two tokens. Sender must be authorized.
     * @param source Source to request the swap: Uniswap V2, Uniswap V3, Balancer V2, or Paraswap V5.
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param limitType Swap limit to be applied: slippage or min amount out
     * @param limitAmount Amount of the swap limit to be applied depending on limitType
     * @param data Encoded data to specify different swap parameters depending on the source picked
     * @return amountOut Received amount of tokens out
     */
    function swap(
        uint8 source,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        SwapLimit limitType,
        uint256 limitAmount,
        bytes memory data
    ) external override auth returns (uint256 amountOut) {
        require(tokenIn != tokenOut, 'SWAP_SAME_TOKEN');
        require(swapConnector != address(0), 'SWAP_CONNECTOR_NOT_SET');

        uint256 minAmountOut;
        if (limitType == SwapLimit.MinAmountOut) {
            minAmountOut = limitAmount;
        } else if (limitType == SwapLimit.Slippage) {
            require(limitAmount <= FixedPoint.ONE, 'SWAP_SLIPPAGE_ABOVE_ONE');
            uint256 price = getPrice(tokenIn, tokenOut);
            // No need for checked math as we are checking it manually beforehand
            // Always round up the expected min amount out. Limit amount is slippage.
            minAmountOut = amountIn.mulUp(price).mulUp(FixedPoint.ONE.uncheckedSub(limitAmount));
        } else {
            revert('SWAP_INVALID_LIMIT_TYPE');
        }

        uint256 preBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 preBalanceOut = IERC20(tokenOut).balanceOf(address(this));
        swapConnector.swap(source, tokenIn, tokenOut, amountIn, minAmountOut, data);

        uint256 postBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        require(postBalanceIn >= preBalanceIn - amountIn, 'SWAP_BAD_TOKEN_IN_BALANCE');

        uint256 amountOutBeforeFees = IERC20(tokenOut).balanceOf(address(this)) - preBalanceOut;
        require(amountOutBeforeFees >= minAmountOut, 'SWAP_MIN_AMOUNT');

        uint256 swapFeeAmount = _payFee(tokenOut, amountOutBeforeFees, swapFee);
        amountOut = amountOutBeforeFees - swapFeeAmount;
        emit Swap(source, tokenIn, tokenOut, amountIn, amountOut, minAmountOut, swapFeeAmount, data);
    }

    /**
     * @dev Bridge assets to another chain
     * @param source Source to request the bridge. It depends on the Bridge Connector attached to a Smart Vault.
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param limitType Bridge limit to be applied: slippage or min amount out
     * @param limitAmount Amount of the swap limit to be applied depending on limitType
     * @param recipient Address that will receive the tokens on the destination chain
     * @param data Encoded data to specify different bridge parameters depending on the source picked
     * @return bridged Amount requested to be bridged after fees
     */
    function bridge(
        uint8 source,
        uint256 chainId,
        address token,
        uint256 amount,
        BridgeLimit limitType,
        uint256 limitAmount,
        address recipient,
        bytes memory data
    ) external override auth returns (uint256 bridged) {
        require(block.chainid != chainId, 'BRIDGE_SAME_CHAIN');
        require(recipient != address(0), 'BRIDGE_RECIPIENT_ZERO');
        require(bridgeConnector != address(0), 'BRIDGE_CONNECTOR_NOT_SET');

        uint256 bridgeFeeAmount = _payFee(token, amount, bridgeFee);
        bridged = amount - bridgeFeeAmount;

        uint256 minAmountOut;
        if (limitType == BridgeLimit.MinAmountOut) {
            minAmountOut = limitAmount;
        } else if (limitType == BridgeLimit.Slippage) {
            require(limitAmount <= FixedPoint.ONE, 'BRIDGE_SLIPPAGE_ABOVE_ONE');
            // No need for checked math as we are checking it manually beforehand
            // Always round up the expected min amount out. Limit amount is slippage.
            minAmountOut = bridged.mulUp(FixedPoint.ONE.uncheckedSub(limitAmount));
        } else {
            revert('BRIDGE_INVALID_LIMIT_TYPE');
        }

        uint256 preBalanceIn = IERC20(token).balanceOf(address(this));
        bridgeConnector.bridge(source, chainId, token, bridged, minAmountOut, recipient, data);
        uint256 postBalanceIn = IERC20(token).balanceOf(address(this));
        require(postBalanceIn >= preBalanceIn - bridged, 'BRIDGE_BAD_TOKEN_IN_BALANCE');

        emit Bridge(source, chainId, token, bridged, minAmountOut, bridgeFeeAmount, recipient, data);
    }

    /**
     * @dev Internal function to pay the amount of fees to be charged based on a fee configuration to the fee collector
     * @param token Token being charged
     * @param amount Token amount to be taxed with fees
     * @param fee Fee configuration to be applied
     * @return paidAmount Amount of fees paid to the fee collector
     */
    function _payFee(address token, uint256 amount, Fee storage fee) internal returns (uint256 paidAmount) {
        // Fee amounts are always rounded down
        uint256 feeAmount = amount.mulDown(fee.pct);

        // If cap amount or cap period are not set, charge the entire amount
        if (fee.token == address(0) || fee.cap == 0 || fee.period == 0) {
            _safeTransfer(token, feeCollector, feeAmount);
            return feeAmount;
        }

        // Reset cap totalizator if necessary
        if (block.timestamp >= fee.nextResetTime) {
            fee.totalCharged = 0;
            fee.nextResetTime = block.timestamp + fee.period;
        }

        // Calc fee amount in the fee token used for the cap
        uint256 feeTokenPrice = getPrice(token, fee.token);
        uint256 feeAmountInFeeToken = feeAmount.mulDown(feeTokenPrice);

        // Compute fee amount picking the minimum between the chargeable amount and the remaining part for the cap
        if (fee.totalCharged + feeAmountInFeeToken <= fee.cap) {
            paidAmount = feeAmount;
            fee.totalCharged += feeAmountInFeeToken;
        } else if (fee.totalCharged < fee.cap) {
            paidAmount = (fee.cap.uncheckedSub(fee.totalCharged) * feeAmount) / feeAmountInFeeToken;
            fee.totalCharged = fee.cap;
        } else {
            // This case is when the total charged amount is already greater than the cap amount. It could happen if
            // the cap amounts is decreased or if the cap token is changed. In this case the total charged amount is
            // not updated, and the amount to paid is zero.
            paidAmount = 0;
        }

        // Pay fee amount to the fee collector
        _safeTransfer(token, feeCollector, paidAmount);
    }

    /**
     * @dev Internal method to transfer ERC20 or native tokens from a Smart Vault
     * @param token Address of the ERC20 token to transfer
     * @param to Address transferring the tokens to
     * @param amount Amount of tokens to transfer
     */
    function _safeTransfer(address token, address to, uint256 amount) internal {
        if (amount == 0) return;
        if (Denominations.isNativeToken(token)) Address.sendValue(payable(to), amount);
        else IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @dev Sets a new strategy as allowed or not
     * @param strategy Address of the strategy to be set
     * @param allowed Whether the strategy is allowed or not
     */
    function _setStrategy(address strategy, bool allowed) internal {
        if (allowed) _validateStatelessDependency(strategy);
        isStrategyAllowed[strategy] = allowed;
        emit StrategySet(strategy, allowed);
    }

    /**
     * @dev Sets a new price oracle
     * @param newPriceOracle New price oracle to be set
     */
    function _setPriceOracle(address newPriceOracle) internal {
        _validateStatelessDependency(newPriceOracle);
        priceOracle = newPriceOracle;
        emit PriceOracleSet(newPriceOracle);
    }

    /**
     * @dev Sets a new swap connector
     * @param newSwapConnector New swap connector to be set
     */
    function _setSwapConnector(address newSwapConnector) internal {
        _validateStatelessDependency(newSwapConnector);
        swapConnector = newSwapConnector;
        emit SwapConnectorSet(newSwapConnector);
    }

    /**
     * @dev Sets a new bridge connector
     * @param newBridgeConnector New bridge connector to be set
     */
    function _setBridgeConnector(address newBridgeConnector) internal {
        _validateStatelessDependency(newBridgeConnector);
        bridgeConnector = newBridgeConnector;
        emit BridgeConnectorSet(newBridgeConnector);
    }

    /**
     * @dev Internal method to set the fee collector
     * @param newFeeCollector New fee collector to be set
     */
    function _setFeeCollector(address newFeeCollector) internal {
        require(newFeeCollector != address(0), 'FEE_COLLECTOR_ZERO');
        feeCollector = newFeeCollector;
        emit FeeCollectorSet(newFeeCollector);
    }

    /**
     * @dev Internal method to set a new fee cap configuration
     * @param fee Fee configuration to be updated
     * @param pct Fee percentage to be set
     * @param cap New maximum amount of fees to be charged per period
     * @param token Address of the token cap to be set
     * @param period New cap period length in seconds
     */
    function _setFeeConfiguration(Fee storage fee, uint256 pct, uint256 cap, address token, uint256 period) internal {
        require(pct <= FixedPoint.ONE, 'FEE_PCT_ABOVE_ONE');

        // If there is no fee percentage, there must not be a fee cap
        bool isZeroCap = token == address(0) && cap == 0 && period == 0;
        require(pct != 0 || isZeroCap, 'INVALID_CAP_WITH_FEE_ZERO');

        // If there is a cap, all values must be non-zero
        bool isNonZeroCap = token != address(0) && cap != 0 && period != 0;
        require(isZeroCap || isNonZeroCap, 'INCONSISTENT_CAP_VALUES');

        // Changing the fee percentage does not affect the totalizator at all, it only affects future fee charges
        fee.pct = pct;

        // Changing the fee cap amount does not affect the totalizator, it only applies when changing the for the total
        // charged amount. Note that it can happen that the cap amount is lower than the total charged amount if the
        // cap amount is lowered. However, there shouldn't be any accounting issues with that.
        fee.cap = cap;

        // Changing the cap period only affects the end time of the next period, but not the end date of the current one
        fee.period = period;

        // Therefore, only clean the totalizators if the cap is being removed
        if (isZeroCap) {
            fee.totalCharged = 0;
            fee.nextResetTime = 0;
        } else {
            // If cap values are not zero, set the next reset time if it wasn't set already
            // Otherwise, if the cap token is being changed the total charged amount must be updated accordingly
            if (fee.nextResetTime == 0) {
                fee.nextResetTime = block.timestamp + period;
            } else if (fee.token != token) {
                uint256 newTokenPrice = getPrice(fee.token, token);
                fee.totalCharged = fee.totalCharged.mulDown(newTokenPrice);
            }
        }

        // Finally simply set the new requested token
        fee.token = token;
    }
}