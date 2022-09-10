// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/IDepositZap.sol";
import "../../interfaces/curve/IStableSwapPool.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

contract CurveControllerMetaTemplate is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Underlying pool of meta pool
    address public immutable basePoolAddress;

    /*
     * Deposit zap used to operate both meta pool and underlying tokens
     * https://curve.readthedocs.io/exchange-deposits.html
     */
    address public immutable zapAddress;

    uint256 public constant N_COINS = 4;

    constructor(
        address _manager,
        address _accessControl,
        address _addressRegistry,
        address _basePoolAddress,
        address _zapAddress
    ) public BaseController(_manager, _accessControl, _addressRegistry) {
        require(address(_basePoolAddress) != address(0), "INVALID_CURVE_BASE_POOL_ADDRESS");
        require(address(_zapAddress) != address(0), "INVALID_CURVE_DEPOSIT_ZAP_ADDRESS");
        basePoolAddress = _basePoolAddress;
        zapAddress = _zapAddress;
    }

    /// @notice Deploy liquidity to Curve pool using Deposit Zap
    /// @dev Calls to external contract
    /// @dev We trust sender to send a true curve metaPoolAddress. If it's not the case it will fail in the add_liquidity part.
    /// @param metaPoolAddress Meta pool address
    /// @param amounts List of amounts of coins to deposit
    /// @param minMintAmount Minimum amount of LP tokens to mint from the deposit
    function deploy(
        address metaPoolAddress,
        uint256[N_COINS] calldata amounts,
        uint256 minMintAmount
    ) external onlyManager onlyAddLiquidity {
        address lpTokenAddress = metaPoolAddress;

        for (uint256 i = 0; i < N_COINS; ++i) {
            if (amounts[i] > 0) {
                address poolAddress;
                uint256 coinIndex;

                if (i == 0) {
                    // The first coin is a coin from meta pool
                    poolAddress = metaPoolAddress;
                    coinIndex = 0;
                } else {
                    // Coins from underlying base pool
                    poolAddress = basePoolAddress;
                    coinIndex = i - 1;
                }
                address coin = IStableSwapPool(poolAddress).coins(coinIndex);

                _validateCoin(coin, amounts[i]);

                _approve(IERC20(coin), amounts[i]);
            }
        }
        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        IDepositZap(zapAddress).add_liquidity(metaPoolAddress, amounts, minMintAmount);
        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

        require(lpTokenBalanceAfter.sub(lpTokenBalanceBefore) >= minMintAmount, "LP_AMT_TOO_LOW");
    }

    /// @notice Withdraw liquidity from Curve pool
    /// @dev Calls to external contract
    /// @dev We trust sender to send a true curve metaPoolAddress. If it's not the case it will fail in the remove_liquidity_imbalance part.
    /// @param metaPoolAddress Meta pool address
    /// @param amounts List of amounts of underlying coins to withdraw
    /// @param maxBurnAmount Maximum amount of LP token to burn in the withdrawal
    function withdrawImbalance(
        address metaPoolAddress,
        uint256[N_COINS] memory amounts,
        uint256 maxBurnAmount
    ) external onlyManager onlyRemoveLiquidity {
        address lpTokenAddress = _getLPTokenAndApprove(metaPoolAddress, maxBurnAmount);

        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(metaPoolAddress);

        IDepositZap(zapAddress).remove_liquidity_imbalance(metaPoolAddress, amounts, maxBurnAmount);

        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(metaPoolAddress);

        _compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, amounts);

        require(lpTokenBalanceBefore.sub(lpTokenBalanceAfter) <= maxBurnAmount, "LP_COST_TOO_HIGH");
    }

    /// @notice Withdraw liquidity from Curve pool
    /// @dev Calls to external contract
    /// @dev We trust sender to send a true curve metaPoolAddress. If it's not the case it will fail in the remove_liquidity part.
    /// @param metaPoolAddress Meta pool address
    /// @param amount Quantity of LP tokens to burn in the withdrawal
    /// @param minAmounts Minimum amounts of underlying coins to receive
    function withdraw(
        address metaPoolAddress,
        uint256 amount,
        uint256[N_COINS] memory minAmounts
    ) external onlyManager onlyRemoveLiquidity {
        address lpTokenAddress = _getLPTokenAndApprove(metaPoolAddress, amount);

        uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(metaPoolAddress);

        IDepositZap(zapAddress).remove_liquidity(metaPoolAddress, amount, minAmounts);

        uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
        uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(metaPoolAddress);

        _compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

        require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");
    }

    function _validateCoin(address coin, uint256 amount) internal {
        require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

        uint256 balance = IERC20(coin).balanceOf(address(this));

        require(balance >= amount, "INSUFFICIENT_BALANCE");
    }

    function _getCoinsBalances(address metaPoolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
        // Coin from meta pool
        address firstCoin = IStableSwapPool(metaPoolAddress).coins(0);
        coinsBalances[0] = IERC20(firstCoin).balanceOf(address(this));

        // Coins from underlying pool
        for (uint256 i = 1; i < N_COINS; ++i) {
            address coin = IStableSwapPool(basePoolAddress).coins(i - 1);
            uint256 balance = IERC20(coin).balanceOf(address(this));
            coinsBalances[i] = balance;
        }
        return coinsBalances;
    }

    function _compareCoinsBalances(
        uint256[N_COINS] memory balancesBefore,
        uint256[N_COINS] memory balancesAfter,
        uint256[N_COINS] memory amounts
    ) internal pure {
        for (uint256 i = 0; i < N_COINS; ++i) {
            uint256 minAmount = amounts[i];
            require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
        }
    }

    function _getLPTokenAndApprove(address metaPoolAddress, uint256 amount) internal returns (address) {
        // Meta pool is an ERC20 LP token of that pool at the same time
        address lpTokenAddress = metaPoolAddress;

        _approve(IERC20(lpTokenAddress), amount);

        return lpTokenAddress;
    }

    function _approve(IERC20 token, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), zapAddress);
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(zapAddress, currentAllowance);
        }
        token.safeIncreaseAllowance(zapAddress, amount);
    }
}