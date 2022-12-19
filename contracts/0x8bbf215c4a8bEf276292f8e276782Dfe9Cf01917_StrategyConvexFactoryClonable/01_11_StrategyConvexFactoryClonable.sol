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
    // pull our asset price, in usdc, via yearn's oracle
    function getPriceUsdcRecommended(
        address tokenAddress
    ) external view returns (uint256);
}

interface IConvexRewards {
    // strategy's staked balance in the synthetix staking contract
    function balanceOf(address account) external view returns (uint256);

    // read how much claimable CRV a strategy has
    function earned(address account) external view returns (uint256);

    // burn a tokenized deposit (Convex deposit tokens) to receive curve lp tokens back
    function withdraw(uint256 _amount, bool _claim) external returns (bool);

    // withdraw directly to curve LP token, this is what we primarily use
    function withdrawAndUnwrap(
        uint256 _amount,
        bool _claim
    ) external returns (bool);

    // claim rewards, with an option to claim extra rewards or not
    function getReward(
        address _account,
        bool _claimExtras
    ) external returns (bool);

    // check if we have rewards on a pool
    function extraRewardsLength() external view returns (uint256);

    // if we have rewards, see what the address is
    function extraRewards(uint256 _reward) external view returns (address);

    // read our rewards token
    function rewardToken() external view returns (address);

    // check our reward period finish
    function periodFinish() external view returns (uint256);
}

interface IDetails {
    // get details from curve
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

interface IConvexDeposit {
    // deposit into convex, receive a tokenized deposit.  parameter to stake immediately (we always do this).
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    // pull our curve token address from the booster
    function crv() external view returns (address);

