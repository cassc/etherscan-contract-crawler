pragma solidity ^0.8.10;

import {
    ICurveBasePool,
    IPool2,
    IPool3,
    IPool4,
    IPool5,
    IPoolFactory2,
    IPoolFactory3,
    IPoolFactory4,
    IPoolFactory5,
    ICurveMetaPool
} from "./interfaces/ICurvePool.sol";
import { Initializable } from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import { IBaseRewardPool } from "./interfaces/IBaseRewardPool.sol";
import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { IBooster } from "./interfaces/IBooster.sol";
import { WETH as IWETH } from "solmate/tokens/WETH.sol";
import { MultiPoolStrategy as IMultiPoolStrategy } from "./MultiPoolStrategy.sol";

contract ConvexPoolAdapter is Initializable {
    /// @notice The address of the curve pool.
    address public curvePool;
    /// @notice The address of the MultiPoolStrategy contract.
    address public multiPoolStrategy;
    /// @notice The address of the curve LP token.
    address public curveLpToken;
    /// @notice The address of the convex reward pool.
    IBaseRewardPool public convexRewardPool;
    /// @notice The address of the underlying token.
    address public underlyingToken;
    /// @notice The convex pid.
    uint256 public convexPid;
    /// @notice The index of the underlying token in the curve pool.
    int128 public underlyingTokenPoolIndex;
    /// @notice The reward tokens.
    address[] public rewardTokens;
    /// @notice The number of tokens in the curve pool.
    uint256 public tokensLength;

    /// @notice The zapper contract if pool is a meta pool.
    address public zapper;
    /// @notice The useEth flag. If true, the adapter will wrap/unwrap ETH.
    bool public useEth;
    /// @notice The indexUint flag. If true, the adapter will use uint256(uint128(index)) for calc_withdraw_one_coin.
    bool public indexUint;

    uint256 public storedUnderlyingBalance;
    uint256 public healthFactor;
    //// CONSTANTS
    address public constant CONVEX_BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public constant CURVE_TOKEN = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct RewardData {
        address token;
        uint256 amount;
    }

    error Unauthorized();
    error InvalidHealthFactor();

    modifier onlyMultiPoolStrategy() {
        if (msg.sender != multiPoolStrategy) revert Unauthorized();
        _;
    }
    /// @dev The contract automatically disables initializers when deployed so that nobody can highjack the
    /// implementation contract.

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _curvePool,
        address _multiPoolStrategy,
        uint256 _convexPid,
        uint256 _tokensLength,
        address _zapper,
        bool _useEth,
        bool _indexUint,
        int128 _underlyingTokenPoolIndex
    )
        external
        initializer
    {
        curvePool = _curvePool;
        multiPoolStrategy = _multiPoolStrategy;
        (address _curveLpToken,,, address _convexRewardPool,,) = IBooster(CONVEX_BOOSTER).poolInfo(_convexPid);
        curveLpToken = _curveLpToken;
        convexRewardPool = IBaseRewardPool(_convexRewardPool);
        convexPid = _convexPid;
        underlyingToken = IMultiPoolStrategy(_multiPoolStrategy).asset();

        tokensLength = _tokensLength;
        zapper = _zapper;
        useEth = _useEth;
        indexUint = _indexUint;
        healthFactor = 200; // 2%
        underlyingTokenPoolIndex = _underlyingTokenPoolIndex;
        IERC20(curveLpToken).approve(CONVEX_BOOSTER, type(uint256).max);
        IERC20(underlyingToken).approve(address(curvePool), type(uint256).max);
        if (zapper != address(0)) {
            IERC20(underlyingToken).approve(zapper, type(uint256).max);
            IERC20(curvePool).approve(zapper, type(uint256).max);
        }
        uint256 extraRewardsLength = convexRewardPool.extraRewardsLength();
        if (extraRewardsLength > 0) {
            for (uint256 i; i < extraRewardsLength; i++) {
                rewardTokens.push(IBaseRewardPool(convexRewardPool.extraRewards(i)).rewardToken());
            }
        }
    }

    function _addCurvePoolLiquidity(uint256 _amount, uint256 _minCurveLpAmount) internal {
        uint256[5] memory amounts;
        amounts[uint256(uint128(underlyingTokenPoolIndex))] = _amount;
        if (zapper != address(0)) {
            if (tokensLength == 2) {
                IPoolFactory2(zapper).add_liquidity{ value: address(this).balance }(
                    curvePool, [amounts[0], amounts[1]], _minCurveLpAmount
                );
            } else if (tokensLength == 3) {
                IPoolFactory3(zapper).add_liquidity{ value: address(this).balance }(
                    curvePool, [amounts[0], amounts[1], amounts[2]], _minCurveLpAmount
                );
            } else if (tokensLength == 4) {
                IPoolFactory4(zapper).add_liquidity{ value: address(this).balance }(
                    curvePool, [amounts[0], amounts[1], amounts[2], amounts[3]], _minCurveLpAmount
                );
            } else if (tokensLength == 5) {
                IPoolFactory5(zapper).add_liquidity{ value: address(this).balance }(
                    curvePool, [amounts[0], amounts[1], amounts[2], amounts[3], amounts[4]], _minCurveLpAmount
                );
            }
            return;
        }
        if (tokensLength == 2) {
            IPool2(curvePool).add_liquidity{ value: address(this).balance }([amounts[0], amounts[1]], _minCurveLpAmount);
        } else if (tokensLength == 3) {
            IPool3(curvePool).add_liquidity{ value: address(this).balance }(
                [amounts[0], amounts[1], amounts[2]], _minCurveLpAmount
            );
        } else if (tokensLength == 4) {
            IPool4(curvePool).add_liquidity{ value: address(this).balance }(
                [amounts[0], amounts[1], amounts[2], amounts[3]], _minCurveLpAmount
            );
        } else if (tokensLength == 5) {
            IPool5(curvePool).add_liquidity{ value: address(this).balance }(
                [amounts[0], amounts[1], amounts[2], amounts[3], amounts[4]], _minCurveLpAmount
            );
        }
    }

    function _removeCurvePoolLiquidity(uint256 _amount, uint256 _minReceiveAmount) internal {
        if (zapper != address(0)) {
            ICurveMetaPool(zapper).remove_liquidity_one_coin(
                curveLpToken, _amount, underlyingTokenPoolIndex, _minReceiveAmount
            );
        } else {
            ICurveBasePool(curvePool).remove_liquidity_one_coin(_amount, underlyingTokenPoolIndex, _minReceiveAmount);
        }
    }

    function deposit(uint256 _amount, uint256 _minCurveLpAmount) external onlyMultiPoolStrategy {
        if (useEth) {
            IWETH(payable(WETH)).withdraw(_amount);
        }
        _addCurvePoolLiquidity(_amount, _minCurveLpAmount);
        uint256 curveLpBalance = IERC20(curveLpToken).balanceOf(address(this));
        IBooster(CONVEX_BOOSTER).deposit(convexPid, curveLpBalance, true);
        storedUnderlyingBalance = underlyingBalance();
    }

    function withdraw(uint256 _amount, uint256 _minReceiveAmount) external onlyMultiPoolStrategy {
        uint256 _underlyingBalance = underlyingBalance(); // underlying token balance that this adapter holds
        convexRewardPool.withdrawAndUnwrap(_amount, false);
        _removeCurvePoolLiquidity(_amount, _minReceiveAmount);
        if (useEth) {
            IWETH(payable(WETH)).deposit{ value: address(this).balance }();
        }
        uint256 underlyingBal = IERC20(underlyingToken).balanceOf(address(this)); // what we withdrawn from curve
        IERC20(underlyingToken).transfer(multiPoolStrategy, underlyingBal);
        uint256 healthyBalance = storedUnderlyingBalance - (storedUnderlyingBalance * healthFactor / 10_000); // acceptable  underlying
            // token amount that this adapter holds
        if (_underlyingBalance >= healthyBalance) {
            storedUnderlyingBalance = _underlyingBalance - underlyingBal;
        } else {
            storedUnderlyingBalance -= underlyingBal; // only update with amount that goes out from this adapter
        }
    }

    function claim() external onlyMultiPoolStrategy {
        convexRewardPool.getReward(address(this), true);
        uint256 crvBal = IERC20(CURVE_TOKEN).balanceOf(address(this));
        if (crvBal > 0) {
            IERC20(CURVE_TOKEN).transfer(multiPoolStrategy, crvBal);
        }
        uint256 rewardTokensLength = rewardTokens.length;
        for (uint256 i; i < rewardTokensLength; i++) {
            uint256 rewardTokenBal = IERC20(rewardTokens[i]).balanceOf(address(this));
            if (rewardTokenBal > 0) {
                IERC20(rewardTokens[i]).transfer(multiPoolStrategy, rewardTokenBal);
            }
        }
    }

    function underlyingBalance() public view returns (uint256 underlyingBal) {
        uint256 lpBal = convexRewardPool.balanceOf(address(this));
        if (lpBal == 0) return 0;
        if (zapper != address(0)) {
            underlyingBal = ICurveMetaPool(zapper).calc_withdraw_one_coin(curveLpToken, lpBal, underlyingTokenPoolIndex);
        } else {
            if (indexUint) {
                underlyingBal =
                    ICurveBasePool(curvePool).calc_withdraw_one_coin(lpBal, uint256(uint128(underlyingTokenPoolIndex)));
            } else {
                underlyingBal = ICurveBasePool(curvePool).calc_withdraw_one_coin(lpBal, underlyingTokenPoolIndex);
            }
        }
    }

    function lpBalance() external view returns (uint256 lpBal) {
        lpBal = convexRewardPool.balanceOf(address(this));
    }

    function isHealthy() external view returns (bool) {
        uint256 underlyingBal = underlyingBalance();
        uint256 healthThreshold = storedUnderlyingBalance - (storedUnderlyingBalance * healthFactor / 10_000);
        return underlyingBal >= healthThreshold;
    }

    function totalClaimable() external view returns (RewardData[] memory) {
        uint256 rewardTokensLength = rewardTokens.length;
        RewardData[] memory rewards = new RewardData[](rewardTokensLength + 1);
        rewards[0] = RewardData({ token: CURVE_TOKEN, amount: convexRewardPool.earned(address(this)) });
        if (rewardTokensLength > 0) {
            for (uint256 i; i < rewardTokensLength; i++) {
                rewards[i + 1] = RewardData({
                    token: rewardTokens[i],
                    amount: IBaseRewardPool(convexRewardPool.extraRewards(i)).earned(address(this))
                });
            }
        }
        return rewards;
    }

    function setHealthFactor(uint256 _newHealthFactor) external onlyMultiPoolStrategy {
        if (_newHealthFactor > 10_000) {
            revert InvalidHealthFactor();
        }
        healthFactor = _newHealthFactor;
    }

    receive() external payable { }
}