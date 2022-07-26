// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../components/SafeOwnableUpgradeable.sol";
import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IWETH9.sol";
import "../interfaces/INativeUnwrapper.sol";
import "../libraries/LibOrder.sol";

contract Storage is Initializable, SafeOwnableUpgradeable {
    bool private _reserved1;
    mapping(address => bool) public brokers;
    ILiquidityPool internal _pool;
    uint64 public nextOrderId;
    LibOrder.OrderList internal _orders;
    IERC20Upgradeable internal _mlp;
    IWETH internal _weth;
    uint32 public liquidityLockPeriod; // 1e0
    INativeUnwrapper public _nativeUnwrapper;
    mapping(address => bool) public rebalancers;
    bool public isPositionOrderPaused;
    bool public isLiquidityOrderPaused;
    uint32 public marketOrderTimeout;
    uint32 public maxLimitOrderTimeout;
    address public maintainer;
    bytes32[44] _gap;

    modifier whenPositionOrderEnabled() {
        require(!isPositionOrderPaused, "POP"); // Position Order Paused
        _;
    }

    modifier whenLiquidityOrderEnabled() {
        require(!isLiquidityOrderPaused, "LOP"); // Liquidity Order Paused
        _;
    }
}