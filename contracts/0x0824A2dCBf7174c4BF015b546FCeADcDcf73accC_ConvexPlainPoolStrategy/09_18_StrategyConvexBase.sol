// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {BaseStrategy} from "./BaseStrategy.sol";
import {IConvexRewards} from "../../interfaces/convex/IConvexRewards.sol";
import {IConvexDeposit} from "../../interfaces/convex/IConvexDeposit.sol";
import {ICurveFi} from "../../interfaces/curve-finance/ICurveFi.sol";
import {IOracle} from "../../interfaces/oracle/IOracle.sol";
import {IUniswapV2Router02} from "../../interfaces/uniswap/IUniswapV2Router02.sol";

abstract contract StrategyConvexBase is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // convex stuff
    address internal constant _DEPOSIT_CONTRACT = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31; // this is the deposit contract that all pools use, aka booster
    IConvexRewards public rewardsContract; // This is unique to each curve pool
    address public virtualRewardsPool; // This is only if we have bonus rewards
    uint256 public pid; // this is unique to each pool

    // curve stuff
    ICurveFi public curve; // Curve Pool, this is our pool specific to this vault
    // use Curve to sell our CVX and CRV rewards to WETH
    ICurveFi internal constant _CRV_ETH = ICurveFi(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511);
    ICurveFi internal constant _CVX_ETH = ICurveFi(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);

    // Swap stuff
    address internal constant _SUSHI_SWAP = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // we use this to sell our bonus token

    IERC20 internal constant _CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 internal constant _CONVEX_TOKEN = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 internal constant _WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 internal constant _USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    // keeper stuff
    uint256 public harvestProfitMin; // minimum size in USD (6 decimals) that we want to harvest
    uint256 public harvestProfitMax; // maximum size in USD (6 decimals) that we want to harvest
    uint256 public creditThreshold; // amount of credit in underlying tokens that will automatically trigger a harvest

    string internal _stratName;

    // convex-specific variables
    bool public hasRewards;
    bool public claimRewards;
    IERC20 public rewardsToken;
    address[] internal _rewardsPath;

    constructor(
        address _vault,
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) BaseStrategy(_vault) {
        _initializeStrat(_pid, _curvePool, _name);
    }

    function _initializeBase(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) internal {
        _initialize(_vault, _strategist, _rewards, _keeper);
        _initializeStrat(_pid, _curvePool, _name);
    }

    function _initializeStrat(
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) internal {
        // make sure that we haven't initialized this before
        require(address(curve) == address(0));

        // want = Curve LP
        want.approve(address(_DEPOSIT_CONTRACT), type(uint256).max);
        _CONVEX_TOKEN.approve(address(_CVX_ETH), type(uint256).max);
        _CRV.approve(address(_CRV_ETH), type(uint256).max);

        // this is the pool specific to this vault, but we only use it as an address
        curve = ICurveFi(_curvePool);

        // setup our rewards contract
        pid = _pid;
        // this is the pool ID on convex, we use this to determine what the rewardsContract address is
        (address lptoken, , , address _rewardsContract, , ) = IConvexDeposit(_DEPOSIT_CONTRACT).poolInfo(_pid);

        // set up our rewardsContract
        rewardsContract = IConvexRewards(_rewardsContract);

        // check that our LP token based on our pid matches our want
        require(address(lptoken) == address(want), "Wrong PID number");

        // set our strategy's name
        _stratName = _name;
    }

    function name() external view override returns (string memory) {
        return _stratName;
    }

    /// @notice How much want we have staked in Convex
    function stakedBalance() public view returns (uint256) {
        return rewardsContract.balanceOf(address(this));
    }

    /// @notice Balance of want sitting in our strategy
    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    /// @notice How much CRV we can claim from the staking contract
    function claimableBalance() public view returns (uint256) {
        return rewardsContract.earned(address(this));
    }

    /// @notice The value in dollars that our claimable rewards are worth (in USDT, 6 decimals).
    function claimableProfitInUsdt() public view returns (uint256) {
        // calculations pulled directly from CVX's contract for minting CVX per CRV claimed
        uint256 totalCliffs = 1_000;
        uint256 maxSupply = 100 * 1_000_000 * 1e18;
        // 100mil
        uint256 reductionPerCliff = 100_000 * 1e18;
        // 100,000
        uint256 supply = _CONVEX_TOKEN.totalSupply();
        uint256 mintableCvx;

        uint256 cliff = supply.div(reductionPerCliff);
        uint256 _claimableBal = claimableBalance();
        //mint if below total cliffs
        if (cliff < totalCliffs) {
            //for reduction% take inverse of current cliff
            uint256 reduction = totalCliffs.sub(cliff);
            //reduce
            mintableCvx = _claimableBal.mul(reduction).div(totalCliffs);

            //supply cap check
            uint256 amtTillMax = maxSupply.sub(supply);
            if (mintableCvx > amtTillMax) {
                mintableCvx = amtTillMax;
            }
        }

        // our chainlink oracle returns prices normalized to 8 decimals, we convert it to 6
        IOracle ethOracle = IOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        uint256 ethPrice = ethOracle.latestAnswer().div(1e2);
        // 1e8 div 1e2 = 1e6
        uint256 crvPrice = _CRV_ETH.price_oracle().mul(ethPrice).div(1e18);
        // 1e18 mul 1e6 div 1e18 = 1e6
        uint256 cvxPrice = _CVX_ETH.price_oracle().mul(ethPrice).div(1e18);
        // 1e18 mul 1e6 div 1e18 = 1e6

        uint256 crvValue = crvPrice.mul(_claimableBal).div(1e18);
        // 1e6 mul 1e18 div 1e18 = 1e6
        uint256 cvxValue = cvxPrice.mul(mintableCvx).div(1e18);
        // 1e6 mul 1e18 div 1e18 = 1e6

        // get the value of our rewards token if we have one
        uint256 rewardsValue;
        if (hasRewards) {
            address[] memory usdPath = new address[](3);
            usdPath[0] = address(rewardsToken);
            usdPath[1] = address(_WETH);
            usdPath[2] = address(_USDT);

            uint256 _claimableBonusBal = IConvexRewards(virtualRewardsPool).earned(address(this));
            if (_claimableBonusBal > 0) {
                uint256[] memory rewardSwap = IUniswapV2Router02(_SUSHI_SWAP).getAmountsOut(
                    _claimableBonusBal,
                    usdPath
                );
                rewardsValue = rewardSwap[rewardSwap.length - 1];
            }
        }

        return crvValue.add(cvxValue).add(rewardsValue);
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        return balanceOfWant().add(stakedBalance());
    }

    function _prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        // this claims our CRV, CVX, and any extra tokens like SNX or ANKR. no harm leaving this true even if no extra rewards currently.
        rewardsContract.getReward(address(this), true);

        // claim and sell our rewards if we have them
        if (hasRewards) {
            uint256 _rewardsBalance = IERC20(rewardsToken).balanceOf(address(this));
            if (_rewardsBalance > 0) {
                _sellRewards(_rewardsBalance);
            }
        }

        uint256 crvBalance = _CRV.balanceOf(address(this));
        uint256 convexBalance = _CONVEX_TOKEN.balanceOf(address(this));

        // do this even if we have zero balances so we can sell WETH from rewards
        _sellCrvAndCvx(crvBalance, convexBalance);

        // Add liquidity into the underlying Curve LP
        _addLiquidityToCurve();

        // debtOustanding will only be > 0 in the event of revoking or if we need to rebalance from a withdrawal or lowering the debtRatio
        if (_debtOutstanding > 0) {
            uint256 _stakedBal = stakedBalance();
            if (_stakedBal > 0) {
                rewardsContract.withdrawAndUnwrap(Math.min(_stakedBal, _debtOutstanding), claimRewards);
            }
            uint256 _withdrawnBal = balanceOfWant();
            _debtPayment = Math.min(_debtOutstanding, _withdrawnBal);
        }

        // serious loss should never happen, but if it does (for instance, if Curve is hacked), let's record it accurately
        uint256 assets = estimatedTotalAssets();
        uint256 debt = vault.strategies(address(this)).totalDebt;

        // if assets are greater than debt, things are working great!
        if (assets > debt) {
            _profit = assets.sub(debt);
            uint256 _wantBal = balanceOfWant();
            if (_profit.add(_debtPayment) > _wantBal) {
                // this should only be hit following donations to strategy
                _liquidateAllPositions();
            }
        }
        // if assets are less than debt, we are in trouble
        else {
            _loss = debt.sub(assets);
        }
    }

    // solhint-disable-next-line no-unused-vars
    function _adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }
        // Send all of our Curve pool tokens to be deposited
        uint256 _toInvest = balanceOfWant();
        // deposit into convex and stake immediately (but only if we have something to invest)
        if (_toInvest > 0) {
            IConvexDeposit(_DEPOSIT_CONTRACT).deposit(pid, _toInvest, true);
        }
    }

    function _liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 _wantBal = balanceOfWant();
        if (_amountNeeded > _wantBal) {
            uint256 _stakedBal = stakedBalance();
            if (_stakedBal > 0) {
                rewardsContract.withdrawAndUnwrap(Math.min(_stakedBal, _amountNeeded.sub(_wantBal)), claimRewards);
            }
            uint256 _withdrawnBal = balanceOfWant();
            _liquidatedAmount = Math.min(_amountNeeded, _withdrawnBal);
            _loss = _amountNeeded.sub(_liquidatedAmount);
        } else {
            // we have enough balance to cover the liquidation available
            return (_amountNeeded, 0);
        }
    }

    // fire sale, get rid of it all!
    function _liquidateAllPositions() internal override returns (uint256) {
        uint256 _stakedBal = stakedBalance();
        if (_stakedBal > 0) {
            // don't bother withdrawing zero
            rewardsContract.withdrawAndUnwrap(_stakedBal, claimRewards);
        }
        return balanceOfWant();
    }

    // in case we need to exit into the convex deposit token, this will allow us to do that
    // make sure to check claimRewards before this step if needed
    // plan to have gov sweep convex deposit tokens from strategy after this
    function withdrawToConvexDepositTokens() external onlyGovernance {
        uint256 _stakedBal = stakedBalance();
        if (_stakedBal > 0) {
            rewardsContract.withdraw(_stakedBal, claimRewards);
        }
    }

    // migrate our want token to a new strategy if needed, make sure to check claimRewards first
    // also send over any CRV or CVX that is claimed; for migrations we definitely want to claim
    function _prepareMigration(address _newStrategy) internal override {
        uint256 _stakedBal = stakedBalance();
        if (_stakedBal > 0) {
            rewardsContract.withdrawAndUnwrap(_stakedBal, claimRewards);
        }
        _CRV.safeTransfer(_newStrategy, _CRV.balanceOf(address(this)));
        _CONVEX_TOKEN.safeTransfer(_newStrategy, _CONVEX_TOKEN.balanceOf(address(this)));
    }

    // we don't want for these tokens to be swept out. We allow gov to sweep out cvx vault tokens; we would only be holding these if things were really, really rekt.
    function _protectedTokens() internal view override returns (address[] memory) {}

    // We usually don't need to claim rewards on withdrawals, but might change our mind for migrations etc
    function setClaimRewards(bool _claimRewards) external onlyGovernance {
        claimRewards = _claimRewards;
    }

    // Use to add, update or remove rewards
    function updateRewards(bool _hasRewards, uint256 _rewardsIndex) external onlyGovernance {
        if (address(rewardsToken) != address(0) && address(rewardsToken) != address(_CONVEX_TOKEN)) {
            rewardsToken.approve(_SUSHI_SWAP, uint256(0));
        }
        if (_hasRewards == false) {
            hasRewards = false;
            rewardsToken = IERC20(address(0));
            virtualRewardsPool = address(0);
        } else {
            // update with our new token. get this via our virtualRewardsPool
            virtualRewardsPool = rewardsContract.extraRewards(_rewardsIndex);
            address _rewardsToken = IConvexRewards(virtualRewardsPool).rewardToken();
            rewardsToken = IERC20(_rewardsToken);

            // approve, setup our path, and turn on rewards
            rewardsToken.approve(_SUSHI_SWAP, type(uint256).max);
            _rewardsPath = [address(rewardsToken), address(_WETH)];
            hasRewards = true;
        }
    }

    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _convexAmount) internal {
        if (_convexAmount > 1e17) {
            // don't want to swap dust or we might revert
            _CVX_ETH.exchange(1, 0, _convexAmount, 0, false);
        }

        if (_crvAmount > 1e17) {
            // don't want to swap dust or we might revert
            _CRV_ETH.exchange(1, 0, _crvAmount, 0, false);
        }

        uint256 _wethBalance = _WETH.balanceOf(address(this));

        // don't want to swap dust or we might revert
        if (_wethBalance > 1e15) {
            _swapEthToTargetToken(_wethBalance);
        }
    }

    function _swapEthToTargetToken(uint256 _wethBalance) internal virtual;

    function _addLiquidityToCurve() internal virtual;

    // Sells our harvested reward token into the selected output.
    function _sellRewards(uint256 _amount) internal {
        IUniswapV2Router02(_SUSHI_SWAP).swapExactTokensForTokens(
            _amount,
            uint256(0),
            _rewardsPath,
            address(this),
            block.timestamp
        );
    }

    // We don't need this anymore since we don't use baseStrategy harvestTrigger
    function ethToWant(uint256 _ethAmount) public view override returns (uint256) {}
}