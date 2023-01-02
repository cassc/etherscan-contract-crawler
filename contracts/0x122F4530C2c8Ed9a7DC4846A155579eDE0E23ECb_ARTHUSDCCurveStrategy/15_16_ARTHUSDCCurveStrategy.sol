// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VersionedInitializable} from "../../proxy/VersionedInitializable.sol";

import {StakingRewardsChild} from "../../staking/StakingRewardsChild.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {IStableSwap} from "../../interfaces/IStableSwap.sol";
import {IPriceFeed} from "../../interfaces/IPriceFeed.sol";

import {ARTHUSDCCurveLogic} from "./ARTHUSDCCurveLogic.sol";

contract ARTHUSDCCurveStrategy is VersionedInitializable, StakingRewardsChild {
    event Deposit(address indexed src, uint256 wad);
    event Withdrawal(address indexed dst, uint256 wad);

    address private _me;

    mapping(address => ARTHUSDCCurveLogic.Position) public positions;

    IERC20 public arth;
    IERC20 public lp;
    IERC20 public varDebtArth;
    IERC20 public usdc;
    ILendingPool public lendingPool;
    IStableSwap public liquidityPool;
    IPriceFeed priceFeed;

    /// @notice all revenue gets sent over here.
    address public treasury;

    uint64 public minLockDuration;
    uint64 public minLockDurationForPermit;

    uint256 public minDepositForPermit;
    uint256 public totalUsdcSupplied;
    uint256 public totalArthBorrowed;

    function initialize(
        address _usdc,
        address _arth,
        address _maha,
        address _lp,
        address _varDebtArth,
        address _lendingPool,
        address _liquidityPool,
        uint256 _rewardsDuration,
        address _priceFeed,
        address _treasury,
        address _owner
    ) external initializer {
        arth = IERC20(_arth);
        usdc = IERC20(_usdc);
        lp = IERC20(_lp);
        varDebtArth = IERC20(_varDebtArth);
        lendingPool = ILendingPool(_lendingPool);
        liquidityPool = IStableSwap(_liquidityPool);
        priceFeed = IPriceFeed(_priceFeed);

        treasury = _treasury;
        _me = address(this);

        usdc.approve(_lendingPool, type(uint256).max);
        arth.approve(_lendingPool, type(uint256).max);
        usdc.approve(_liquidityPool, type(uint256).max);
        arth.approve(_liquidityPool, type(uint256).max);

        _stakingRewardsChildInit(_maha, _rewardsDuration, _owner);
        _transferOwnership(_owner);

        minLockDuration = 86400 * 5; // 5 day lock
        minLockDurationForPermit = 86400 * 30; // 30 day lock

        // allow the strategy to borrow upto 97% LTV
        lendingPool.setUserEMode(1);
    }

    function seedLP(uint256 usdcToLiquidityPool) external {
        usdc.transferFrom(msg.sender, _me, usdcToLiquidityPool);
        uint256[2] memory inAmounts = [0, usdcToLiquidityPool];
        liquidityPool.add_liquidity(inAmounts, 0);
    }

    function deposit(uint256 usdcSupplied, uint256 minLiquidityReceived) external {
        _deposit(msg.sender, usdcSupplied, minLiquidityReceived, minLockDuration);
    }

    function depositWithPermit(
        address who,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 usdcSupplied,
        uint256 minLiquidityReceived
    ) external {
        require(value >= minDepositForPermit, "!minDepositForPermit");
        IERC20Permit(address(usdc)).permit(who, _me, value, deadline, v, r, s);
        _deposit(who, usdcSupplied, minLiquidityReceived, minLockDurationForPermit);
    }

    function _deposit(
        address who,
        uint256 usdcSupplied,
        uint256 minLiquidityReceived,
        uint64 lockDuration
    ) internal nonReentrant {
        usdc.transferFrom(who, _me, usdcSupplied);

        uint256 _totalArthBorrowed = ARTHUSDCCurveLogic.deposit(
            positions,
            who,
            usdcSupplied,
            minLiquidityReceived,
            lockDuration,
            ARTHUSDCCurveLogic.DepositParams({
                me: _me, // address me;
                usdc: usdc, // IERC20 usdc;
                arth: arth, // IERC20 arth;
                lendingPool: lendingPool, // ILendingPool lendingPool;
                stableswap: liquidityPool, // IStableSwap stableswap;
                priceFeed: priceFeed
            })
        );

        totalArthBorrowed += _totalArthBorrowed;
        totalUsdcSupplied += usdcSupplied;

        // Record the staking in the staking contract for maha rewards
        _stake(who, usdcSupplied);
    }

    function withdraw() external payable {
        _withdraw(msg.sender);
    }

    function _withdraw(address who) internal nonReentrant {
        // Record the staking in the staking contract for maha rewards
        _withdraw(who, positions[who].usdcSupplied);

        uint256 _usdcSupplied = positions[who].totalUsdc;
        uint256 _totalArthBorrowed = positions[who].arthBorrowed;

        ARTHUSDCCurveLogic.withdraw(
            positions,
            who,
            ARTHUSDCCurveLogic.WithdrawParams({
                me: _me, // address me;
                treasury: treasury, // address treasury;
                usdc: usdc, // IERC20 usdc;
                arth: arth, // IERC20 arth;
                lp: lp,
                totalArthBorrowed: totalArthBorrowed,
                totalUsdcSupplied: totalUsdcSupplied,
                varDebtArth: varDebtArth,
                lendingPool: lendingPool, // ILendingPool lendingPool;
                stableswap: liquidityPool // IStableSwap stableswap;
            })
        );

        totalArthBorrowed -= _totalArthBorrowed;
        totalUsdcSupplied -= _usdcSupplied;
    }

    function _flush(address to) internal {
        uint256 arthBalance = arth.balanceOf(_me);
        if (arthBalance > 0) assert(arth.transfer(to, arthBalance));

        uint256 usdcBalance = usdc.balanceOf(_me);
        if (usdcBalance > 0) assert(usdc.transfer(to, usdcBalance));
    }

    /// @dev in case admin needs to execute some calls directly
    function emergencyCall(address target, bytes memory signature) external payable onlyOwner {
        (bool success, bytes memory response) = target.call{value: msg.value}(signature);
        require(success, string(response));
    }

    function getRevision() public pure virtual override returns (uint256) {
        return 0;
    }
}