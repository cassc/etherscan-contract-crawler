// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import "IERC20.sol";
import "SafeERC20.sol";
import "Address.sol";
import "Math.sol";
import "SafeMath.sol";
import "ICurve.sol";

import {IUniswapV2Router02} from "IUniV2.sol";

import "BaseStrategy.sol";

import "IOracle.sol";
import "IUniV3.sol";
import "IConvexRewards.sol";
import "IConvexDeposit.sol";


abstract contract StrategyConvexBase is BaseStrategy {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    /* ========== STATE VARIABLES ========== */
    // these should stay the same across different wants.

    // convex stuff
    address internal constant depositContract =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31; // this is the deposit contract that all pools use, aka booster
    IConvexRewards public rewardsContract; // This is unique to each curve pool
    address public virtualRewardsPool; // This is only if we have bonus rewards
    uint256 public pid; // this is unique to each pool

    // keepCRV stuff
    uint256 public keepCRV; // the percentage of CRV we re-lock for boost (in basis points)
    uint256 public keepCVX; // the percentage of CVX we keep for boosting yield (in basis points)
    address public keepCVXDestination; // where we send the CVX we are keeping
    address public voter;
    uint256 internal constant FEE_DENOMINATOR = 10000; // this means all of our fee values are in basis points

    // Swap stuff
    address internal constant sushiswap =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // we use this to sell our bonus token

    IERC20 internal constant crv =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 internal constant convexToken =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 internal constant weth =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // keeper stuff
    uint256 public harvestProfitMin; // minimum size in USD (6 decimals) that we want to harvest
    uint256 public harvestProfitMax; // maximum size in USD (6 decimals) that we want to harvest


    string internal stratName;

    // convex-specific variables
    bool public claimRewards; // boolean if we should always claim rewards when withdrawing, usually via withdrawAndUnwrap (generally this should be false)

    /* ========== CONSTRUCTOR ========== */

    constructor(address _vault) BaseStrategy(_vault) {}

    /* ========== VIEWS ========== */

    function name() external view override returns (string memory) {
        return stratName;
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

    function estimatedTotalAssets() public view override returns (uint256) {
        return balanceOfWant().add(stakedBalance());
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }
        // Send all of our Curve pool tokens to be deposited
        uint256 _toInvest = balanceOfWant();
        // deposit into convex and stake immediately (but only if we have something to invest)
        if (_toInvest > 0) {
            IConvexDeposit(depositContract).deposit(pid, _toInvest, true);
        }
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 _wantBal = balanceOfWant();
        if (_amountNeeded > _wantBal) {
            uint256 _stakedBal = stakedBalance();
            if (_stakedBal > 0) {
                rewardsContract.withdrawAndUnwrap(
                    Math.min(_stakedBal, _amountNeeded.sub(_wantBal)),
                    claimRewards
                );
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
    function liquidateAllPositions() internal override returns (uint256) {
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
    function withdrawToConvexDepositTokens() external onlyVaultManagers {
        uint256 _stakedBal = stakedBalance();
        if (_stakedBal > 0) {
            rewardsContract.withdraw(_stakedBal, claimRewards);
        }
    }

    // we don't want for these tokens to be swept out. We allow gov to sweep out cvx vault tokens; we would only be holding these if things were really, really rekt.
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}

    /* ========== SETTERS ========== */

    // These functions are useful for setting parameters of the strategy that may need to be adjusted.

    // Set the amount of CRV to be locked in Yield's veCRV voter from each harvest. Default is 10%. Option to keep CVX as well.
    function setKeep(
        uint256 _keepCRV,
        uint256 _keepCVX,
        address _keepCVXDestination,
        address _keepCRVDestination
    ) external onlyGovernance {
        require(_keepCRV <= 10_000 && _keepCVX <= 10_000);
        keepCRV = _keepCRV;
        keepCVX = _keepCVX;
        keepCVXDestination = _keepCVXDestination;
        voter = _keepCRVDestination;
    }

    function setKeepCRV(uint256 _keepCRV, address _keepCRVDestination) external onlyGovernance {
        keepCRV = _keepCRV;
        voter = _keepCRVDestination;
    }

    // We usually don't need to claim rewards on withdrawals, but might change our mind for migrations etc
    function setClaimRewards(bool _claimRewards) external onlyVaultManagers {
        claimRewards = _claimRewards;
    }

}

contract StrategyConvex3CrvRewardsClonable is StrategyConvexBase {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    // these will likely change across different wants.

    // Curve stuff
    address public curve; // Curve Pool, this is our pool specific to this vault
    ICurveFi internal constant zapContract =
        ICurveFi(0xA79828DF1850E8a3A3064576f380D90aECDD3359); // this is used for depositing to all 3Crv metapools

    bool public checkEarmark; // this determines if we should check if we need to earmark rewards before harvesting

    // use Curve to sell our CVX and CRV rewards to WETH
    ICurveFi internal constant crveth =
        ICurveFi(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511); // use curve's new CRV-ETH crypto pool to sell our CRV
    ICurveFi internal constant cvxeth =
        ICurveFi(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4); // use curve's new CVX-ETH crypto pool to sell our CVX

    // we use these to deposit to our curve pool
    address public targetStable;
    address internal constant uniswapv3 =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    IERC20 internal constant usdt =
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 internal constant usdc =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 internal constant dai =
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    uint24 public uniStableFee; // this is equal to 0.05%, can change this later if a different path becomes more optimal

    // rewards token info. we can have more than 1 reward token but this is rare, so we don't include this in the template
    IERC20 public rewardsToken;
    bool public hasRewards;
    address[] internal rewardsPath;

    // check for cloning
    bool internal isOriginal = true;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _vault,
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) public StrategyConvexBase(_vault) {
        _initializeStrat(_pid, _curvePool, _name);
    }

    /* ========== CLONING ========== */

    event Cloned(address indexed clone);

    // we use this to clone our original strategy to other vaults
    function cloneConvex3CrvRewards(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) external returns (address newStrategy) {
        require(isOriginal);
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactorysol
        bytes20 addressBytes = bytes20(address(this));
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newStrategy := create(0, clone_code, 0x37)
        }

        StrategyConvex3CrvRewardsClonable(newStrategy).initialize(
            _vault,
            _strategist,
            _rewards,
            _keeper,
            _pid,
            _curvePool,
            _name
        );

        emit Cloned(newStrategy);
    }

    // this will only be called by the clone function above
    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) public {
        _initialize(_vault, _strategist, _rewards, _keeper);
        _initializeStrat(_pid, _curvePool, _name);
    }

    // this is called by our original strategy, as well as any clones
    function _initializeStrat(
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) internal {
        // make sure that we haven't initialized this before
        require(address(curve) == address(0)); // already initialized.

        // You can set these parameters on deployment to whatever you want
        maxReportDelay = 21 days; // 21 days in seconds, if we hit this then harvestTrigger = True
        healthCheck = 0xF939E44d0C9FF5da316D1Caca163BBc56b88445b;
        baseFeeOracle = 0x1323Fa099cB2c54EDa59fD4A8BB8DC8c0913B050;
        harvestProfitMin = 0;
        harvestProfitMax = 120000e6;
        creditThreshold = 1e6 * 1e18;

        // want = Curve LP
        want.approve(address(depositContract), type(uint256).max);
        convexToken.approve(address(cvxeth), type(uint256).max);
        crv.approve(address(crveth), type(uint256).max);
        weth.approve(uniswapv3, type(uint256).max);

        // this is the pool specific to this vault, but we only use it as an address
        curve = address(_curvePool);

        // setup our rewards contract
        pid = _pid; // this is the pool ID on convex, we use this to determine what the reweardsContract address is
        (address lptoken, , , address _rewardsContract, , ) =
            IConvexDeposit(depositContract).poolInfo(_pid);

        // set up our rewardsContract
        rewardsContract = IConvexRewards(_rewardsContract);

        // check that our LP token based on our pid matches our want
        require(address(lptoken) == address(want));

        // set our strategy's name
        stratName = _name;

        // these are our approvals and path specific to this contract
        dai.approve(address(zapContract), type(uint256).max);
        usdt.safeApprove(address(zapContract), type(uint256).max); // USDT requires safeApprove(), funky token
        usdc.approve(address(zapContract), type(uint256).max);

        // start with usdt
        targetStable = address(usdt);

        // set our uniswap pool fees
        uniStableFee = 500;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function prepareReturn(uint256 _debtOutstanding)
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

        uint256 crvBalance = crv.balanceOf(address(this));
        uint256 convexBalance = convexToken.balanceOf(address(this));

        uint256 _sendToVoter = crvBalance.mul(keepCRV).div(FEE_DENOMINATOR);
        if (_sendToVoter > 0) {
            crv.safeTransfer(voter, _sendToVoter);
            crvBalance = crv.balanceOf(address(this));
        }

        uint256 _cvxToKeep = convexBalance.mul(keepCVX).div(FEE_DENOMINATOR);
        if (_cvxToKeep > 0) {
            convexToken.safeTransfer(keepCVXDestination, _cvxToKeep);
            convexBalance = convexToken.balanceOf(address(this));
        }

        // claim and sell our rewards if we have them
        if (hasRewards) {
            uint256 _rewardsBalance =
                IERC20(rewardsToken).balanceOf(address(this));
            if (_rewardsBalance > 0) {
                _sellRewards(_rewardsBalance);
            }
        }

        // do this even if we have zero balances so we can sell WETH from rewards
        _sellCrvAndCvx(crvBalance, convexBalance);

        // check for balances of tokens to deposit
        uint256 _daiBalance = dai.balanceOf(address(this));
        uint256 _usdcBalance = usdc.balanceOf(address(this));
        uint256 _usdtBalance = usdt.balanceOf(address(this));

        // deposit our balance to Curve if we have any
        if (_daiBalance > 0 || _usdcBalance > 0 || _usdtBalance > 0) {
            zapContract.add_liquidity(
                curve,
                [0, _daiBalance, _usdcBalance, _usdtBalance],
                0
            );
        }

        // debtOustanding will only be > 0 in the event of revoking or if we need to rebalance from a withdrawal or lowering the debtRatio
        if (_debtOutstanding > 0) {
            uint256 _stakedBal = stakedBalance();
            if (_stakedBal > 0) {
                rewardsContract.withdrawAndUnwrap(
                    Math.min(_stakedBal, _debtOutstanding),
                    claimRewards
                );
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
                liquidateAllPositions();
            }
        }
        // if assets are less than debt, we are in trouble
        else {
            _loss = debt.sub(assets);
        }

        // we're done harvesting, so reset our trigger if we used it
        forceHarvestTriggerOnce = false;
    }

    // migrate our want token to a new strategy if needed, make sure to check claimRewards first
    // also send over any CRV or CVX that is claimed; for migrations we definitely want to claim
    function prepareMigration(address _newStrategy) internal override {
        uint256 _stakedBal = stakedBalance();
        if (_stakedBal > 0) {
            rewardsContract.withdrawAndUnwrap(_stakedBal, claimRewards);
        }
        crv.safeTransfer(_newStrategy, crv.balanceOf(address(this)));
        convexToken.safeTransfer(
            _newStrategy,
            convexToken.balanceOf(address(this))
        );
    }

    // Sells our CRV and CVX on Curve, then WETH -> stables together on UniV3
    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _convexAmount)
        internal
    {
        if (_convexAmount > 1e17) {
            // don't want to swap dust or we might revert
            cvxeth.exchange(1, 0, _convexAmount, 0, false);
        }

        if (_crvAmount > 1e17) {
            // don't want to swap dust or we might revert
            crveth.exchange(1, 0, _crvAmount, 0, false);
        }

        uint256 _wethBalance = weth.balanceOf(address(this));
        if (_wethBalance > 1e15) {
            // don't want to swap dust or we might revert
            IUniV3(uniswapv3).exactInput(
                IUniV3.ExactInputParams(
                    abi.encodePacked(
                        address(weth),
                        uint24(uniStableFee),
                        address(targetStable)
                    ),
                    address(this),
                    block.timestamp,
                    _wethBalance,
                    uint256(1)
                )
            );
        }
    }

    // Sells our harvested reward token into the selected output.
    function _sellRewards(uint256 _amount) internal {
        IUniswapV2Router02(sushiswap).swapExactTokensForTokens(
            _amount,
            uint256(0),
            rewardsPath,
            address(this),
            block.timestamp
        );
    }

    /* ========== KEEP3RS ========== */
    // use this to determine when to harvest
    function harvestTrigger(uint256 callCostinEth)
        public
        view
        override
        returns (bool)
    {
        // Should not trigger if strategy is not active (no assets and no debtRatio). This means we don't need to adjust keeper job.
        if (!isActive()) {
            return false;
        }

        // only check if we need to earmark on vaults we know are problematic
        if (checkEarmark) {
            // don't harvest if we need to earmark convex rewards
            if (needsEarmarkReward()) {
                return false;
            }
        }


        // harvest if we have a profit to claim at our upper limit without considering gas price
        uint256 claimableProfit = claimableProfitInUsdt();
        if (claimableProfit > harvestProfitMax) {
            return true;
        }


        // check if the base fee gas price is higher than we allow. if it is, block harvests.
        if (!isBaseFeeAcceptable()) {
            return false;
        }

        // trigger if we want to manually harvest, but only if our gas price is acceptable
        if (forceHarvestTriggerOnce) {
            return true;
        }

        // harvest if we have a sufficient profit to claim, but only if our gas price is acceptable
        if (claimableProfit > harvestProfitMin) {
            return true;
        }

        StrategyParams memory params = vault.strategies(address(this));
        // harvest no matter what once we reach our maxDelay
        if (block.timestamp.sub(params.lastReport) > maxReportDelay) {
            return true;
        }

        // harvest our credit if it's above our threshold
        if (vault.creditAvailable() > creditThreshold) {
            return true;
        }

        // otherwise, we don't harvest
        return false;
    }

    /// @notice The value in dollars that our claimable rewards are worth (in USDT, 6 decimals).
    function claimableProfitInUsdt() public view returns (uint256) {
        // calculations pulled directly from CVX's contract for minting CVX per CRV claimed
        uint256 totalCliffs = 1_000;
        uint256 maxSupply = 100 * 1_000_000 * 1e18; // 100mil
        uint256 reductionPerCliff = 100_000 * 1e18; // 100,000
        uint256 supply = convexToken.totalSupply();
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
        uint256 ethPrice = ethOracle.latestAnswer().div(1e2); // 1e8 div 1e2 = 1e6
        uint256 crvPrice = crveth.price_oracle().mul(ethPrice).div(1e18); // 1e18 mul 1e6 div 1e18 = 1e6
        uint256 cvxPrice = cvxeth.price_oracle().mul(ethPrice).div(1e18); // 1e18 mul 1e6 div 1e18 = 1e6

        uint256 crvValue = crvPrice.mul(_claimableBal).div(1e18); // 1e6 mul 1e18 div 1e18 = 1e6
        uint256 cvxValue = cvxPrice.mul(mintableCvx).div(1e18); // 1e6 mul 1e18 div 1e18 = 1e6

        // get the value of our rewards token if we have one
        uint256 rewardsValue;
        if (hasRewards) {
            address[] memory usd_path = new address[](3);
            usd_path[0] = address(rewardsToken);
            usd_path[1] = address(weth);
            usd_path[2] = address(usdt);

            uint256 _claimableBonusBal =
                IConvexRewards(virtualRewardsPool).earned(address(this));
            if (_claimableBonusBal > 0) {
                uint256[] memory rewardSwap =
                    IUniswapV2Router02(sushiswap).getAmountsOut(
                        _claimableBonusBal,
                        usd_path
                    );
                rewardsValue = rewardSwap[rewardSwap.length - 1];
            }
        }

        return crvValue.add(cvxValue).add(rewardsValue);
    }

    // convert our keeper's eth cost into want, we don't need this anymore since we don't use baseStrategy harvestTrigger
    function ethToWant(uint256 _ethAmount)
        public
        view
        override
        returns (uint256)
    {}

    /// @notice True if someone needs to earmark rewards on Convex before keepers harvest again
    function needsEarmarkReward() public view returns (bool needsEarmark) {
        // check if there is any CRV we need to earmark
        uint256 crvExpiry = rewardsContract.periodFinish();
        if (crvExpiry < block.timestamp) {
            return true;
        } else if (hasRewards) {
            // check if there is any bonus reward we need to earmark
            uint256 rewardsExpiry =
                IConvexRewards(virtualRewardsPool).periodFinish();
            return rewardsExpiry < block.timestamp;
        }
    }

    /* ========== SETTERS ========== */

    // These functions are useful for setting parameters of the strategy that may need to be adjusted.

    /// @notice Set optimal token to sell harvested funds for depositing to Curve.
    function setOptimal(uint256 _optimal) external onlyVaultManagers {
        if (_optimal == 0) {
            targetStable = address(dai);
        } else if (_optimal == 1) {
            targetStable = address(usdc);
        } else if (_optimal == 2) {
            targetStable = address(usdt);
        } else {
            revert("incorrect token");
        }
    }

    /// @notice Use to update, add, or remove extra rewards tokens.
    function updateRewards(bool _hasRewards, uint256 _rewardsIndex)
        external
        onlyGovernance
    {
        if (
            address(rewardsToken) != address(0) &&
            address(rewardsToken) != address(convexToken)
        ) {
            rewardsToken.approve(sushiswap, uint256(0));
        }
        if (_hasRewards == false) {
            hasRewards = false;
            rewardsToken = IERC20(address(0));
            virtualRewardsPool = address(0);
        } else {
            // update with our new token. get this via our virtualRewardsPool
            virtualRewardsPool = rewardsContract.extraRewards(_rewardsIndex);
            address _rewardsToken =
                IConvexRewards(virtualRewardsPool).rewardToken();
            rewardsToken = IERC20(_rewardsToken);

            // approve, setup our path, and turn on rewards
            rewardsToken.approve(sushiswap, type(uint256).max);
            rewardsPath = [address(rewardsToken), address(weth)];
            hasRewards = true;
        }
    }

    /**
     * @notice
     * Here we set various parameters to optimize our harvestTrigger.
     * @param _harvestProfitMin The amount of profit (in USDC, 6 decimals)
     * that will trigger a harvest if gas price is acceptable.
     * @param _harvestProfitMax The amount of profit in USDC that
     * will trigger a harvest regardless of gas price.
     * @param _creditThreshold The number of want tokens that will
     * automatically trigger a harvest once gas is cheap enough.
     * @param _checkEarmark Whether or not we should check Convex's
     * booster to see if we need to earmark before harvesting.
     */
    function setHarvestTriggerParams(
        uint256 _harvestProfitMin,
        uint256 _harvestProfitMax,
        uint256 _creditThreshold,
        bool _checkEarmark
    ) external onlyVaultManagers {
        harvestProfitMin = _harvestProfitMin;
        harvestProfitMax = _harvestProfitMax;
        creditThreshold = _creditThreshold;
        checkEarmark = _checkEarmark;
    }

    /// @notice Set the fee pool we'd like to swap through on UniV3 (1% = 10_000)
    function setUniFees(uint24 _stableFee) external onlyVaultManagers {
        uniStableFee = _stableFee;
    }
}