    // give us info about a pool based on its pid
    function poolInfo(
        uint256
    ) external view returns (address, address, address, address, address, bool);
}

contract StrategyConvexFactoryClonable is BaseStrategy {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice This is the deposit contract that all Convex pools use, aka booster.
    address public depositContract;

    /// @notice This is unique to each pool and holds the rewards.
    IConvexRewards public rewardsContract;

    /// @notice This is a unique numerical identifier for each Convex pool.
    uint256 public pid;

    /// @notice The percentage of CRV from each harvest that we send to our voter (out of 10,000).
    uint256 public localKeepCRV;

    /// @notice The percentage of CVX from each harvest that we send to our voter (out of 10,000).
    uint256 public localKeepCVX;

    /// @notice The address of our Curve voter. This is where we send any keepCRV.
    address public curveVoter;

    /// @notice The address of our Convex voter. This is where we send any keepCVX.
    address public convexVoter;

    // this means all of our fee values are in basis points
    uint256 internal constant FEE_DENOMINATOR = 10000;

    /// @notice The address of our base token (CRV for Curve, BAL for Balancer, etc.).
    IERC20 public crv;

    /// @notice The address of our Convex token (CVX for Curve, AURA for Balancer, etc.).
    IERC20 public convexToken;

    // we use this to be able to adjust our strategy's name
    string internal stratName;

    /// @notice Whether we should claim rewards when withdrawing, generally this should be false.
    bool public claimRewards;

    /// @notice Minimum profit size in USDC that we want to harvest.
    /// @dev Only used in harvestTrigger.
    uint256 public harvestProfitMinInUsdc;

    /// @notice Maximum profit size in USDC that we want to harvest (ignore gas price once we get here).
    /// @dev Only used in harvestTrigger.
    uint256 public harvestProfitMaxInUsdc;

    /// @notice Check if we need to earmark rewards on Convex before harvesting, usually false.
    /// @dev Only used in harvestTrigger.
    bool public checkEarmark;

    // ySwaps stuff
    /// @notice The address of our ySwaps trade factory.
    address public tradeFactory;

    /// @notice Array of any extra rewards tokens this Convex pool may have.
    address[] public rewardsTokens;

    /// @notice Will only be true on the original deployed contract and not on clones; we don't want to clone a clone.
    bool public isOriginal = true;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _vault,
        address _tradeFactory,
        uint256 _pid,
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc,
        address _booster,
        address _convexToken
    ) BaseStrategy(_vault) {
        _initializeStrat(
            _tradeFactory,
            _pid,
            _harvestProfitMinInUsdc,
            _harvestProfitMaxInUsdc,
            _booster,
            _convexToken
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
    /// @param _pid Our pool id (pid) for this strategy.
    /// @param _harvestProfitMinInUsdc Minimum acceptable profit for a harvest.
    /// @param _harvestProfitMaxInUsdc Maximum acceptable profit for a harvest.
    /// @param _booster Address of the convex booster/deposit contract.
    /// @param _convexToken Address of our convex token.
    function cloneStrategyConvex(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _tradeFactory,
        uint256 _pid,
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc,
        address _booster,
        address _convexToken
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

        StrategyConvexFactoryClonable(newStrategy).initialize(
            _vault,
            _strategist,
            _rewards,
            _keeper,
            _tradeFactory,
            _pid,
            _harvestProfitMinInUsdc,
            _harvestProfitMaxInUsdc,
            _booster,
            _convexToken
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
    /// @param _pid Our pool id (pid) for this strategy.
    /// @param _harvestProfitMinInUsdc Minimum acceptable profit for a harvest.
    /// @param _harvestProfitMaxInUsdc Maximum acceptable profit for a harvest.
    /// @param _booster Address of the convex booster/deposit contract.
    /// @param _convexToken Address of our convex token.
    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _tradeFactory,
        uint256 _pid,
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc,
        address _booster,
        address _convexToken
    ) public {
        _initialize(_vault, _strategist, _rewards, _keeper);
        _initializeStrat(
            _tradeFactory,
            _pid,
            _harvestProfitMinInUsdc,
            _harvestProfitMaxInUsdc,
            _booster,
            _convexToken
        );
    }

    // this is called by our original strategy, as well as any clones via the above function
    function _initializeStrat(
        address _tradeFactory,
        uint256 _pid,
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc,
        address _booster,
        address _convexToken
    ) internal {
        // make sure that we haven't initialized this before
        if (depositContract != address(0)) {
            revert(); // already initialized.
        }

        // 1:1 assignments
        tradeFactory = _tradeFactory;
        pid = _pid;
        harvestProfitMinInUsdc = _harvestProfitMinInUsdc;
        harvestProfitMaxInUsdc = _harvestProfitMaxInUsdc;
        depositContract = _booster;
        convexToken = IERC20(_convexToken);

        // want = Curve LP
        want.approve(address(_booster), type(uint256).max);

        // set up our max delay
        maxReportDelay = 365 days;

        // use the booster contract to pull more info needed
        IConvexDeposit booster = IConvexDeposit(_booster);
        crv = IERC20(booster.crv());
        (address lptoken, , , address _rewardsContract, , ) = booster.poolInfo(
            _pid
        );
        rewardsContract = IConvexRewards(_rewardsContract);
        if (address(lptoken) != address(want)) {
            revert();
        }

        // set up rewards and trade factory
        _updateRewards();
        _setUpTradeFactory();

        // set our strategy's name
        stratName = string(
            abi.encodePacked(
                "StrategyConvexFactory-",
                IDetails(address(want)).symbol()
            )
        );
    }

    /* ========== VIEWS ========== */

    /// @notice Strategy name.
    function name() external view override returns (string memory) {
        return stratName;
    }

    /// @notice Balance of want staked in Convex.
    function stakedBalance() public view returns (uint256) {
        return rewardsContract.balanceOf(address(this));
    }

    /// @notice Balance of want sitting in our strategy.
    function balanceOfWant() public view returns (uint256) {
        // balance of want sitting in our strategy
        return want.balanceOf(address(this));
    }

    /// @notice Balance of CRV we can claim from the staking contract.
    function claimableBalance() public view returns (uint256) {
        return rewardsContract.earned(address(this));
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
        // this claims our CRV, CVX, and any extra tokens like SNX or ANKR. no harm leaving this true even if no extra rewards currently
        // rewards will be converted later with mev protection by yswaps (tradeFactory)
        rewardsContract.getReward(address(this), true);

        // by default this is zero, but if we want any for our voter this will be used
        uint256 _localKeepCRV = localKeepCRV;
        address _curveVoter = curveVoter;
        if (_localKeepCRV > 0 && _curveVoter != address(0)) {
            uint256 crvBalance = crv.balanceOf(address(this));
            uint256 _sendToVoter;
            unchecked {
                _sendToVoter = (crvBalance * _localKeepCRV) / FEE_DENOMINATOR;
            }
            if (_sendToVoter > 0) {
                crv.safeTransfer(_curveVoter, _sendToVoter);
            }
        }

        // by default this is zero, but if we want any for our voter this will be used
        uint256 _localKeepCVX = localKeepCVX;
        address _convexVoter = convexVoter;
        if (_localKeepCVX > 0 && _convexVoter != address(0)) {
            uint256 cvxBalance = convexToken.balanceOf(address(this));
            uint256 _sendToVoter;
            unchecked {
                _sendToVoter = (cvxBalance * _localKeepCVX) / FEE_DENOMINATOR;
            }
            if (_sendToVoter > 0) {
                convexToken.safeTransfer(_convexVoter, _sendToVoter);
            }
        }

        // serious loss should never happen, but if it does (for instance, if Curve is hacked), let's record it accurately
        uint256 assets = estimatedTotalAssets();
        uint256 debt = vault.strategies(address(this)).totalDebt;

        // if assets are greater than debt, things are working great!
        if (assets >= debt) {
            unchecked {
                _profit = assets - debt;
            }
            _debtPayment = _debtOutstanding;

            uint256 toFree = _profit + _debtPayment;

            // freed is math.min(wantBalance, toFree)
            (uint256 freed, ) = liquidatePosition(toFree);

            if (toFree > freed) {
                if (_debtPayment > freed) {
                    _debtPayment = freed;
                    _profit = 0;
                } else {
                    unchecked {
                        _profit = freed - _debtPayment;
                    }
                }
            }
        }
        // if assets are less than debt, we are in trouble. don't worry about withdrawing here, just report losses
        else {
            unchecked {
                _loss = debt - assets;
            }
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        // if in emergency exit, we don't want to deploy any more funds
        if (emergencyExit) {
            return;
        }

        // Send all of our Curve pool tokens to be deposited
        uint256 _toInvest = balanceOfWant();

        // deposit into convex and stake immediately but only if we have something to invest
        // the final true argument means we deposit + stake at the same time
        if (_toInvest > 0) {
            IConvexDeposit(depositContract).deposit(pid, _toInvest, true);
        }
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
                // withdraw whatever extra funds we need
                rewardsContract.withdrawAndUnwrap(
                    Math.min(_stakedBal, _neededFromStaked),
                    claimRewards
                );
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

    // fire sale, get rid of it all!
    function liquidateAllPositions() internal override returns (uint256) {
        uint256 _stakedBal = stakedBalance();
        if (_stakedBal > 0) {
            // don't bother withdrawing zero, save gas where we can
            rewardsContract.withdrawAndUnwrap(_stakedBal, claimRewards);
        }
        return balanceOfWant();
    }

    // migrate our want token to a new strategy if needed, claim rewards tokens as well unless it's an emergency
    function prepareMigration(address _newStrategy) internal override {
        uint256 stakedBal = stakedBalance();

        if (stakedBal > 0) {
            rewardsContract.withdrawAndUnwrap(stakedBal, claimRewards);
        }

        uint256 crvBal = crv.balanceOf(address(this));
        uint256 cvxBal = convexToken.balanceOf(address(this));

        if (crvBal > 0) {
            crv.safeTransfer(_newStrategy, crvBal);
        }
        if (cvxBal > 0) {
            convexToken.safeTransfer(_newStrategy, cvxBal);
        }
    }

    // want is blocked by default, add any other tokens to protect from gov here.
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}

    /// @notice In case we need to emergency exit into the convex deposit
    ///  token, this will allow us to do that.
    /// @dev Make sure to check claimRewards before this step if needed, and
    ///  plan to have gov sweep convex deposit tokens from strategy after this.
    function withdrawToConvexDepositTokens() external onlyVaultManagers {
        uint256 _stakedBal = stakedBalance();
        if (_stakedBal > 0) {
            rewardsContract.withdraw(_stakedBal, claimRewards);
        }
    }

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

        // convex provides us info on any extra tokens we may receive
        uint256 length = rewardsContract.extraRewardsLength();
        address _convexToken = address(convexToken);
        for (uint256 i; i < length; ++i) {
            address virtualRewardsPool = rewardsContract.extraRewards(i);
            address _rewardsToken = IConvexRewards(virtualRewardsPool)
                .rewardToken();

            // we only need to approve the new token and turn on rewards if the extra reward isn't CVX
            if (_rewardsToken != _convexToken) {
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

        // enable for any rewards tokens too
        for (uint256 i; i < rewardsTokens.length; ++i) {
            address _rewardsToken = rewardsTokens[i];
            IERC20(_rewardsToken).approve(_tradeFactory, type(uint256).max);
            tf.enable(_rewardsToken, _want);
        }

        convexToken.approve(_tradeFactory, type(uint256).max);
        tf.enable(address(convexToken), _want);
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

        // disable for all rewards tokens too
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

        tradeFactory = address(0);
    }

    /* ========== KEEP3RS ========== */

    /**
     * @notice
     *  Provide a signal to the keeper that harvest() should be called.
     *
     *  Don't harvest if a strategy is inactive, or if it needs an earmark first.
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

        // only check if we need to earmark on vaults we know are problematic
        if (checkEarmark) {
            // don't harvest if we need to earmark convex rewards
            if (needsEarmarkReward()) {
                return false;
            }
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
    /// @dev Uses yearn's lens oracle, if returned values are strange then troubleshoot there.
    /// @return Total return in USDC from selling claimable CRV and CVX.
    function claimableProfitInUsdc() public view returns (uint256) {
        IOracle yearnOracle = IOracle(
            0x83d95e0D5f402511dB06817Aff3f9eA88224B030
        ); // yearn lens oracle
        uint256 crvPrice = yearnOracle.getPriceUsdcRecommended(address(crv));
        uint256 convexTokenPrice = yearnOracle.getPriceUsdcRecommended(
            address(convexToken)
        );

        // calculations pulled directly from CVX's contract for minting CVX per CRV claimed
        uint256 totalCliffs = 1_000;
        uint256 maxSupply; // 100mil
        unchecked {
            maxSupply = 100 * 1_000_000 * 1e18;
        }
        uint256 reductionPerCliff; // 100,000
        unchecked {
            reductionPerCliff = 100_000 * 1e18;
        }
        uint256 supply = convexToken.totalSupply();
        uint256 mintableCvx;

        uint256 cliff;
        unchecked {
            cliff = supply / reductionPerCliff;
        }
        uint256 _claimableBal = claimableBalance();

        // mint if below total cliffs
        if (cliff < totalCliffs) {
            uint256 reduction; // for reduction% take inverse of current cliff
            unchecked {
                reduction = totalCliffs - cliff;
            }
            // reduce
            unchecked {
                mintableCvx = (_claimableBal * reduction) / totalCliffs;
            }

            uint256 amtTillMax; // supply cap check
            unchecked {
                amtTillMax = maxSupply - supply;
            }
            if (mintableCvx > amtTillMax) {
                mintableCvx = amtTillMax;
            }
        }

        // Oracle returns prices as 6 decimals, so multiply by claimable amount and divide by token decimals (1e18)
        return
            (crvPrice * _claimableBal + convexTokenPrice * mintableCvx) / 1e18;
    }

    /// @notice Convert our keeper's eth cost into want
    /// @dev We don't use this since we don't factor call cost into our harvestTrigger.
    /// @param _ethAmount Amount of ether spent.
    /// @return Value of ether in want.
    function ethToWant(
        uint256 _ethAmount
    ) public view override returns (uint256) {}

    /// @notice Check if someone needs to earmark rewards on Convex before keepers harvest again.
    /// @dev Not worth harvesting if this is true as our rewards will be minimal.
    /// @return needsEarmark Whether or not rewards need to be earmarked before flowing again.
    function needsEarmarkReward() public view returns (bool needsEarmark) {
        // check if there is any CRV we need to earmark
        uint256 crvExpiry = rewardsContract.periodFinish();
        if (crvExpiry < block.timestamp) {
            return true;
        }
    }

    /* ========== SETTERS ========== */
    // These functions are useful for setting parameters of the strategy that may need to be adjusted.

    /// @notice Use this to set or update our keep amounts for this strategy.
    /// @dev Must be less than 10,000. Set in basis points. Only governance can set this.
    /// @param _keepCrv Percent of each CRV harvest to send to our voter.
    /// @param _keepCvx Percent of each CVX harvest to send to our voter.
    function setLocalKeepCrvs(
        uint256 _keepCrv,
        uint256 _keepCvx
    ) external onlyGovernance {
        if (_keepCrv > 10_000 || _keepCvx > 10_000) {
            revert();
        }

        if (_keepCrv > 0 && curveVoter == address(0)) {
            revert();
        }

        if (_keepCvx > 0 && convexVoter == address(0)) {
            revert();
        }

        localKeepCRV = _keepCrv;
        localKeepCVX = _keepCvx;
    }

    /// @notice Use this to set or update our voter contracts.
    /// @dev For Convex strategies, this is simply where we send our keepCRV and keepCVX.
    ///  Only governance can set this.
    /// @param _curveVoter Address of our curve voter.
    /// @param _convexVoter Address of our convex voter.
    function setVoters(
        address _curveVoter,
        address _convexVoter
    ) external onlyGovernance {
        curveVoter = _curveVoter;
        convexVoter = _convexVoter;
    }

    /// @notice Set whether we claim rewards on withdrawals.
    /// @dev Usually false, but may set to true during migrations.
    /// @param _claimRewards Whether we want to claim rewards on withdrawals.
    function setClaimRewards(bool _claimRewards) external onlyVaultManagers {
        claimRewards = _claimRewards;
    }

    /**
     * @notice
     *  Here we set various parameters to optimize our harvestTrigger.
     * @param _harvestProfitMinInUsdc The amount of profit (in USDC, 6 decimals)
     *  that will trigger a harvest if gas price is acceptable.
     * @param _harvestProfitMaxInUsdc The amount of profit in USDC that
     *  will trigger a harvest regardless of gas price.
     * @param _checkEarmark Whether or not we should check Convex's
     *  booster to see if we need to earmark before harvesting.
     */
    function setHarvestTriggerParams(
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc,
        bool _checkEarmark
    ) external onlyVaultManagers {
        harvestProfitMinInUsdc = _harvestProfitMinInUsdc;
        harvestProfitMaxInUsdc = _harvestProfitMaxInUsdc;
        checkEarmark = _checkEarmark;
    }
}