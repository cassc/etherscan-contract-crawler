// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";

import { MetavisorBaseVault, IERC20MetadataUpgradeable, IWETH9, SafeERC20Upgradeable, VaultType, VaultSpec } from "./MetavisorBaseVault.sol";
import { UniswapInteractionHelper, TicksData, PRICE_IMPACT_DENOMINATOR } from "../helpers/UniswapInteractionHelper.sol";
import { DENOMINATOR } from "../MetavisorRegistry.sol";
import { Errors } from "../helpers/Errors.sol";

contract MetavisorManagedVault is MetavisorBaseVault, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using SafeERC20Upgradeable for IWETH9;

    // solhint-disable func-name-mixedcase
    function __MetavisorManagedVault__init(
        address _registry,
        address _pool,
        VaultType _vaultType
    ) external initializer {
        __MetavisorBaseVault_init(_registry, _pool, _vaultType);
        __ReentrancyGuard_init();

        (int24 tickSpread, , , ) = metavisorRegistry.vaultSpec(address(this));
        (, int24 currentTick) = UniswapInteractionHelper.getSqrtRatioX96AndTick(pool);

        ticksData = UniswapInteractionHelper.getBaseTicks(
            currentTick,
            tickSpacing * tickSpread,
            tickSpacing
        );
    }

    constructor() {
        _disableInitializers();
    }

    /*
     ** Data
     */
    TicksData public ticksData;

    /*
     ** Modifiers
     */
    modifier validateTwap() {
        (, , uint32 twapInterval, uint256 priceThreshold) = metavisorRegistry.vaultSpec(
            address(this)
        );

        if (!UniswapInteractionHelper.isTwapWithinThreshold(pool, twapInterval, priceThreshold)) {
            revert Errors.TwapCheckFailed(twapInterval, priceThreshold);
        }
        _;
    }

    /*
     ** Events
     */
    event Deposited(address indexed depositor, uint256 shares, uint256 amount0, uint256 amount1);
    event Withdrawn(address indexed withdrawer, uint256 shares, uint256 amount0, uint256 amount1);
    event FeeClaimed(uint256 fees0, uint256 fees1);
    event Compounded(uint256 amount0, uint256 amount1);
    event Rescaled(int24 tickLower, int24 tickUpper);

    /*
     ** Uniswap Callbacks
     */
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata
    ) external override onlyPool {
        if (amount0Owed > 0) {
            token0.safeTransfer(msg.sender, amount0Owed);
        }
        if (amount1Owed > 0) {
            token1.safeTransfer(msg.sender, amount1Owed);
        }
    }

    function uniswapV3SwapCallback(
        int256 amount0Owed,
        int256 amount1Owed,
        bytes calldata
    ) external override onlyPool {
        if (amount0Owed > 0) {
            token0.safeTransfer(msg.sender, uint256(amount0Owed));
        }
        if (amount1Owed > 0) {
            token1.safeTransfer(msg.sender, uint256(amount1Owed));
        }
    }

    /*
     ** Core Interactions
     */
    function deposit(
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min
    ) external payable nonReentrant validateTwap returns (uint256 shares) {
        if (amount0 != 0 || amount1 != 0) {
            uint256 tSupply = totalSupply();

            if (tSupply != 0) {
                _compound(true); // Ensures only collectable fee is used for share computation
            }

            shares = UniswapInteractionHelper.computeShares(
                pool,
                amount0,
                amount1,
                _balance0(),
                _balance1(),
                tSupply,
                ticksData
            );

            _transferReceive(token0, msg.sender, address(this), amount0);
            _transferReceive(token1, msg.sender, address(this), amount1);

            UniswapInteractionHelper.mintLiquidity(
                pool,
                ticksData,
                amount0,
                amount1,
                amount0Min,
                amount1Min
            );

            _mint(msg.sender, shares);

            emit Deposited(msg.sender, shares, amount0, amount1);
        } else {
            revert Errors.InvalidDeposit();
        }
    }

    function withdraw(
        uint256 shares,
        bool _asEth,
        uint256 amount0Min,
        uint256 amount1Min
    ) external nonReentrant validateTwap returns (uint256 amount0, uint256 amount1) {
        if (shares == 0) {
            revert Errors.InvalidWithdraw(shares);
        }

        uint256 tSupply = totalSupply();

        if (shares > tSupply) {
            revert Errors.InvalidWithdraw(shares);
        }

        uint256 fees0;
        uint256 fees1;

        (amount0, amount1, fees0, fees1) = UniswapInteractionHelper.burnLiquidity(
            pool,
            ticksData,
            shares,
            tSupply,
            amount0Min,
            amount1Min
        );

        emit FeeClaimed(fees0, fees1);
        transferProtocolFees(fees0, fees1);

        amount0 += FullMath.mulDiv(_balance0() - amount0, shares, tSupply);
        amount1 += FullMath.mulDiv(_balance1() - amount1, shares, tSupply);

        _burn(msg.sender, shares);

        _transferSend(token0, msg.sender, amount0, _asEth);
        _transferSend(token1, msg.sender, amount1, _asEth);

        emit Withdrawn(msg.sender, shares, amount0, amount1);

        if (totalSupply() != 0) {
            _compound(false);
        }
    }

    function compound() external nonReentrant validateTwap {
        if (totalSupply() == 0) {
            revert Errors.InvalidCompound();
        }
        _compound(true);
    }

    function canRescale() public view returns (bool) {
        (, int24 currentTick) = UniswapInteractionHelper.getSqrtRatioX96AndTick(pool);
        (, int24 tickOpen, , ) = metavisorRegistry.vaultSpec(address(this));

        if (currentTick < ticksData.tickLower || currentTick > ticksData.tickUpper) {
            return true;
        }

        int24 deltaLower = UniswapInteractionHelper.abs(ticksData.tickLower - currentTick);
        int24 deltaUpper = UniswapInteractionHelper.abs(ticksData.tickUpper - currentTick);

        return deltaLower < tickOpen * tickSpacing || deltaUpper < tickOpen * tickSpacing;
    }

    function rescale(uint160 maxPriceImpact) external nonReentrant validateTwap {
        if (!canRescale()) {
            revert Errors.CanNotRescale();
        }
        if (!metavisorRegistry.isAllowedToRescale(msg.sender)) {
            revert Errors.NotAllowedToRescale(msg.sender);
        }
        if (maxPriceImpact >= PRICE_IMPACT_DENOMINATOR) {
            revert Errors.InvalidPriceImpact(maxPriceImpact);
        }

        (uint128 totalLiquidity, , ) = UniswapInteractionHelper.getLiquidityInPosition(
            pool,
            ticksData
        );

        if (totalLiquidity == 0) {
            revert Errors.NoLiquidity();
        }

        (, , uint256 fees0, uint256 fees1) = UniswapInteractionHelper.burnLiquidity(
            pool,
            ticksData,
            type(uint256).max,
            totalSupply(),
            0,
            0
        );

        emit FeeClaimed(fees0, fees1);
        transferProtocolFees(fees0, fees1);

        uint256 swapPercentage = metavisorRegistry.swapPercentage();
        (int24 tickSpread, , , ) = metavisorRegistry.vaultSpec(address(this));

        int24 baseTicks = tickSpacing * tickSpread;
        (, int24 currentTick) = UniswapInteractionHelper.getSqrtRatioX96AndTick(pool);

        TicksData memory ticks = UniswapInteractionHelper.getBaseTicks(
            currentTick,
            baseTicks,
            tickSpacing
        );

        uint256 amount0Available = _balance0();
        uint256 amount1Available = _balance1();

        uint128 liquidity = UniswapInteractionHelper.getLiquidityForAmounts(
            pool,
            amount0Available,
            amount1Available,
            ticks
        );

        (uint256 amount0, uint256 amount1) = UniswapInteractionHelper.getAmountsForLiquidity(
            pool,
            liquidity,
            ticks
        );

        bool zeroForOne = UniswapInteractionHelper.swapDirection(
            amount0Available,
            amount1Available,
            amount0,
            amount1
        );

        int256 amountToSwap = zeroForOne
            ? int256(FullMath.mulDiv(amount0Available - amount0, swapPercentage, DENOMINATOR))
            : int256(FullMath.mulDiv(amount1Available - amount1, swapPercentage, DENOMINATOR));

        UniswapInteractionHelper.swapToken(pool, zeroForOne, amountToSwap, maxPriceImpact);

        amount0Available = _balance0();
        amount1Available = _balance1();

        ticksData = UniswapInteractionHelper.getPositionTicks(
            pool,
            amount0Available,
            amount1Available,
            baseTicks,
            tickSpacing
        );

        UniswapInteractionHelper.mintLiquidity(
            pool,
            ticksData,
            amount0Available,
            amount1Available,
            0,
            0
        );

        emit Rescaled(ticksData.tickLower, ticksData.tickUpper);
    }

    /*
     ** Secondary Interactions
     */
    function getVaultStatus()
        external
        returns (uint256 amount0, uint256 amount1, uint256 fees0, uint256 fees1, uint128 liquidity)
    {
        return UniswapInteractionHelper.getReserves(pool, ticksData);
    }

    /*
     ** Helpers
     */
    function _compound(bool _collect) internal {
        if (_collect) {
            (, , uint256 fees0, uint256 fees1) = UniswapInteractionHelper.burnLiquidity(
                pool,
                ticksData,
                0,
                totalSupply(),
                0, // we are burning no liquidity here
                0
            );

            emit FeeClaimed(fees0, fees1);
            transferProtocolFees(fees0, fees1);
        }

        (uint256 new0, uint256 new1) = UniswapInteractionHelper.mintLiquidity(
            pool,
            ticksData,
            _balance0(),
            _balance1(),
            0,
            0
        );

        emit Compounded(new0, new1);
    }

    function _balance0() internal view returns (uint256) {
        return token0.balanceOf(address(this));
    }

    function _balance1() internal view returns (uint256) {
        return token1.balanceOf(address(this));
    }

    function _transferSend(
        IERC20MetadataUpgradeable token,
        address recipient,
        uint256 amount,
        bool _asEth
    ) internal {
        if (amount > 0) {
            if (_asEth && address(token) == address(weth)) {
                weth.withdraw(amount);
                (bool success, ) = recipient.call{ value: amount }("");
                if (!success) {
                    revert Errors.ExternalTransferFailed();
                }
            } else {
                token.safeTransfer(recipient, amount);
            }
        }
    }

    function _transferReceive(
        IERC20MetadataUpgradeable token,
        address from,
        address recipient,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (address(token) == address(weth) && address(this).balance >= amount) {
                weth.deposit{ value: address(this).balance }();
                if (recipient != address(this)) {
                    weth.safeTransfer(recipient, amount);
                }
            } else {
                token.safeTransferFrom(from, recipient, amount);
            }
        }
    }
}