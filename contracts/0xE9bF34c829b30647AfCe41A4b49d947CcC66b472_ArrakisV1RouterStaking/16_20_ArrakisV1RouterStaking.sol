// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import {
    IGauge,
    IArrakisV1RouterStaking
} from "./interfaces/IArrakisV1RouterStaking.sol";
import {IArrakisVaultV1} from "./interfaces/IArrakisVaultV1.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ArrakisV1RouterStaking is
    IArrakisV1RouterStaking,
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using Address for address payable;
    using SafeERC20 for IERC20;

    IWETH public immutable weth;

    constructor(IWETH _weth) {
        weth = _weth;
    }

    function initialize() external initializer {
        __Pausable_init();
        __Ownable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice addLiquidity adds liquidity to ArrakisVaultV1 pool of interest (mints LP tokens)
    /// @param pool address of ArrakisVaultV1 pool to add liquidity to
    /// @param amount0Max the maximum amount of token0 msg.sender willing to input
    /// @param amount1Max the maximum amount of token1 msg.sender willing to input
    /// @param amount0Min the minimum amount of token0 actually input (slippage protection)
    /// @param amount1Min the minimum amount of token1 actually input (slippage protection)
    /// @param receiver account to receive minted ArrakisVaultV1 tokens
    /// @return amount0 amount of token0 transferred from msg.sender to mint `mintAmount`
    /// @return amount1 amount of token1 transferred from msg.sender to mint `mintAmount`
    /// @return mintAmount amount of ArrakisVaultV1 tokens minted and transferred to `receiver`
    function addLiquidity(
        IArrakisVaultV1 pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 amountSharesMin,
        address receiver
    )
        external
        override
        whenNotPaused
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        return
            _addLiquidity(
                pool,
                amount0Max,
                amount1Max,
                amount0Min,
                amount1Min,
                amountSharesMin,
                receiver
            );
    }

    /// @notice addLiquidityAndStake same as addLiquidity except Arrakis LP token
    /// is immediately staked in corresponding LiquidityGauge. New param:
    /// @param gauge the address of the LiquidityGauge corresponding to the ArrakisVaultV1
    function addLiquidityAndStake(
        IGauge gauge,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 amountSharesMin,
        address receiver
    )
        external
        override
        whenNotPaused
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        address pool = gauge.staking_token();
        (amount0, amount1, mintAmount) = _addLiquidity(
            IArrakisVaultV1(pool),
            amount0Max,
            amount1Max,
            amount0Min,
            amount1Min,
            amountSharesMin,
            address(this)
        );

        IERC20(pool).safeIncreaseAllowance(address(gauge), mintAmount);
        gauge.deposit(mintAmount, receiver);
    }

    /// @notice addLiquidityETH same as addLiquidity but expects ETH transfers (instead of WETH)
    function addLiquidityETH(
        IArrakisVaultV1 pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 amountSharesMin,
        address receiver
    )
        external
        payable
        override
        whenNotPaused
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        return
            _addLiquidityETH(
                pool,
                amount0Max,
                amount1Max,
                amount0Min,
                amount1Min,
                amountSharesMin,
                receiver
            );
    }

    /// @notice addLiquidityETHAndStake same as addLiquidityETH except Arrakis LP token
    /// is immediately staked in corresponding LiquidityGauge. New param:
    /// @param gauge the address of the LiquidityGauge corresponding to the ArrakisVaultV1
    function addLiquidityETHAndStake(
        IGauge gauge,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 amountSharesMin,
        address receiver
    )
        external
        payable
        override
        whenNotPaused
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        address pool = gauge.staking_token();
        (amount0, amount1, mintAmount) = _addLiquidityETH(
            IArrakisVaultV1(pool),
            amount0Max,
            amount1Max,
            amount0Min,
            amount1Min,
            amountSharesMin,
            address(this)
        );

        IERC20(pool).safeIncreaseAllowance(address(gauge), mintAmount);
        gauge.deposit(mintAmount, receiver);
    }

    /// @notice removeLiquidity removes liquidity from a ArrakisVaultV1 pool and burns LP tokens
    /// @param burnAmount The number of ArrakisVaultV1 tokens to burn
    /// @param amount0Min Minimum amount of token0 received after burn (slippage protection)
    /// @param amount1Min Minimum amount of token1 received after burn (slippage protection)
    /// @param receiver The account to receive the underlying amounts of token0 and token1
    /// @return amount0 actual amount of token0 transferred to receiver for burning `burnAmount`
    /// @return amount1 actual amount of token1 transferred to receiver for burning `burnAmount`
    /// @return liquidityBurned amount of liquidity removed from the underlying Uniswap V3 position
    function removeLiquidity(
        IArrakisVaultV1 pool,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        override
        whenNotPaused
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        )
    {
        IERC20(address(pool)).safeTransferFrom(
            msg.sender,
            address(this),
            burnAmount
        );
        (amount0, amount1, liquidityBurned) = pool.burn(burnAmount, receiver);
        require(
            amount0 >= amount0Min && amount1 >= amount1Min,
            "received below minimum"
        );
    }

    /// @notice removeLiquidityAndUnstake same as removeLiquidity except Arrakis LP token
    /// is first unstaked from liquidity gauge, and all rewards for msg.sender collected. New param:
    /// @param gauge the address of the LiquidityGauge corresponding to the ArrakisVaultV1
    function removeLiquidityAndUnstake(
        IGauge gauge,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        override
        whenNotPaused
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        )
    {
        gauge.claim_rewards(msg.sender);
        IERC20(address(gauge)).safeTransferFrom(
            msg.sender,
            address(this),
            burnAmount
        );
        gauge.withdraw(burnAmount);
        address pool = gauge.staking_token();
        (amount0, amount1, liquidityBurned) = IArrakisVaultV1(pool).burn(
            burnAmount,
            receiver
        );
        require(
            amount0 >= amount0Min && amount1 >= amount1Min,
            "received below minimum"
        );
    }

    /// @notice removeLiquidityETH same as removeLiquidity
    /// except this function unwraps WETH and sends ETH to receiver account
    // solhint-disable-next-line code-complexity, function-max-lines
    function removeLiquidityETH(
        IArrakisVaultV1 pool,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address payable receiver
    )
        external
        override
        whenNotPaused
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        )
    {
        IERC20 token0 = pool.token0();
        IERC20 token1 = pool.token1();

        bool wethToken0 = _isToken0Weth(address(token0), address(token1));

        IERC20(address(pool)).safeTransferFrom(
            msg.sender,
            address(this),
            burnAmount
        );
        (amount0, amount1, liquidityBurned) = pool.burn(
            burnAmount,
            address(this)
        );
        require(
            amount0 >= amount0Min && amount1 >= amount1Min,
            "received below minimum"
        );

        if (wethToken0) {
            if (amount0 > 0) {
                weth.withdraw(amount0);
                receiver.sendValue(amount0);
            }
            if (amount1 > 0) {
                token1.safeTransfer(receiver, amount1);
            }
        } else {
            if (amount1 > 0) {
                weth.withdraw(amount1);
                receiver.sendValue(amount1);
            }
            if (amount0 > 0) {
                token0.safeTransfer(receiver, amount0);
            }
        }
    }

    /// @notice removeLiquidityAndUnstake same as removeLiquidity except Arrakis LP token
    /// is first unstaked from liquidity gauge, and all rewards for msg.sender collected. New param:
    /// @param gauge the address of the LiquidityGauge corresponding to the ArrakisVaultV1
    // solhint-disable-next-line code-complexity, function-max-lines
    function removeLiquidityETHAndUnstake(
        IGauge gauge,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address payable receiver
    )
        external
        override
        whenNotPaused
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        )
    {
        gauge.claim_rewards(msg.sender);
        IERC20(address(gauge)).safeTransferFrom(
            msg.sender,
            address(this),
            burnAmount
        );
        gauge.withdraw(burnAmount);
        address pool = gauge.staking_token();
        (amount0, amount1, liquidityBurned) = IArrakisVaultV1(pool).burn(
            burnAmount,
            address(this)
        );
        require(
            amount0 >= amount0Min && amount1 >= amount1Min,
            "received below minimum"
        );

        IERC20 token0 = IArrakisVaultV1(pool).token0();
        IERC20 token1 = IArrakisVaultV1(pool).token1();

        bool wethToken0 = _isToken0Weth(address(token0), address(token1));

        if (wethToken0) {
            if (amount0 > 0) {
                weth.withdraw(amount0);
                receiver.sendValue(amount0);
            }
            if (amount1 > 0) {
                token1.safeTransfer(receiver, amount1);
            }
        } else {
            if (amount1 > 0) {
                weth.withdraw(amount1);
                receiver.sendValue(amount1);
            }
            if (amount0 > 0) {
                token0.safeTransfer(receiver, amount0);
            }
        }
    }

    function _addLiquidity(
        IArrakisVaultV1 pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 amountSharesMin,
        address receiver
    )
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        IERC20 token0 = pool.token0();
        IERC20 token1 = pool.token1();

        (uint256 amount0In, uint256 amount1In, uint256 _mintAmount) =
            pool.getMintAmounts(amount0Max, amount1Max);
        require(
            amount0In >= amount0Min &&
                amount1In >= amount1Min &&
                _mintAmount >= amountSharesMin,
            "below min amounts"
        );

        if (amount0In > 0) {
            token0.safeTransferFrom(msg.sender, address(this), amount0In);
        }
        if (amount1In > 0) {
            token1.safeTransferFrom(msg.sender, address(this), amount1In);
        }

        return _deposit(pool, amount0In, amount1In, _mintAmount, receiver);
    }

    // solhint-disable-next-line code-complexity, function-max-lines
    function _addLiquidityETH(
        IArrakisVaultV1 pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 amountSharesMin,
        address receiver
    )
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        IERC20 token0 = pool.token0();
        IERC20 token1 = pool.token1();

        (uint256 amount0In, uint256 amount1In, uint256 _mintAmount) =
            pool.getMintAmounts(amount0Max, amount1Max);
        require(
            amount0In >= amount0Min &&
                amount1In >= amount1Min &&
                _mintAmount >= amountSharesMin,
            "below min amounts"
        );

        if (_isToken0Weth(address(token0), address(token1))) {
            require(
                amount0Max == msg.value,
                "mismatching amount of ETH forwarded"
            );
            if (amount0In > 0) {
                weth.deposit{value: amount0In}();
            }
            if (amount1In > 0) {
                token1.safeTransferFrom(msg.sender, address(this), amount1In);
            }
        } else {
            require(
                amount1Max == msg.value,
                "mismatching amount of ETH forwarded"
            );
            if (amount1In > 0) {
                weth.deposit{value: amount1In}();
            }
            if (amount0In > 0) {
                token0.safeTransferFrom(msg.sender, address(this), amount0In);
            }
        }

        (amount0, amount1, mintAmount) = _deposit(
            pool,
            amount0In,
            amount1In,
            _mintAmount,
            receiver
        );

        if (_isToken0Weth(address(token0), address(token1))) {
            if (amount0Max > amount0) {
                payable(msg.sender).sendValue(amount0Max - amount0);
            }
        } else {
            if (amount1Max > amount1) {
                payable(msg.sender).sendValue(amount1Max - amount1);
            }
        }
    }

    function _deposit(
        IArrakisVaultV1 pool,
        uint256 amount0In,
        uint256 amount1In,
        uint256 _mintAmount,
        address receiver
    )
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        )
    {
        if (amount0In > 0) {
            pool.token0().safeIncreaseAllowance(address(pool), amount0In);
        }
        if (amount1In > 0) {
            pool.token1().safeIncreaseAllowance(address(pool), amount1In);
        }

        (amount0, amount1, ) = pool.mint(_mintAmount, receiver);
        require(
            amount0 == amount0In && amount1 == amount1In,
            "unexpected amounts deposited"
        );
        mintAmount = _mintAmount;
    }

    function _isToken0Weth(address token0, address token1)
        internal
        view
        returns (bool wethToken0)
    {
        if (token0 == address(weth)) {
            wethToken0 = true;
        } else if (token1 == address(weth)) {
            wethToken0 = false;
        } else {
            revert("one pool token must be WETH");
        }
    }
}