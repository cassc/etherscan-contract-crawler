// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../interfaces/ILiquidity.sol";
import "../LiquidityManager.sol";

/**
 * @title Test Contract Wrapper for LiquidityManager
 * @author MetaStreet Labs
 */
contract TestLiquidityManager is ILiquidity {
    using LiquidityManager for LiquidityManager.Liquidity;

    /**************************************************************************/
    /* Events */
    /**************************************************************************/

    /**
     * @notice Emitted with return value from deposit()
     * @param shares Shares created
     */
    event Deposited(uint128 shares);

    /**
     * @notice Emitted with return values from redeem()
     * @param index Redemption index
     * @param target Redemption target
     */
    event RedemptionTarget(uint128 index, uint128 target);

    /**************************************************************************/
    /* State */
    /**************************************************************************/

    /**
     * @notice Liquidity
     */
    LiquidityManager.Liquidity internal _liquidity;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    constructor() {
        _liquidity.initialize();
    }

    /**************************************************************************/
    /* ILiquidity Getters */
    /**************************************************************************/

    /**
     * @inheritdoc ILiquidity
     */
    function liquidityNodes(uint128 startTick, uint128 endTick) external view returns (ILiquidity.NodeInfo[] memory) {
        return _liquidity.liquidityNodes(startTick, endTick);
    }

    /**
     * @inheritdoc ILiquidity
     */
    function liquidityNode(uint128 tick) external view returns (ILiquidity.NodeInfo memory) {
        return _liquidity.liquidityNode(tick);
    }

    /**************************************************************************/
    /* Wrapper for Primary API */
    /**************************************************************************/

    /**
     * @dev External wrapper function for LiquidityManager.redemptionAvailable()
     */
    function redemptionAvailable(
        uint128 tick,
        uint128 pending,
        uint128 index,
        uint128 target
    ) external view returns (uint128, uint128) {
        return _liquidity.redemptionAvailable(tick, pending, index, target);
    }

    /**
     * @dev External wrapper function for LiquidityManager._instantiate()
     */
    function instantiate(uint128 tick) external {
        return _liquidity._instantiate(_liquidity.nodes[tick], tick);
    }

    /**
     * @dev External wrapper function for LiquidityManager.deposit()
     */
    function deposit(uint128 tick, uint128 amount) external returns (uint256) {
        uint128 shares = _liquidity.deposit(tick, amount);
        emit Deposited(shares);
        return shares;
    }

    /**
     * @dev External wrapper function for LiquidityManager.use()
     */
    function use(uint128 tick, uint128 amount, uint128 pending) external {
        _liquidity.use(tick, amount, pending);
    }

    /**
     * @dev External wrapper function for LiquidityManager.restore()
     */
    function restore(uint128 tick, uint128 used, uint128 pending, uint128 restored) external {
        _liquidity.restore(tick, used, pending, restored);
    }

    /**
     * @dev External wrapper function for LiquidityManager.redeem()
     */
    function redeem(uint128 tick, uint128 shares) external returns (uint128, uint128) {
        (uint128 index, uint128 target) = _liquidity.redeem(tick, shares);
        emit RedemptionTarget(index, target);
        return (index, target);
    }

    /**
     * @dev External wrapper function for LiquidityManager.source()
     */
    function source(
        uint256 amount,
        uint128[] calldata ticks,
        uint256 multiplier,
        uint256 durationIndex
    ) external view returns (ILiquidity.NodeSource[] memory, uint16 count) {
        return _liquidity.source(amount, ticks, multiplier, durationIndex);
    }
}