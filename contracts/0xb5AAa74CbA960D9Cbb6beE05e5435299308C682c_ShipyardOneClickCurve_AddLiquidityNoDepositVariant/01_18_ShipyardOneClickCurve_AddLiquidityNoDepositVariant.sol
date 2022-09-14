// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/common/IUniswapRouterETH.sol";
import "../interfaces/company/IShipyardVault.sol";
import "../interfaces/company/IStrategyCurve.sol";
import "../interfaces/curve/ICurveSwap.sol";
import "../libraries/SafeCurveSwap.sol";
import "../libraries/SafeUniswapRouter.sol";
import "../managers/SlippageManager.sol";
import "../utils/AddressUtils.sol";

contract ShipyardOneClickCurve_AddLiquidityNoDepositVariant is Ownable, SlippageManager, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeERC20 for IShipyardVault;
    using SafeMath for uint256;
    using SafeCurveSwap for ICurveSwap;
    using SafeUniswapRouter for IUniswapRouterETH;

    address public immutable usdcAddress;

    constructor(
        address _usdcAddress
    ) public {
        usdcAddress = AddressUtils.validateOneAndReturn(_usdcAddress);
    }

    function deposit(address _shipyardVaultAddress, address _depositTokenAddress, uint256 _amountInDepositToken) external nonReentrant {

        IShipyardVault shipyardVault = IShipyardVault(_shipyardVaultAddress);
        IStrategyCurve strategy = IStrategyCurve(shipyardVault.strategy());

        address poolTokenAddress = (address)(strategy.want());

        bool isUnderlyingToken = strategy.underlyingToken(_depositTokenAddress);

        require(isUnderlyingToken || _depositTokenAddress == usdcAddress || _depositTokenAddress == poolTokenAddress, 'Invalid deposit token address');

        if (isUnderlyingToken || _depositTokenAddress == poolTokenAddress) {

            IERC20(_depositTokenAddress).safeTransferFrom(msg.sender, address(this), _amountInDepositToken);

        } else if (_depositTokenAddress == usdcAddress) {

            address preferredTokenAddress = strategy.preferredUnderlyingToken();

            IERC20(usdcAddress).safeTransferFrom(msg.sender, address(this), _amountInDepositToken);

            // Swap into preferredToken

            address[] memory paths;
            paths[0] = usdcAddress;
            paths[1] = preferredTokenAddress;

            address unirouterAddress = strategy.unirouter();

            _approveTokenIfNeeded(usdcAddress, unirouterAddress);

            _amountInDepositToken = IERC20(_depositTokenAddress).balanceOf(address(this));

            IUniswapRouterETH(unirouterAddress).safeSwapExactTokensForTokens(slippage, _amountInDepositToken, paths, address(this), block.timestamp);

            _depositTokenAddress = preferredTokenAddress;
        }

        _amountInDepositToken = IERC20(_depositTokenAddress).balanceOf(address(this));

        address poolAddress = strategy.pool();

        if (_depositTokenAddress != poolTokenAddress) {

            uint256 depositTokenIndex = strategy.underlyingTokenIndex(_depositTokenAddress);
            uint256 poolSize = strategy.poolSize();

            _approveTokenIfNeeded(_depositTokenAddress, poolAddress);

            require(poolSize == 2);

            uint256[2] memory amounts;
            amounts[depositTokenIndex] = _amountInDepositToken;
            ICurveSwap(poolAddress).safeAddLiquidityUsingNoDepositSlippageCalculation(slippage, amounts);
        }

        uint256 amountPoolToken = IERC20(poolTokenAddress).balanceOf(address(this));

        // We now have the pool token so let’s call our vault contract

        _approveTokenIfNeeded(poolTokenAddress, _shipyardVaultAddress);

        shipyardVault.deposit(amountPoolToken);

        // After we get back the shipyard LP token we can give to the sender

        uint256 amountShipyardToken = shipyardVault.balanceOf(address(this));

        shipyardVault.safeTransfer(msg.sender, amountShipyardToken);
    }

    function withdraw(address _shipyardVaultAddress, address _requestedTokenAddress, uint256 _withdrawAmountInShipToken) external nonReentrant {

        IShipyardVault shipyardVault = IShipyardVault(_shipyardVaultAddress);
        IStrategyCurve strategy = IStrategyCurve(shipyardVault.strategy());

        bool isUnderlyingToken = strategy.underlyingToken(_requestedTokenAddress);

        address poolTokenAddress = (address)(strategy.want());

        require(isUnderlyingToken || _requestedTokenAddress == poolTokenAddress || _requestedTokenAddress == usdcAddress, 'Invalid withdraw token address');

        shipyardVault.safeTransferFrom(msg.sender, address(this), _withdrawAmountInShipToken);

        _withdrawAmountInShipToken = shipyardVault.balanceOf(address(this));

        shipyardVault.withdraw(_withdrawAmountInShipToken);

        uint256 poolTokenBalance = IERC20(poolTokenAddress).balanceOf(address(this));

        if (_requestedTokenAddress == poolTokenAddress) {

            IERC20(poolTokenAddress).safeTransfer(msg.sender, poolTokenBalance);
            return;
        }

        address poolAddress = strategy.pool();

        _approveTokenIfNeeded(poolTokenAddress, poolAddress);

        if (isUnderlyingToken) {

            ICurveSwap(poolAddress).safeRemoveLiquidityOneCoin(
                slippage,
                poolTokenBalance,
                int128(strategy.underlyingTokenIndex(_requestedTokenAddress))
            );

            uint256 outputTokenBalance = IERC20(_requestedTokenAddress).balanceOf(address(this));

            IERC20(_requestedTokenAddress).safeTransfer(msg.sender, outputTokenBalance);
            return;
        }

        // Withdraw token must be USDC by this point

        address preferredTokenAddress = strategy.preferredUnderlyingToken();

        ICurveSwap(poolAddress).safeRemoveLiquidityOneCoin(
            slippage,
            poolTokenBalance,
            int128(strategy.underlyingTokenIndex(preferredTokenAddress))
        );

        // Swap from preferredToken to USDC

        address[] memory paths;
        paths[0] = preferredTokenAddress;
        paths[1] = usdcAddress;

        address unirouter = strategy.unirouter();

        _approveTokenIfNeeded(preferredTokenAddress, unirouter);

        IUniswapRouterETH(unirouter).safeSwapExactTokensForTokens(slippage, poolTokenBalance, paths, address(this), block.timestamp);

        uint256 usdcBalance = IERC20(usdcAddress).balanceOf(address(this));

        IERC20(usdcAddress).safeTransfer(msg.sender, usdcBalance);
    }

    function _approveTokenIfNeeded(address token, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, uint256(~0));
        }
    }
}