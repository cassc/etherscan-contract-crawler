// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {BaseVault} from "../BaseVault.sol";
import {AccessStrategy} from "../both/AccessStrategy.sol";
import {ICurvePool, I3CrvMetaPoolZap} from "../interfaces/curve.sol";
import {IConvexBooster, IConvexRewards} from "../interfaces/convex.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract ConvexStrategy is AccessStrategy {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /// @notice Index assigned to `asset` by curve. Used during deposit/withdraw.
    int128 public immutable assetIndex;
    /// @notice The `asset`'s decimals.
    uint8 immutable assetDecimals;

    constructor(
        BaseVault _vault,
        int128 _assetIndex,
        bool _isMetaPool,
        ICurvePool _curvePool,
        I3CrvMetaPoolZap _zapper,
        uint256 _convexPid,
        address[] memory strategists
    ) AccessStrategy(_vault, strategists) {
        assetIndex = _assetIndex;
        assetDecimals = ERC20(_vault.asset()).decimals();
        isMetaPool = _isMetaPool;
        curvePool = _curvePool;
        zapper = _zapper;
        convexPid = _convexPid;
        if (isMetaPool) require(address(zapper) != address(0), "Zapper required");

        IConvexBooster.PoolInfo memory poolInfo = CVX_BOOSTER.poolInfo(convexPid);
        cvxRewarder = IConvexRewards(poolInfo.crvRewards);
        curveLpToken = ERC20(poolInfo.lptoken);

        // Curve Approvals (minting/burning lp tokens)
        if (isMetaPool) {
            asset.safeApprove(address(zapper), type(uint256).max);
            curveLpToken.safeApprove(address(zapper), type(uint256).max);
        } else {
            asset.safeApprove(address(curvePool), type(uint256).max);
        }

        // Convex Approvals
        curveLpToken.safeApprove(address(CVX_BOOSTER), type(uint256).max);

        // For trading CVX and CRV
        CRV.safeApprove(address(ROUTER), type(uint256).max);
        CVX.safeApprove(address(ROUTER), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                                DEPOSITS
    //////////////////////////////////////////////////////////////*/

    /// @notice The curve pool, e.g. FRAX/USDC. Stableswap pool addresses are different from their lp token addresses.
    /// @dev https://curve.readthedocs.io/exchange-deposits.html#curve-stableswap-exchange-deposit-contracts
    ICurvePool public immutable curvePool;
    /// @notice The lp token received upon deposit into the pool.
    ERC20 public immutable curveLpToken;
    /// @notice If true, use the zapper for deposits/withdrawals E.g. for MIM/3CRV this would be true.
    bool immutable isMetaPool;
    /// @notice Allows users to deposit underlying tokens to metapool, e.g. USDC to MIM/3CRV.
    /// @dev See https://curve.readthedocs.io/exchange-deposits.html#metapool-deposits
    I3CrvMetaPoolZap public immutable zapper;

    /// @notice Id of the curve pool (used by convex booster).
    uint256 public immutable convexPid;
    /// @notice Convex booster. Used for depositing curve lp tokens.
    IConvexBooster public constant CVX_BOOSTER = IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    /// @notice Deposit `assets` and receive at least `minLpTokens` of CRV lp tokens.
    function deposit(uint256 assets, uint256 minLpTokens) external onlyRole(STRATEGIST_ROLE) {
        _depositIntoCurve(assets, minLpTokens);
        CVX_BOOSTER.depositAll(convexPid, true);
    }

    /// @dev Deposits into curve using metapool if necessary.
    function _depositIntoCurve(uint256 assets, uint256 minLpTokens) internal {
        // E.g. in a FRAX-USDC stableswap pool, the 0 index is for FRAX and the index 1 is for USDC.
        if (isMetaPool) {
            uint256[4] memory depositAmounts = [uint256(0), 0, 0, 0];
            depositAmounts[uint256(uint128(assetIndex))] = assets;
            zapper.add_liquidity({pool: address(curvePool), depositAmounts: depositAmounts, minMintAmount: minLpTokens});
        } else {
            uint256[2] memory depositAmounts = [uint256(0), 0];
            depositAmounts[uint256(uint128(assetIndex))] = assets;
            curvePool.add_liquidity({depositAmounts: depositAmounts, minMintAmount: minLpTokens});
        }
    }

    /// @dev Divestment. Unstake from convex and convert curve lp tokens into `asset`.
    function _divest(uint256 assets) internal override returns (uint256) {
        _withdraw(assets);

        uint256 amountToSend = Math.min(asset.balanceOf(address(this)), assets);
        asset.safeTransfer(address(vault), amountToSend);
        return amountToSend;
    }

    /*//////////////////////////////////////////////////////////////
                              WITHDRAWALS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The minimum amount of lp tokens to count towards tvl or be liquidated during withdrawals.
     * @dev `calc_withdraw_one_coin` and `remove_liquidity_one_coin` may fail when using amounts smaller than this.
     */
    uint256 constant MIN_LP_AMOUNT = 100;

    /**
     * @notice Withdraw from CRV + convex and try to increase balance of `asset` to `assets`.
     * @dev Useful in the case that we want to do multiple withdrawals ahead of a big divestment from the vault. Doing the
     * withdrawals manually (in chunks) will give us less slippage
     */
    function withdrawAssets(uint256 assets) external onlyRole(STRATEGIST_ROLE) {
        _withdraw(assets);
    }

    /// @dev Try to increase balance of `asset` to `assets`.
    function _withdraw(uint256 assets) internal {
        uint256 currAssets = asset.balanceOf(address(this));
        if (currAssets >= assets) return;

        // price * (num of lp tokens) = dollars
        uint256 currLpBal = curveLpToken.balanceOf(address(this));
        uint256 lpTokenBal = currLpBal + cvxRewarder.balanceOf(address(this));
        uint256 price = curvePool.get_virtual_price(); // 18 decimals
        uint256 dollarsOfLp = lpTokenBal.mulWadDown(price);

        // Get the amount of dollars to remove from vault, and the equivalent amount of lp token.
        // We assume that the  vault `asset` is $1.00 (e.g. we assume that USDC is 1.00). Convert to 18 decimals.
        uint256 dollarsOfAssetsToDivest = Math.min(_giveDecimals(assets - currAssets, assetDecimals, 18), dollarsOfLp);
        uint256 lpTokensToDivest = dollarsOfAssetsToDivest.divWadDown(price);

        // Minimum amount of dollars received is 99% of dollar value of lp shares (trading fees, slippage)
        // Convert back to `asset` decimals.
        uint256 minAssetsReceived = _giveDecimals(dollarsOfAssetsToDivest.mulDivDown(99, 100), 18, assetDecimals);
        // Increase the cap on lp tokens by 1% to account for curve's trading fees
        uint256 maxLpTokensToBurn = Math.min(lpTokenBal, lpTokensToDivest.mulDivDown(101, 100));

        // Withdraw from convex if needed to get correct amount of curve lp tokens
        if (maxLpTokensToBurn > currLpBal) _withdrawFromConvex(maxLpTokensToBurn - currLpBal);

        _withdrawFromCurve(maxLpTokensToBurn, minAssetsReceived);
    }

    /// @dev Withdraw from curve burning at most `maxLpTokensToBurn` and receiving at least `minAssetsReceived` assets.
    function _withdrawFromCurve(uint256 maxLpTokensToBurn, uint256 minAssetsReceived) internal {
        if (maxLpTokensToBurn < MIN_LP_AMOUNT) return;

        if (isMetaPool) {
            zapper.remove_liquidity_one_coin({
                pool: address(curvePool),
                burnAmount: maxLpTokensToBurn,
                index: assetIndex,
                minAmount: minAssetsReceived
            });
        } else {
            curvePool.remove_liquidity_one_coin(curveLpToken.balanceOf(address(this)), assetIndex, minAssetsReceived);
        }
    }

    /// @dev Convert between different decimal representations
    function _giveDecimals(uint256 number, uint256 inDecimals, uint256 outDecimals) internal pure returns (uint256) {
        if (inDecimals > outDecimals) {
            number = number / (10 ** (inDecimals - outDecimals));
        }
        if (inDecimals < outDecimals) {
            number = number * (10 ** (outDecimals - inDecimals));
        }
        return number;
    }

    function withdrawFromConvex(uint256 numLpTokens) external onlyRole(STRATEGIST_ROLE) {
        _withdrawFromConvex(numLpTokens);
    }

    function _withdrawFromConvex(uint256 numLpTokens) internal {
        cvxRewarder.withdrawAndUnwrap({amount: numLpTokens, claim: true});
    }

    /*//////////////////////////////////////////////////////////////
                                REWARDS
    //////////////////////////////////////////////////////////////*/

    /// @notice BaseRewardPool. Used for claiming rewards (cvx and crv).
    IConvexRewards public immutable cvxRewarder;

    /// @notice The UniswapV2 router used for trades.
    ISwapRouter public constant ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    /// @notice The CRV token. Given as a reward for deposits into convex contracts.
    ERC20 public constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    /// @notice The CVX token. Given as a reward for deposits into convex contracts.
    ERC20 public constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    /// @notice All trades are made with WETH as the middle asset, e.g. CRV => WETH => USDC.
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    /// @notice We won't sell any CRV or CVX unless we have 0.01 of them.
    uint256 constant MIN_REWARD_AMOUNT = 0.01e18;

    /// @notice Claim convex rewards.
    function claimRewards() external onlyRole(STRATEGIST_ROLE) {
        _claimRewards();
    }

    function _claimRewards() internal {
        cvxRewarder.getReward();
    }

    /// @notice Sell rewards.
    function sellRewards(uint256 minAssetsFromCrv, uint256 minAssetsFromCvx) external onlyRole(STRATEGIST_ROLE) {
        _sellRewards(minAssetsFromCrv, minAssetsFromCvx);
    }

    function _sellRewards(uint256 minAssetsFromCrv, uint256 minAssetsFromCvx) internal {
        // Sell CRV rewards if we have at least MIN_REWARD_AMOUNT tokens
        uint256 crvBal = CRV.balanceOf(address(this));
        if (crvBal > MIN_REWARD_AMOUNT) {
            ISwapRouter.ExactInputSingleParams memory paramsCrv = ISwapRouter.ExactInputSingleParams({
                tokenIn: address(CRV),
                tokenOut: address(asset),
                fee: 10_000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: crvBal,
                amountOutMinimum: minAssetsFromCrv,
                sqrtPriceLimitX96: 0
            });
            ROUTER.exactInputSingle(paramsCrv);
        }

        // Sell CVX rewards
        uint256 cvxBal = CVX.balanceOf(address(this));
        if (cvxBal > MIN_REWARD_AMOUNT) {
            ISwapRouter.ExactInputSingleParams memory paramsCvx = ISwapRouter.ExactInputSingleParams({
                tokenIn: address(CVX),
                tokenOut: address(asset),
                fee: 10_000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: cvxBal,
                amountOutMinimum: minAssetsFromCvx,
                sqrtPriceLimitX96: 0
            });
            ROUTER.exactInputSingle(paramsCvx);
        }
    }

    /// @notice Claim convex rewards and sell them for `asset`.
    function claimAndSellRewards(uint256 minAssetsFromCrv, uint256 minAssetsFromCvx)
        external
        onlyRole(STRATEGIST_ROLE)
    {
        _claimRewards();
        _sellRewards(minAssetsFromCrv, minAssetsFromCvx);
    }

    /// @notice Amount of CRV to be gained during next claim.
    /// @dev The amount of CVX to be gained can be calculated off chain: https://docs.convexfinance.com/convexfinanceintegration/cvx-minting
    function pendingRewards() external view returns (uint256 pendingCrv) {
        pendingCrv = cvxRewarder.earned(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                                  TVL
    //////////////////////////////////////////////////////////////*/

    function totalLockedValue() external override returns (uint256) {
        uint256 lpTokenBal = curveLpToken.balanceOf(address(this)) + cvxRewarder.balanceOf(address(this));
        uint256 assetsLp;
        if (lpTokenBal < MIN_LP_AMOUNT) return balanceOfAsset();

        if (isMetaPool) {
            assetsLp =
                zapper.calc_withdraw_one_coin({pool: address(curvePool), tokenAmount: lpTokenBal, index: assetIndex});
        } else {
            assetsLp = curvePool.calc_withdraw_one_coin(lpTokenBal, assetIndex);
        }
        return balanceOfAsset() + assetsLp;
    }

    /*//////////////////////////////////////////////////////////////
                                UPGRADES
    //////////////////////////////////////////////////////////////*/
    function sendAllTokens(address newStrategy) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Withdraw from convex
        uint256 stakedBal = cvxRewarder.balanceOf(address(this));
        if (stakedBal > 0) {
            _withdrawFromConvex(stakedBal);
        }

        // Send `asset`, curve lp, cvx, crv tokens to the new address
        _sweepToken(asset, newStrategy);
        _sweepToken(curveLpToken, newStrategy);
        _sweepToken(CRV, newStrategy);
        _sweepToken(CVX, newStrategy);
    }

    function _sweepToken(ERC20 token, address to) internal {
        uint256 bal = token.balanceOf(address(this));
        if (bal == 0) return;
        token.safeTransfer(to, bal);
    }
}