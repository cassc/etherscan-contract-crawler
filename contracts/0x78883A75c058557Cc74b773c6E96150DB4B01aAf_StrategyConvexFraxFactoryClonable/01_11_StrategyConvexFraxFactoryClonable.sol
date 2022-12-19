// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;
pragma experimental ABIEncoderV2;

// These are the core Yearn libraries
import "Math.sol";
import "curve.sol";
import "BaseStrategy.sol";

interface ITradeFactory {
    function enable(address, address) external;

    function disable(address, address) external;
}

interface IOracle {
    function getPriceUsdcRecommended(
        address tokenAddress
    ) external view returns (uint256);
}

interface IDetails {
    // get details from curve
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

interface IConvexFrax {
    // use this to create our personal convex frax vault for this strategy to get convex's FXS boost
    function createVault(uint256 pid) external returns (address);

    function getReward() external; // claim our rewards from the staking contract via our user vault

    function stakeLockedCurveLp(
        uint256 _liquidity,
        uint256 _secs
    ) external returns (bytes32 kek_id); // stake our frax convex LP as a new kek

    function lockAdditionalCurveLp(bytes32 _kek_id, uint256 _addl_liq) external; // add want to an existing lock/kek

    // returns FXS first, then any other reward token, then CRV and CVX
    function earned()
        external
        view
        returns (
            address[] memory token_addresses,
            uint256[] memory total_earned
        );

    function fxs() external view returns (address);

    function crv() external view returns (address);

    function cvx() external view returns (address);

    function lock_time_for_max_multiplier() external view returns (uint256);

    function lock_time_min() external view returns (uint256);

    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 amount;
        uint256 ending_timestamp;
        uint256 multiplier; // 6 decimals of precision. 1x = 1000000
    }

    function lockedLiquidityOf(address user) external view returns (uint256);

    function lockedStakesOf(
        address _address
    ) external view returns (LockedStake[] memory);

    function withdrawLockedAndUnwrap(bytes32 _kek_id) external;
}

