// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {SafeMath} from "SafeMath.sol";
import {SafeERC20} from "SafeERC20.sol";
import {Address} from "Address.sol";
import {ERC20} from "ERC20.sol";
import {Math} from "Math.sol";

import "curve.sol";
import {IUniswapV2Router02} from "uniswap.sol";
import {IERC20} from "IERC20.sol";
import {BaseStrategy, StrategyParams} from "BaseStrategy.sol";

interface IOracle {
    function latestAnswer() external view returns (uint256);
}

interface IUniV3 {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

interface IConvexRewards {
    // Strategy's staked balance in the synthetix staking contract
    function balanceOf(address account) external view returns (uint256);

    // Read how much claimable CRV a strategy has
    function earned(address account) external view returns (uint256);

    // Stake a convex tokenized deposit
    function stake(uint256 _amount) external returns (bool);

    // Withdraw to a convex tokenized deposit, probably never need to use this
    function withdraw(uint256 _amount, bool _claim) external returns (bool);

    // Withdraw directly to curve LP token, this is what we primarily use
    function withdrawAndUnwrap(uint256 _amount, bool _claim)
        external
        returns (bool);

    // Claim rewards, with an option to claim extra rewards or not
    function getReward(address _account, bool _claimExtras)
        external
        returns (bool);

    // Check if we have rewards on a pool
    function extraRewardsLength() external view returns (uint256);

    // If we have rewards, see what the address is
    function extraRewards(uint256 _reward) external view returns (address);

    // Read our rewards token
    function rewardToken() external view returns (address);

    // Check our reward period finish
    function periodFinish() external view returns (uint256);
}

interface IConvexDeposit {
    // Deposit into convex, receive a tokenized deposit.  parameter to stake immediately (we always do this)
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    // Burn a tokenized deposit (Convex deposit tokens) to receive curve lp tokens back
    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    // Give us info about a pool based on its pid
    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );
}

abstract contract StrategyConvexBase is BaseStrategy {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    // These should stay the same across different wants

    // Convex stuff
    address internal constant depositContract =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31; // This is the deposit contract that all pools use, aka booster
    IConvexRewards public rewardsContract; // This is unique to each curve pool
    address public virtualRewardsPool; // This is only if we have bonus rewards
    uint256 public pid; // This is unique to each pool

    // Swap stuff
    address internal constant sushiswap =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // We use this to sell our bonus token

    IERC20 internal constant crv =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 internal constant convexToken =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20 internal constant weth =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // Keeper stuff
    uint256 public harvestProfitMin; // Minimum size in USD (6 decimals) that we want to harvest
    uint256 public harvestProfitMax; // Maximum size in USD (6 decimals) that we want to harvest
    uint256 public creditThreshold; // Amount of credit in underlying tokens that will automatically trigger a harvest
    bool internal forceHarvestTriggerOnce; // Only set this to true when we want to trigger our keepers to harvest for us

    string internal stratName;

    // Convex-specific variables
    bool public claimRewards; // Boolean if we should always claim rewards when withdrawing, usually via withdrawAndUnwrap (generally this should be false)

    /* ========== CONSTRUCTOR ========== */

    constructor(address _vault) public BaseStrategy(_vault) {}

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
        // Deposit into Convex and stake immediately (but only if we have something to invest)
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
            // We have enough balance to cover the liquidation available
            return (_amountNeeded, 0);
        }
    }

    // Fire sale, get rid of it all!
    function liquidateAllPositions() internal override returns (uint256) {
        uint256 _stakedBal = stakedBalance();
        if (_stakedBal > 0) {
            // Don't bother withdrawing zero
            rewardsContract.withdrawAndUnwrap(_stakedBal, claimRewards);
        }
        return balanceOfWant();
    }

    // In case we need to exit into the convex deposit token, this will allow us to do that
    // Make sure to check claimRewards before this step if needed
    // Plan to have gov sweep Convex deposit tokens from strategy after this
    function withdrawToConvexDepositTokens() external onlyVaultManagers {
        uint256 _stakedBal = stakedBalance();
        if (_stakedBal > 0) {
            rewardsContract.withdraw(_stakedBal, claimRewards);
        }
    }

    // We don't want for these tokens to be swept out. We allow gov to sweep out cvx vault tokens;
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}

    /* ========== SETTERS ========== */

    // These functions are useful for setting parameters of the strategy that may need to be adjusted.

    // We usually don't need to claim rewards on withdrawals, but might change our mind for migrations etc
    function setClaimRewards(bool _claimRewards) external onlyVaultManagers {
        claimRewards = _claimRewards;
    }

    // This allows us to manually harvest with our keeper as needed
    function setForceHarvestTriggerOnce(bool _forceHarvestTriggerOnce)
        external
        onlyVaultManagers
    {
        forceHarvestTriggerOnce = _forceHarvestTriggerOnce;
    }
}