contract StrategyConvexFraxFactoryClonable is BaseStrategy {
    using SafeERC20 for IERC20;
    /* ========== STATE VARIABLES ========== */

    /// @notice This is the Frax Booster.
    address public fraxBooster;

    /// @notice This is the staking address specific to this Convex pool.
    IConvexFrax public stakingAddress;

    /// @notice This is a unique numerical identifier for each Convex Frax pool.
    uint256 public fraxPid;

    /// @notice This is the vault our strategy uses to stake on Frax and use Convex's boost.
    IConvexFrax public userVault;

    /// @notice The percentage of CRV from each harvest that we send to our voter (out of 10,000).
    uint256 public localKeepCRV;

    /// @notice The percentage of CVX from each harvest that we send to our voter (out of 10,000).
    uint256 public localKeepCVX;

    /// @notice The percentage of FXS from each harvest that we send to our voter (out of 10,000).
    uint256 public localKeepFXS;

    /// @notice The address of our Curve voter. This is where we send any keepCRV.
    address public curveVoter;

    /// @notice The address of our Convex voter. This is where we send any keepCVX.
    address public convexVoter;

    /// @notice The address of our Frax voter. This is where we send any keepFXS.
    address public fraxVoter;

    // this means all of our fee values are in basis points
    uint256 internal constant FEE_DENOMINATOR = 10000;

    /// @notice The address of our base token (CRV for Curve, BAL for Balancer, etc.).
    IERC20 public crv;

    /// @notice The address of our Convex token (CVX for Curve, AURA for Balancer, etc.).
    IERC20 public convexToken;

    /// @notice The address of our Frax token (FXS).
    IERC20 public fxs;

    // we use this to be able to adjust our strategy's name
    string internal stratName;

    /// @notice Minimum profit size in USDC that we want to harvest.
    /// @dev Only used in harvestTrigger.
    uint256 public harvestProfitMinInUsdc;

    /// @notice Maximum profit size in USDC that we want to harvest (ignore gas price once we get here).
    /// @dev Only used in harvestTrigger.
    uint256 public harvestProfitMaxInUsdc;

    // ySwaps stuff
    /// @notice The address of our ySwaps trade factory.
    address public tradeFactory;

    /// @notice Array of any extra rewards tokens this Convex pool may have.
    address[] public rewardsTokens;

    /// @notice Will only be true on the original deployed contract and not on clones; we don't want to clone a clone.
    bool public isOriginal = true;

    // Vars to track our frax deposits
    /// @notice Timestamp of the most recent deposit to track when all funds will become liquid.
    uint256 public lastDeposit;

    /// @notice Most recent amount deposited.
    uint256 public lastDepositAmount;

    /// @notice Minimum size required for deposit (in want).
    /// @dev Prevents us from creating a new kek for only dust.
    uint256 public minDeposit;

    /// @notice Maximum size for a single deposit (in want).
    /// @dev Prevents large imbalances in our kek sizes following a large deposit.
    uint256 public maxSingleDeposit;

    /// @notice This is the time the tokens are locked for when staked.
    /// @dev Initially set to the min time, ~1 week, and can be updated later if desired.
    uint256 public lockTime;

    /// @notice This is the max number of keks we will allow the strategy to have
    ///  open at one time to limit withdraw loops.
    /// @dev A new kek (position) is created each time we stake the LP token. A whole
    ///  kek must be withdrawn during any withdrawals.
    uint256 public maxKeks;

    /// @notice The index of the next kek to be deposited to for deposit/withdrawal tracking.
    uint256 public nextKek;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _vault,
        address _tradeFactory,
        uint256 _fraxPid,
        address _stakingAddress,
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc,
        address _booster
    ) BaseStrategy(_vault) {
        _initializeStrat(
            _tradeFactory,
            _fraxPid,
            _stakingAddress,
            _harvestProfitMinInUsdc,
            _harvestProfitMaxInUsdc,
            _booster
        );
    }

    /* ========== CLONING ========== */

    event Cloned(address indexed clone);

    /// @notice Use this to clone an exact copy of this strategy on another vault.
    /// @dev In practice, this will only be called by the factory on the template contract.
    /// @param _vault Vault address we are targeting with this strategy.
    /// @param _strategist Address to grant the strategist role.
    /// @param _rewards If we have any strategist rewards, send them here.
    /// @param _keeper Address to grant the keeper role.
    /// @param _tradeFactory Our trade factory address.
    /// @param _fraxPid Our frax pool id (pid) for this strategy.
    /// @param _stakingAddress Convex staking address for our want token.
    /// @param _harvestProfitMinInUsdc Minimum acceptable profit for a harvest.
    /// @param _harvestProfitMaxInUsdc Maximum acceptable profit for a harvest.
    /// @param _booster Address of the convex frax booster/deposit contract.
    function cloneStrategyConvexFrax(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _tradeFactory,
        uint256 _fraxPid,
        address _stakingAddress,
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc,
        address _booster
    ) external returns (address newStrategy) {
        // don't clone a clone
        if (!isOriginal) {
            revert();
        }

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

        StrategyConvexFraxFactoryClonable(newStrategy).initialize(
            _vault,
            _strategist,
            _rewards,
            _keeper,
            _tradeFactory,
            _fraxPid,
            _stakingAddress,
            _harvestProfitMinInUsdc,
            _harvestProfitMaxInUsdc,
            _booster
        );

        emit Cloned(newStrategy);
    }

    /// @notice Initialize the strategy.
    /// @dev This should only be called by the clone function above.
    /// @param _vault Vault address we are targeting with this strategy.
    /// @param _strategist Address to grant the strategist role.
    /// @param _rewards If we have any strategist rewards, send them here.
    /// @param _keeper Address to grant the keeper role.
    /// @param _tradeFactory Our trade factory address.
    /// @param _fraxPid Our frax pool id (pid) for this strategy.
    /// @param _stakingAddress Convex staking address for our want token.
    /// @param _harvestProfitMinInUsdc Minimum acceptable profit for a harvest.
    /// @param _harvestProfitMaxInUsdc Maximum acceptable profit for a harvest.
    /// @param _booster Address of the convex frax booster/deposit contract.
    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _tradeFactory,
        uint256 _fraxPid,
        address _stakingAddress,
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc,
        address _booster
    ) public {
        _initialize(_vault, _strategist, _rewards, _keeper);
        _initializeStrat(
            _tradeFactory,
            _fraxPid,
            _stakingAddress,
            _harvestProfitMinInUsdc,
            _harvestProfitMaxInUsdc,
            _booster
        );
    }

    // this is called by our original strategy, as well as any clones
    function _initializeStrat(
        address _tradeFactory,
        uint256 _fraxPid,
        address _stakingAddress,
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc,
        address _booster
    ) internal {
        // make sure that we haven't initialized this before
        if (fraxBooster != address(0)) {
            revert(); // already initialized.
        }

        // 1:1 assignments
        tradeFactory = _tradeFactory;
        fraxPid = _fraxPid;
        stakingAddress = IConvexFrax(_stakingAddress);
        harvestProfitMinInUsdc = _harvestProfitMinInUsdc;
        harvestProfitMaxInUsdc = _harvestProfitMaxInUsdc;
        fraxBooster = _booster;

        // have our strategy deploy our vault from the booster using the fraxPid
        userVault = IConvexFrax(IConvexFrax(_booster).createVault(_fraxPid));

        // pull our token addresses from the user vault
        convexToken = IERC20(userVault.cvx());
        crv = IERC20(userVault.crv());
        fxs = IERC20(userVault.fxs());

        // want = Curve LP
        want.approve(address(userVault), type(uint256).max);

        // set up our max delay
        maxReportDelay = 365 days;

        // setup our default frax LP management vars
        maxKeks = 5;
        lockTime = stakingAddress.lock_time_min(); // default to current minimum
        maxSingleDeposit = 500_000e18;
        minDeposit = 10_000e18;

        // set up rewards and trade factory
        _updateRewards();
        _setUpTradeFactory();

        // set our strategy's name
        stratName = string(
            abi.encodePacked(
                "StrategyConvexFraxFactory-",
                IDetails(address(want)).symbol()
            )
        );
    }

    /* ========== VIEWS ========== */

    /// @notice Strategy name.
    function name() external view override returns (string memory) {
        return stratName;
    }

    /// @notice Balance of want staked in Convex Frax.
    function stakedBalance() public view returns (uint256) {
        // how much want we have staked in Convex-Frax
        return stakingAddress.lockedLiquidityOf(address(userVault));
    }

    /// @notice Balance of want sitting in our strategy.
    function balanceOfWant() public view returns (uint256) {
        // balance of want sitting in our strategy
        return want.balanceOf(address(this));
    }

    /// @notice Total assets the strategy holds, sum of loose and staked want.
    function estimatedTotalAssets() public view override returns (uint256) {
        return balanceOfWant() + stakedBalance();
    }

    /* ========== CORE STRATEGY FUNCTIONS ========== */

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        // rewards will be converted later with mev protection by yswaps (tradeFactory)
        userVault.getReward();

        // by default this is zero, but if we want any for our voter this will be used
        uint256 _localKeepCRV = localKeepCRV;
        address _curveVoter = curveVoter;
        if (_localKeepCRV > 0 && _curveVoter != address(0)) {
            uint256 crvBalance = crv.balanceOf(address(this));
            uint256 _sendToVoter = (crvBalance * _localKeepCRV) /
                FEE_DENOMINATOR;
            if (_sendToVoter > 0) {
                crv.safeTransfer(_curveVoter, _sendToVoter);
            }
        }

        // by default this is zero, but if we want any for our voter this will be used
        uint256 _localKeepCVX = localKeepCVX;
        address _convexVoter = convexVoter;
        if (_localKeepCVX > 0 && _convexVoter != address(0)) {
            uint256 cvxBalance = convexToken.balanceOf(address(this));
            uint256 _sendToVoter = (cvxBalance * _localKeepCVX) /
                FEE_DENOMINATOR;
            if (_sendToVoter > 0) {
                convexToken.safeTransfer(_convexVoter, _sendToVoter);
            }
        }

        // by default this is zero, but if we want any for our voter this will be used
        uint256 _localKeepFXS = localKeepFXS;
        address _fraxVoter = fraxVoter;
        if (_localKeepFXS > 0 && _fraxVoter != address(0)) {
            uint256 fxsBalance = fxs.balanceOf(address(this));
            uint256 _sendToVoter = (fxsBalance * _localKeepFXS) /
                FEE_DENOMINATOR;
            if (_sendToVoter > 0) {
                fxs.safeTransfer(_fraxVoter, _sendToVoter);
            }
        }

        // serious loss should never happen, but if it does (for instance, if Curve is hacked), let's record it accurately
        uint256 assets = estimatedTotalAssets();
        uint256 debt = vault.strategies(address(this)).totalDebt;

        // if assets are greater than debt, things are working great!
        if (assets >= debt) {
            _profit = assets - debt;
            _debtPayment = _debtOutstanding;

            uint256 toFree = _profit + _debtPayment;

            // freed is math.min(wantBalance, toFree)
            (uint256 freed, ) = liquidatePosition(toFree);

            if (toFree > freed) {
                if (_debtPayment > freed) {
                    _debtPayment = freed;
                    _profit = 0;
                } else {
                    _profit = freed - _debtPayment;
                }
            }
        }
        // if assets are less than debt, we are in trouble. don't worry about withdrawing here, just report losses
        else {
            _loss = debt - assets;
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        // if in emergency exit, we don't want to deploy any more funds
        if (emergencyExit) {
            return;
        }

        // Send all of our Curve pool tokens to be deposited
        uint256 _toInvest = balanceOfWant();

        // don't bother with dust
        if (_toInvest < minDeposit) {
            return;
        }

        // don't want a single kek too large vs others
        if (_toInvest > maxSingleDeposit) {
            _toInvest = maxSingleDeposit;
        }

        // If we have already locked the max amount of keks, we need
        // to withdraw the oldest one and reinvest that alongside the new funds
        if (nextKek >= maxKeks) {
            // Get the oldest kek that could have funds in it
            IConvexFrax.LockedStake memory stake = stakingAddress
                .lockedStakesOf(address(userVault))[nextKek - maxKeks];
            // Make sure it hasn't already been withdrawn
            if (stake.amount > 0) {
                // Withdraw funds and add them to the amount to deposit
                userVault.withdrawLockedAndUnwrap(stake.kek_id);
                unchecked {
                    _toInvest += stake.amount;
                }
            }
        }

        userVault.stakeLockedCurveLp(_toInvest, lockTime);
        lastDeposit = block.timestamp;
        lastDepositAmount = _toInvest;
        nextKek++;
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        // check our loose want
        uint256 _wantBal = balanceOfWant();
        if (_amountNeeded > _wantBal) {
            uint256 _stakedBal = stakedBalance();
            if (_stakedBal > 0) {
                uint256 _neededFromStaked;
                unchecked {
                    _neededFromStaked = _amountNeeded - _wantBal;
                }
                // Need to check that there is enough liquidity to withdraw so we dont report loss thats not true
                if (lastDeposit + lockTime > block.timestamp) {
                    require(
                        stakedBalance() - stillLockedStake() >=
                            _neededFromStaked,
                        "Need to wait until most recent deposit unlocks"
                    );
                }
                // no need to check for >0, we know _neededFromStaked has to be at least 1 wei
                withdrawSome(_neededFromStaked);
            }
            uint256 _withdrawnBal = balanceOfWant();
            _liquidatedAmount = Math.min(_amountNeeded, _withdrawnBal);
            unchecked {
                _loss = _amountNeeded - _liquidatedAmount;
            }
        } else {
            // we have enough balance to cover the liquidation available
            return (_amountNeeded, 0);
        }
    }

    // this function manages withdrawing from multiple keks at once
    function withdrawSome(uint256 _amount) internal {
        IConvexFrax.LockedStake[] memory stakes = stakingAddress.lockedStakesOf(
            address(userVault)
        );

        uint256 i = nextKek > maxKeks ? nextKek - maxKeks : 0;
        uint256 needed = Math.min(_amount, stakedBalance());
        IConvexFrax.LockedStake memory stake;
        uint256 liquidity;
        while (needed > 0 && i < nextKek) {
            stake = stakes[i];
            liquidity = stake.amount;

            if (liquidity > 0 && stake.ending_timestamp <= block.timestamp) {
                userVault.withdrawLockedAndUnwrap(stake.kek_id);

                if (liquidity < needed) {
                    unchecked {
                        needed -= liquidity;
                        i++;
                    }
                } else {
                    break;
                }
            } else {
                unchecked {
                    i++;
                }
            }
        }
    }

    /**
     * @notice Liquidate everything we can during emergencyExit.
     *
     * @dev
     *  Will liquidate as much as possible at the time. May not be able
     *  to liquidate all if anything has been deposited in the last week.
     *  Would then have to be called again after locked period has expired.
     *  Note that when this is called (only during emergencyExit) any
     *  funds not retrieved at the time will be treated as a loss.
     */
    function liquidateAllPositions() internal override returns (uint256) {
        withdrawSome(type(uint256).max);
        return balanceOfWant();
    }

    /**
     * @notice Migrate want and reward tokens to our new strategy.
     *
     * @dev
     *  Migration should only be called if all funds are completely liquid.
     *  In an emergency,first try manually withdrawing any liquid keks using
     *  manualWithdraw() and wait until the remainder becomes liquid.
     *  This will allow as much of the liquid position to be withdrawn
     *  while allowing future withdraws for still locked tokens with no loss.
     *  Setting emergencyExit to true and harvesting is another option,
     *  but in this case funds not retrieved at the time will be recorded
     *  as a loss.
     */
    function prepareMigration(address _newStrategy) internal override {
        require(
            lastDeposit + lockTime < block.timestamp,
            "Latest deposit is not avialable yet for withdraw"
        );
        withdrawSome(type(uint256).max);

        uint256 crvBal = crv.balanceOf(address(this));
        uint256 cvxBal = convexToken.balanceOf(address(this));
        uint256 fxsBal = fxs.balanceOf(address(this));

        if (crvBal > 0) {
            crv.safeTransfer(_newStrategy, crvBal);
        }
        if (cvxBal > 0) {
            convexToken.safeTransfer(_newStrategy, cvxBal);
        }
        if (fxsBal > 0) {
            fxs.safeTransfer(_newStrategy, fxsBal);
        }
    }

    // want is blocked by default, add any other tokens to protect from gov here.
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}

    /* ========== YSWAPS ========== */

    /// @notice Use to add or update rewards, rebuilds tradefactory too
    /// @dev Do this before updating trade factory if we have extra rewards.
    ///  Can only be called by governance.
    function updateRewards() external onlyGovernance {
        address tf = tradeFactory;
        _removeTradeFactoryPermissions(true);
        _updateRewards();

        tradeFactory = tf;
        _setUpTradeFactory();
    }

    function _updateRewards() internal {
        // empty the rewardsTokens and rebuild
        delete rewardsTokens;

        // check our user vault to see what rewards we have
        (address[] memory tokenAddresses, ) = userVault.earned();
        uint256 rewardsLength = tokenAddresses.length;

        // if we have rewards other than CRV, CVX, and FXS then add them too
        // we know that the first and last two spots are CRV, CVX, and FXS
        if (rewardsLength > 3) {
            for (uint256 i = 1; i < rewardsLength - 2; ++i) {
                address _rewardsToken = tokenAddresses[i];
                rewardsTokens.push(_rewardsToken);
            }
        }
    }

    /// @notice Use to update our trade factory.
    /// @dev Can only be called by governance.
    /// @param _newTradeFactory Address of new trade factory.
    function updateTradeFactory(
        address _newTradeFactory
    ) external onlyGovernance {
        require(
            _newTradeFactory != address(0),
            "Can't remove with this function"
        );
        _removeTradeFactoryPermissions(true);
        tradeFactory = _newTradeFactory;
        _setUpTradeFactory();
    }

    function _setUpTradeFactory() internal {
        // approve and set up trade factory
        address _tradeFactory = tradeFactory;
        address _want = address(want);

        ITradeFactory tf = ITradeFactory(_tradeFactory);
        crv.approve(_tradeFactory, type(uint256).max);
        tf.enable(address(crv), _want);

        // enable if we have anything else
        for (uint256 i; i < rewardsTokens.length; ++i) {
            address _rewardsToken = rewardsTokens[i];
            IERC20(_rewardsToken).approve(_tradeFactory, type(uint256).max);
            tf.enable(_rewardsToken, _want);
        }

        convexToken.approve(_tradeFactory, type(uint256).max);
        tf.enable(address(convexToken), _want);

        fxs.approve(_tradeFactory, type(uint256).max);
        tf.enable(address(fxs), _want);
    }

    /// @notice Use this to remove permissions from our current trade factory.
    /// @dev Once this is called, setUpTradeFactory must be called to get things working again.
    /// @param _disableTf Specify whether to disable the tradefactory when removing.
    ///  Option given in case we need to get around a reverting disable.
    function removeTradeFactoryPermissions(
        bool _disableTf
    ) external onlyVaultManagers {
        _removeTradeFactoryPermissions(_disableTf);
    }

    function _removeTradeFactoryPermissions(bool _disableTf) internal {
        address _tradeFactory = tradeFactory;
        if (_tradeFactory == address(0)) {
            return;
        }
        ITradeFactory tf = ITradeFactory(_tradeFactory);

        address _want = address(want);
        crv.approve(_tradeFactory, 0);
        if (_disableTf) {
            tf.disable(address(crv), _want);
        }

        // disable for any other rewards tokens too
        for (uint256 i; i < rewardsTokens.length; ++i) {
            address _rewardsToken = rewardsTokens[i];
            IERC20(_rewardsToken).approve(_tradeFactory, 0);
            if (_disableTf) {
                tf.disable(_rewardsToken, _want);
            }
        }

        convexToken.approve(_tradeFactory, 0);
        if (_disableTf) {
            tf.disable(address(convexToken), _want);
        }

        fxs.approve(_tradeFactory, 0);
        if (_disableTf) {
            tf.disable(address(fxs), _want);
        }

        tradeFactory = address(0);
    }

    /* ========== KEEP3RS ========== */

    /**
     * @notice
     *  Provide a signal to the keeper that harvest() should be called.
     *
     *  Don't harvest if a strategy is inactive.
     *  If our profit exceeds our upper limit, then harvest no matter what. For
     *  our lower profit limit, credit threshold, max delay, and manual force trigger,
     *  only harvest if our gas price is acceptable.
     *
     * @param callCostinEth The keeper's estimated gas cost to call harvest() (in wei).
     * @return True if harvest() should be called, false otherwise.
     */
    function harvestTrigger(
        uint256 callCostinEth
    ) public view override returns (bool) {
        // Should not trigger if strategy is not active (no assets and no debtRatio). This means we don't need to adjust keeper job.
        if (!isActive()) {
            return false;
        }

        // harvest if we have a profit to claim at our upper limit without considering gas price
        uint256 claimableProfit = claimableProfitInUsdc();
        if (claimableProfit > harvestProfitMaxInUsdc) {
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
        if (claimableProfit > harvestProfitMinInUsdc) {
            return true;
        }

        StrategyParams memory params = vault.strategies(address(this));
        // harvest regardless of profit once we reach our maxDelay
        if (block.timestamp - params.lastReport > maxReportDelay) {
            return true;
        }

        // harvest our credit if it's above our threshold
        if (vault.creditAvailable() > creditThreshold) {
            return true;
        }

        // otherwise, we don't harvest
        return false;
    }

    /// @notice Calculates the profit if all claimable assets were sold for USDC (6 decimals).
    /// @return Total return in USDC from selling claimable CRV, CVX, and FXS.
    function claimableProfitInUsdc() public view returns (uint256) {
        (, uint256[] memory tokenAmounts) = userVault.earned();
        // get our balances of fxs, crv, cvx. fxs always first, crv + cvx always last two
        uint256 claimableFxs = tokenAmounts[0];
        uint256 rewardLength = tokenAmounts.length;
        uint256 claimableCvx = tokenAmounts[rewardLength - 1];
        uint256 claimableCrv = tokenAmounts[rewardLength - 2];

        IOracle yearnOracle = IOracle(
            0x83d95e0D5f402511dB06817Aff3f9eA88224B030
        ); // yearn lens oracle
        uint256 crvPrice = yearnOracle.getPriceUsdcRecommended(address(crv));
        uint256 cvxPrice = yearnOracle.getPriceUsdcRecommended(
            address(convexToken)
        );
        uint256 fxsPrice = yearnOracle.getPriceUsdcRecommended(address(fxs));

        return
            (crvPrice *
                claimableCrv +
                cvxPrice *
                claimableCvx +
                fxsPrice *
                claimableFxs) / 1e18;
    }

    /// @notice Convert our keeper's eth cost into want
    /// @dev We don't use this since we don't factor call cost into our harvestTrigger.
    /// @param _ethAmount Amount of ether spent.
    /// @return Value of ether in want.
    function ethToWant(
        uint256 _ethAmount
    ) public view override returns (uint256) {}

    /* ========== FRAX-SPECIFIC FUNCTIONS ========== */

    /// @notice Check how much want we have locked (not just deposited) in the staking contract.
    /// @return stillLocked The total amount of want that cannot yet be withdrawn from the staking contract.
    function stillLockedStake() public view returns (uint256 stillLocked) {
        IConvexFrax.LockedStake[] memory stakes = stakingAddress.lockedStakesOf(
            address(userVault)
        );

        IConvexFrax.LockedStake memory stake;
        uint256 time = block.timestamp;
        uint256 _nextKek = nextKek;
        uint256 _maxKeks = maxKeks;
        uint256 i = _nextKek > _maxKeks ? _nextKek - _maxKeks : 0;

        for (i; i < _nextKek; ++i) {
            stake = stakes[i];

            if (stake.ending_timestamp > time) {
                unchecked {
                    stillLocked += stake.amount;
                }
            }
        }
    }

    /// @notice This function allows manual withdrawal of a specific kek.
    /// @dev Available if the counter or loops fail.
    /// @param index Index of the kek to withdraw.
    //Pass the index of the kek to withdraw as the param
    function manualWithdraw(uint256 index) external onlyVaultManagers {
        userVault.withdrawLockedAndUnwrap(
            stakingAddress.lockedStakesOf(address(userVault))[index].kek_id
        );
    }

    /* ========== SETTERS ========== */
    // These functions are useful for setting parameters of the strategy that may need to be adjusted.

    /// @notice Changes the maximum amount of keks we can deposit into at once.
    /// @dev Will withdraw funds if lowering the max. Ideally should harvest
    ///  after adjusting to prevent loose funds sitting idle.
    /// @param _newMaxKeks New number of maxKeks.
    function setMaxKeks(uint256 _newMaxKeks) external onlyVaultManagers {
        require(_newMaxKeks > 0, "Must be >0");

        uint256 _maxKeks = maxKeks;
        uint256 _nextKek = nextKek;

        // If we are lowering the max we need to withdraw the diff,
        // but only if we are already over the new max
        if (_newMaxKeks < _maxKeks) {
            // this second if statement will likely only be false early on (unless we choose a massive newMaxKeks)
            if (_newMaxKeks < _nextKek) {
                uint256 toWithdraw = _nextKek > _maxKeks
                    ? _maxKeks - _newMaxKeks
                    : nextKek - _newMaxKeks;
                IConvexFrax.LockedStake[] memory stakes = stakingAddress
                    .lockedStakesOf(address(userVault));
                IConvexFrax.LockedStake memory stake;

                for (uint256 i; i < toWithdraw; ++i) {
                    // withdraw our oldest keks to lower the number staked.
                    stake = _maxKeks > _nextKek
                        ? stakes[i]
                        : stakes[_nextKek - _maxKeks + i];

                    // Need to make sure the kek can be withdrawn and is > 0
                    if (stake.amount > 0) {
                        require(
                            stake.ending_timestamp < block.timestamp,
                            "Not liquid"
                        );
                        userVault.withdrawLockedAndUnwrap(stake.kek_id);
                    }
                }
            }
        }
        maxKeks = _newMaxKeks;
    }

    /// @notice Set the lower and upper bounds of our deposit size.
    /// @dev Min prevents us from harvesting in dust for a kek, and
    ///  max is how large we allow one kek to be.
    /// @param _minDeposit Minimum want needed to create a new kek.
    /// @param _maxSingleDeposit Maximum size of a single kek.
    function setDepositParams(
        uint256 _minDeposit,
        uint256 _maxSingleDeposit
    ) external onlyVaultManagers {
        require(
            _maxSingleDeposit > _minDeposit,
            "Max must be greater than min"
        );
        minDeposit = _minDeposit;
        maxSingleDeposit = _maxSingleDeposit;
    }

    /// @notice This can be used to update how long the tokens are locked when staked.
    /// @dev Care should be taken when increasing the time to only update directly
    ///  before a harvest, otherwise timestamp checks when withdrawing could be inaccurate.
    /// @param _lockTime Time to lock our LP (in seconds). By default bound to 1 week < t < 1 year.
    function setLockTime(uint256 _lockTime) external onlyVaultManagers {
        require(
            stakingAddress.lock_time_min() <= _lockTime &&
                _lockTime <= stakingAddress.lock_time_for_max_multiplier(),
            "Disallowed by staking address"
        );
        lockTime = _lockTime;
    }

    /// @notice Use this to set or update our keep amounts for this strategy.
    /// @dev Must be less than 10,000. Set in basis points. Only governance can set this.
    /// @param _keepCrv Percent of each CRV harvest to send to our voter.
    /// @param _keepCvx Percent of each CVX harvest to send to our voter.
    /// @param _keepFxs Percent of each FXS harvest to send to our voter.
    function setLocalKeepCrvs(
        uint256 _keepCrv,
        uint256 _keepCvx,
        uint256 _keepFxs
    ) external onlyGovernance {
        if (_keepCrv > 10_000 || _keepCvx > 10_000 || _keepFxs > 10_000) {
            revert();
        }

        if (_keepCrv > 0 && curveVoter == address(0)) {
            revert();
        }

        if (_keepCvx > 0 && convexVoter == address(0)) {
            revert();
        }

        if (_keepFxs > 0 && fraxVoter == address(0)) {
            revert();
        }

        localKeepCRV = _keepCrv;
        localKeepCVX = _keepCvx;
        localKeepFXS = _keepFxs;
    }

    /// @notice Use this to set or update our voter contracts.
    /// @dev For Convex Frax strategies, this is simply where we send our keepCRV, keepCVX and keepFXS.
    ///  Only governance can set this.
    /// @param _curveVoter Address of our curve voter.
    /// @param _convexVoter Address of our convex voter.
    /// @param _convexFraxVoter Address of our frax voter.
    function setVoters(
        address _curveVoter,
        address _convexVoter,
        address _convexFraxVoter
    ) external onlyGovernance {
        curveVoter = _curveVoter;
        convexVoter = _convexVoter;
        fraxVoter = _convexFraxVoter;
    }

    /**
     * @notice
     *  Here we set various parameters to optimize our harvestTrigger.
     * @param _harvestProfitMinInUsdc The amount of profit (in USDC, 6 decimals)
     *  that will trigger a harvest if gas price is acceptable.
     * @param _harvestProfitMaxInUsdc The amount of profit in USDC that
     *  will trigger a harvest regardless of gas price.
     */
    function setHarvestTriggerParams(
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc
    ) external onlyVaultManagers {
        harvestProfitMinInUsdc = _harvestProfitMinInUsdc;
        harvestProfitMaxInUsdc = _harvestProfitMaxInUsdc;
    }
}