contract StrategyConvex3CrvRewardsClonable is StrategyConvexBase {
    /* ========== STATE VARIABLES ========== */
    // These will likely change across different wants

    // Curve stuff
    address public curve; // Curve Pool, this is our pool specific to this vault
    ICurveFi internal constant zapContract =
        ICurveFi(0xA79828DF1850E8a3A3064576f380D90aECDD3359); // This is used for depositing to all 3Crv Metapools

    bool public checkEarmark; // This determines if we should check if we need to earmark rewards before harvesting

    // Use Curve to sell our CVX and CRV rewards to WETH
    ICurveFi internal constant crveth =
        ICurveFi(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511); // Use curve's new CRV-ETH crypto pool to sell our CRV
    ICurveFi internal constant cvxeth =
        ICurveFi(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4); // Use curve's new CVX-ETH crypto pool to sell our CVX

    // We use these to deposit to our curve pool
    address public targetStable;
    address internal constant uniswapv3 =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    IERC20 internal constant usdt =
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 internal constant usdc =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 internal constant dai =
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    uint24 public uniStableFee; // This is equal to 0.05%, can change this later if a different path becomes more optimal

    // Rewards token info, we can have more than 1 reward token but this is rare, so we don't include this in the template
    IERC20 public rewardsToken;
    bool public hasRewards;
    address[] internal rewardsPath;

    // Check for cloning
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

    // We use this to clone our original strategy to other vaults
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
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
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

    // This will only be called by the clone function above
    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) public {
        _initialize(_vault, _strategist, _rewards, _keeper); // BaseStrategy
        _initializeStrat(_pid, _curvePool, _name); // Strategy
    }

    // This is called by our original strategy, as well as any clones
    function _initializeStrat(
        uint256 _pid,
        address _curvePool,
        string memory _name
    ) internal {
        // Make sure that we haven't initialized this before
        require(address(curve) == address(0)); // Already initialized.

        // You can set these parameters on deployment to whatever you want
        maxReportDelay = 21 days; // 21 days in seconds, if we hit this then harvestTrigger = True
        healthCheck = 0xDDCea799fF1699e98EDF118e0629A974Df7DF012; // NOTE health.ychad.eth
        harvestProfitMin = 60000e6;
        harvestProfitMax = 120000e6;
        creditThreshold = 1e6 * 1e18;

        // want = Curve LP
        want.approve(address(depositContract), type(uint256).max);
        convexToken.approve(address(cvxeth), type(uint256).max);
        crv.approve(address(crveth), type(uint256).max);
        weth.approve(uniswapv3, type(uint256).max);

        // This is the pool specific to this vault, but we only use it as an address
        curve = address(_curvePool);

        // Setup our rewards contract
        pid = _pid; // This is the pool ID on convex, we use this to determine what the rewardsContract address is
        (address lptoken, , , address _rewardsContract, , ) = IConvexDeposit(
            depositContract
        ).poolInfo(_pid);

        // Set up our rewardsContract
        rewardsContract = IConvexRewards(_rewardsContract);

        // Check that our LP token based on our pid matches our want
        require(address(lptoken) == address(want));

        // Set our strategy's name
        stratName = _name;

        // These are our approvals and path specific to this contract
        dai.approve(address(zapContract), type(uint256).max);
        usdt.safeApprove(address(zapContract), type(uint256).max); // USDT requires safeApprove(), funky token
        usdc.approve(address(zapContract), type(uint256).max);

        // Start with usdt
        targetStable = address(usdt);

        // Set our Uniswap pool fees
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
        // This claims our CRV, CVX, and any extra tokens like SNX or ANKR
        // No harm leaving this true even if no extra rewards currently
        rewardsContract.getReward(address(this), true);

        uint256 crvBalance = crv.balanceOf(address(this));
        uint256 convexBalance = convexToken.balanceOf(address(this));

        // Claim and sell our rewards if we have them
        if (hasRewards) {
            uint256 _rewardsBalance = IERC20(rewardsToken).balanceOf(
                address(this)
            );
            if (_rewardsBalance > 0) {
                _sellRewards(_rewardsBalance);
            }
        }

        _sellCrvAndCvx(crvBalance, convexBalance);

        // Check for balances of tokens to deposit
        uint256 _daiBalance = dai.balanceOf(address(this));
        uint256 _usdcBalance = usdc.balanceOf(address(this));
        uint256 _usdtBalance = usdt.balanceOf(address(this));

        // Deposit our balance to Curve if we have any
        if (_daiBalance > 0 || _usdcBalance > 0 || _usdtBalance > 0) {
            zapContract.add_liquidity(
                curve,
                [0, _daiBalance, _usdcBalance, _usdtBalance],
                0
            );
        }

        // debtOutstanding will only be > 0 in the event of revoking or if we need to rebalance from a withdrawal or lowering the debtRatio
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

        // Serious loss should never happen, but if it does (for instance, if Curve is hacked), let's record it accurately
        uint256 assets = estimatedTotalAssets();
        uint256 debt = vault.strategies(address(this)).totalDebt;

        // If assets are greater than debt, things are working great!
        if (assets > debt) {
            _profit = assets.sub(debt);
            uint256 _wantBal = balanceOfWant();
            if (_profit.add(_debtPayment) > _wantBal) {
                // This should only be hit following donations to strategy
                liquidateAllPositions();
            }
        }
        // If assets are less than debt, we are in trouble
        else {
            _loss = debt.sub(assets);
        }

        // We're done harvesting, so reset our trigger if we used it
        forceHarvestTriggerOnce = false;
    }

    // Migrate our want token to a new strategy if needed, make sure to check claimRewards first
    // Also send over any CRV or CVX that is claimed; for migrations we definitely want to claim
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

    // Sells our CRV -> WETH on Curve and CVX -> WETH on Curve, then WETH -> stables together on UniV3
    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _convexAmount)
        internal
    {
        if (_convexAmount > 1e17) {
            cvxeth.exchange(1, 0, _convexAmount, 0, false);
        }

        if (_crvAmount > 1e17) {
            crveth.exchange(1, 0, _crvAmount, 0, false);
        }

        uint256 _wethBalance = weth.balanceOf(address(this));
        if (_wethBalance > 1e13) {
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

    // Sells our harvested reward token into the selected output
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
    // Use this to determine when to harvest
    function harvestTrigger(uint256 callCostinEth)
        public
        view
        override
        returns (bool)
    {
        // Should not trigger if strategy is not active (no assets and no debtRatio)
        if (!isActive()) {
            return false;
        }

        // Only check if we need to earmark on vaults we know are problematic
        if (checkEarmark) {
            // Don't harvest if we need to earmark convex rewards
            if (needsEarmarkReward()) {
                return false;
            }
        }

        // Harvest if we have a profit to claim at our upper limit without considering gas price
        uint256 claimableProfit = claimableProfitInUsdt();
        if (claimableProfit > harvestProfitMax) {
            return true;
        }

        // Trigger if we want to manually harvest, but only if our gas price is acceptable
        if (forceHarvestTriggerOnce) {
            return true;
        }

        // Harvest if we have a sufficient profit to claim, but only if our gas price is acceptable
        if (claimableProfit > harvestProfitMin) {
            return true;
        }

        StrategyParams memory params = vault.strategies(address(this));
        // Harvest no matter what once we reach our maxDelay
        if (block.timestamp.sub(params.lastReport) > maxReportDelay) {
            return true;
        }

        // Harvest our credit if it's above our threshold
        if (vault.creditAvailable() > creditThreshold) {
            return true;
        }

        // Otherwise, we don't harvest
        return false;
    }

    /// @notice The value in dollars that our claimable rewards are worth (in USDT, 6 decimals)
    function claimableProfitInUsdt() public view returns (uint256) {
        // Calculations pulled directly from CVX's contract for minting CVX per CRV claimed
        uint256 totalCliffs = 1_000;
        uint256 maxSupply = 100 * 1_000_000 * 1e18; // 100 mil
        uint256 reductionPerCliff = 100_000 * 1e18; // 100,000
        uint256 supply = convexToken.totalSupply();
        uint256 mintableCvx;

        uint256 cliff = supply.div(reductionPerCliff);
        uint256 _claimableBal = claimableBalance();
        // Mint if below total cliffs
        if (cliff < totalCliffs) {
            // For reduction % take inverse of current cliff
            uint256 reduction = totalCliffs.sub(cliff);
            // Reduce
            mintableCvx = _claimableBal.mul(reduction).div(totalCliffs);

            // Supply cap check
            uint256 amtTillMax = maxSupply.sub(supply);
            if (mintableCvx > amtTillMax) {
                mintableCvx = amtTillMax;
            }
        }

        // Our Chainlink oracle returns prices normalized to 8 decimals, we convert it to 6
        IOracle ethOracle = IOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        uint256 ethPrice = ethOracle.latestAnswer().div(1e2); // 1e8 div 1e2 = 1e6
        uint256 crvPrice = crveth.price_oracle().mul(ethPrice).div(1e18); // 1e18 mul 1e6 div 1e18 = 1e6
        uint256 cvxPrice = cvxeth.price_oracle().mul(ethPrice).div(1e18); // 1e18 mul 1e6 div 1e18 = 1e6

        uint256 crvValue = crvPrice.mul(_claimableBal).div(1e18); // 1e6 mul 1e18 div 1e18 = 1e6
        uint256 cvxValue = cvxPrice.mul(mintableCvx).div(1e18); // 1e6 mul 1e18 div 1e18 = 1e6

        // Get the value of our rewards token if we have one
        uint256 rewardsValue;
        if (hasRewards) {
            address[] memory usd_path = new address[](3);
            usd_path[0] = address(rewardsToken);
            usd_path[1] = address(weth);
            usd_path[2] = address(usdt);

            uint256 _claimableBonusBal = IConvexRewards(virtualRewardsPool)
                .earned(address(this));
            if (_claimableBonusBal > 0) {
                uint256[] memory rewardSwap = IUniswapV2Router02(sushiswap)
                    .getAmountsOut(_claimableBonusBal, usd_path);
                rewardsValue = rewardSwap[rewardSwap.length - 1];
            }
        }

        return crvValue.add(cvxValue).add(rewardsValue);
    }

    // Convert our keeper's eth cost into want, we don't need this anymore since we don't use baseStrategy harvestTrigger
    function ethToWant(uint256 _ethAmount)
        public
        view
        override
        returns (uint256)
    {}

    /// @notice True if someone needs to earmark rewards on Convex before keepers harvest again
    function needsEarmarkReward() public view returns (bool needsEarmark) {
        // Check if there is any CRV we need to earmark
        uint256 crvExpiry = rewardsContract.periodFinish();
        if (crvExpiry < block.timestamp) {
            return true;
        } else if (hasRewards) {
            // Check if there is any bonus reward we need to earmark
            uint256 rewardsExpiry = IConvexRewards(virtualRewardsPool)
                .periodFinish();
            return rewardsExpiry < block.timestamp;
        }
    }

    /* ========== SETTERS ========== */

    // These functions are useful for setting parameters of the strategy that may need to be adjusted.

    /// @notice Set optimal token to sell harvested funds for depositing to Curve
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

    // Use to add, update or remove rewards
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
            // Update with our new token, we get this via our virtualRewardsPool
            virtualRewardsPool = rewardsContract.extraRewards(_rewardsIndex);
            address _rewardsToken = IConvexRewards(virtualRewardsPool)
                .rewardToken();
            rewardsToken = IERC20(_rewardsToken);

            // Approve, setup our path, and turn on rewards
            rewardsToken.approve(sushiswap, type(uint256).max);
            rewardsPath = [address(rewardsToken), address(weth)];
            hasRewards = true;
        }
    }

    // Min profit to start checking for harvests if gas is good, max will harvest no matter gas (both in USDT, 6 decimals).
    // Credit threshold is in want token, and will trigger a harvest if credit is large enough.
    // Check earmark to look at convex's booster.
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