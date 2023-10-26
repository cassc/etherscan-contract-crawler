// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/[email protected]/utils/math/Math.sol";
import "github.com/yearn/yearn-vaults/blob/v0.4.6/contracts/BaseStrategy.sol";

interface ITradeFactory {
    function enable(address, address) external;

    function disable(address, address) external;
}

interface IOracle {
    function latestRoundData(
        address,
        address
    )
        external
        view
        returns (
            uint80 roundId,
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
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
    // this is used on newer pools
    function earned(
        address
    ) external view returns (uint256[] memory total_earned);

    function getAllRewardTokens()
        external
        view
        returns (address[] memory token_addresses);

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

    struct KekInfo {
        /**
         * @notice This is the max number of keks we will allow the strategy to have
         *  open at one time to limit withdraw loops.
         * @dev A new kek (position) is created each time we stake the LP token. A whole
         *  kek must be withdrawn during any withdrawals.
         */
        uint128 maxKeks;
        /// @notice The index of the next kek to be deposited to for deposit/withdrawal tracking.
        uint128 nextKek;
    }

    struct DepositInfo {
        /**
         * @notice Minimum size required for deposit (in want).
         * @dev Prevents us from creating a new kek for only dust.
         */
        uint120 minDeposit;
        /**
         * @notice Maximum size for a single deposit (in want).
         * @dev Prevents large imbalances in our kek sizes following a large deposit.
         */
        uint120 maxSingleDeposit;
        /// @notice Determines whether every new deposit (adjustPosition call) goes to an existing kek or not
        bool addToExistingKeks;
    }

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

    /**
     * @notice Minimum profit size in USDC that we want to harvest.
     * @dev Only used in harvestTrigger.
     */
    uint256 public harvestProfitMinInUsdc;

    /**
     * @notice Maximum profit size in USDC that we want to harvest (ignore gas price once we get here).
     * @dev Only used in harvestTrigger.
     */
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

    /**
     * @notice This is the time the tokens are locked for when staked.
     * @dev Initially set to the min time, ~1 week, and can be updated later if desired.
     */
    uint256 public lockTime;

    /// @notice Info about our deposits. See struct NatSpec for more details.
    DepositInfo public depositInfo;

    /// @notice Info about our keks. See struct NatSpec for more details.
    KekInfo public kekInfo;

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

    /**
     * @notice Use this to clone an exact copy of this strategy on another vault.
     * @dev In practice, this will only be called by the factory on the template contract.
     * @param _vault Vault address we are targeting with this strategy.
     * @param _strategist Address to grant the strategist role.
     * @param _rewards If we have any strategist rewards, send them here.
     * @param _keeper Address to grant the keeper role.
     * @param _tradeFactory Our trade factory address.
     * @param _fraxPid Our frax pool id (pid) for this strategy.
     * @param _stakingAddress Convex staking address for our want token.
     * @param _harvestProfitMinInUsdc Minimum acceptable profit for a harvest.
     * @param _harvestProfitMaxInUsdc Maximum acceptable profit for a harvest.
     * @param _booster Address of the convex frax booster/deposit contract.
     */
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
            revert("Can't clone a clone'");
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

    /**
     * @notice Initialize the strategy.
     * @dev This should only be called by the clone function above.
     * @param _vault Vault address we are targeting with this strategy.
     * @param _strategist Address to grant the strategist role.
     * @param _rewards If we have any strategist rewards, send them here.
     * @param _keeper Address to grant the keeper role.
     * @param _tradeFactory Our trade factory address.
     * @param _fraxPid Our frax pool id (pid) for this strategy.
     * @param _stakingAddress Convex staking address for our want token.
     * @param _harvestProfitMinInUsdc Minimum acceptable profit for a harvest.
     * @param _harvestProfitMaxInUsdc Maximum acceptable profit for a harvest.
     * @param _booster Address of the convex frax booster/deposit contract.
     */
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
            revert("Already initialized");
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

        // set up our baseStrategy vars
        maxReportDelay = 365 days;
        creditThreshold = 50_000e18;

        // setup our default frax LP management vars
        kekInfo.maxKeks = 5;
        lockTime = stakingAddress.lock_time_min(); // default to current minimum
        depositInfo.maxSingleDeposit = 500_000e18;
        depositInfo.minDeposit = 100e18;
        depositInfo.addToExistingKeks = true; // this allows us to not worry about locking

        // set up rewards and trade factory
        _updateRewards();
        _setUpTradeFactory();
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Strategy name.
     * @return strategyName Strategy name.
     */
    function name()
        external
        view
        override
        returns (string memory strategyName)
    {
        return
            string(
                abi.encodePacked(
                    "StrategyConvexFraxFactory-",
                    IDetails(address(want)).symbol()
                )
            );
    }

    /**
     * @notice Balance of want staked in Convex Frax.
     * @return balanceStaked Balance of want staked in Convex Frax.
     */
    function stakedBalance() public view returns (uint256 balanceStaked) {
        balanceStaked = stakingAddress.lockedLiquidityOf(address(userVault));
    }

    /**
     * @notice Balance of want sitting in our strategy.
     * @return wantBalance Balance of want sitting in our strategy.
     */
    function balanceOfWant() public view returns (uint256 wantBalance) {
        wantBalance = want.balanceOf(address(this));
    }

    /**
     * @notice Total assets the strategy holds, sum of loose and staked want.
     * @return totalAssets Total assets the strategy holds, sum of loose and staked want.
     */
    function estimatedTotalAssets()
        public
        view
        override
        returns (uint256 totalAssets)
    {
        totalAssets = balanceOfWant() + stakedBalance();
    }

    /**
     * @notice Use this helper function to handle v1 and v2 Convex Frax stakingToken wrappers
     * @dev We use staticcall here, as on newer userVaults, earned() is a write function. So on newer pools, we instead
     *  pull the reward tokens and amounts from the staking contract.
     * @return tokenAddresses Array of our reward token addresses.
     * @return tokenAmounts Amounts of our corresponding reward tokens.
     */
    function getEarnedTokens()
        public
        view
        returns (address[] memory tokenAddresses, uint256[] memory tokenAmounts)
    {
        // on older pools, we can read directly from our user vault returns FXS, CRV, CVX addresses with amounts
        bytes memory data = abi.encodeWithSignature("earned()");
        (bool success, bytes memory returnBytes) = address(userVault)
            .staticcall(data);

        if (success) {
            (tokenAddresses, tokenAmounts) = abi.decode(
                returnBytes,
                (address[], uint256[])
            );
        } else {
            tokenAmounts = stakingAddress.earned(address(userVault));
            tokenAddresses = stakingAddress.getAllRewardTokens();
        }
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
        uint256 _sendToVoter;
        if (_localKeepCRV > 0 && _curveVoter != address(0)) {
            uint256 crvBalance = crv.balanceOf(address(this));
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
            unchecked {
                _sendToVoter = (cvxBalance * _localKeepCVX) / FEE_DENOMINATOR;
            }
            if (_sendToVoter > 0) {
                convexToken.safeTransfer(_convexVoter, _sendToVoter);
            }
        }

        // by default this is zero, but if we want any for our voter this will be used
        uint256 _localKeepFXS = localKeepFXS;
        address _fraxVoter = fraxVoter;
        if (_localKeepFXS > 0 && _fraxVoter != address(0)) {
            uint256 fxsBalance = fxs.balanceOf(address(this));
            unchecked {
                _sendToVoter = (fxsBalance * _localKeepFXS) / FEE_DENOMINATOR;
            }
            if (_sendToVoter > 0) {
                fxs.safeTransfer(_fraxVoter, _sendToVoter);
            }
        }

        // serious loss should never happen, but if it does (for instance, if Curve is hacked), let's record it
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
        uint256 _minDeposit = uint256(depositInfo.minDeposit);
        if (_toInvest < _minDeposit) {
            return;
        }

        // don't want a single kek too large vs others
        uint256 _maxSingleDeposit = uint256(depositInfo.maxSingleDeposit);
        if (_toInvest > _maxSingleDeposit) {
            _toInvest = _maxSingleDeposit;
        }

        // pull down our kek info
        uint256 _nextKek = uint256(kekInfo.nextKek);
        uint256 _maxKeks = uint256(kekInfo.maxKeks);

        // If we have already locked the max amount of keks, first check if we want to just add to existing keks or not
        if (_nextKek >= _maxKeks) {
            // pull our current stake data
            IConvexFrax.LockedStake[] memory stake = stakingAddress
                .lockedStakesOf(address(userVault));

            // only add to existing if we've maxxed out our number of keks
            if (depositInfo.addToExistingKeks) {
                // figure out which is our lowest TVL kek, start with our latest one
                IConvexFrax.LockedStake memory latestStake = stake[
                    _nextKek - 1
                ];
                bytes32 smallestKek = latestStake.kek_id;
                uint256 smallestKekSize = latestStake.amount;

                // if only 1 kek, no need to check which is the smallest
                if (_maxKeks != 1) {
                    for (uint256 i = 2; i <= _maxKeks; ++i) {
                        latestStake = stake[_nextKek - i];
                        // if a kek is smaller in size than our previous smallest, it
                        //   is now smallest
                        if (latestStake.amount < smallestKekSize) {
                            smallestKekSize = latestStake.amount;
                            smallestKek = latestStake.kek_id;
                        }
                    }
                }
                // deposit our assets to our smallest kek
                userVault.lockAdditionalCurveLp(smallestKek, _toInvest);
            } else {
                // if not, we need to withdraw the oldest one and reinvest that alongside the new funds

                // Get the oldest kek that could have funds in it
                IConvexFrax.LockedStake memory firstStake = stake[
                    _nextKek - _maxKeks
                ];
                // Make sure it hasn't already been withdrawn
                if (firstStake.amount > 0) {
                    // Withdraw funds and add them to the amount to deposit
                    userVault.withdrawLockedAndUnwrap(firstStake.kek_id);
                    unchecked {
                        _toInvest += firstStake.amount;
                    }

                    // don't want a single kek too large vs others
                    if (_toInvest > _maxSingleDeposit) {
                        _toInvest = _maxSingleDeposit;
                    }
                }
                // deposit, increment our next kek
                userVault.stakeLockedCurveLp(_toInvest, lockTime);
                kekInfo.nextKek++;
            }
        } else {
            // deposit, increment our next kek
            userVault.stakeLockedCurveLp(_toInvest, lockTime);
            kekInfo.nextKek++;
        }
        lastDeposit = block.timestamp;
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
                        "Need to wait until oldest deposit unlocks"
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

        // pull down our kek info
        uint256 _nextKek = uint256(kekInfo.nextKek);
        uint256 _maxKeks = uint256(kekInfo.maxKeks);

        uint256 i = _nextKek > _maxKeks ? _nextKek - _maxKeks : 0;
        uint256 needed = Math.min(_amount, stakedBalance());
        IConvexFrax.LockedStake memory stake;
        uint256 liquidity;
        while (needed > 0 && i < _nextKek) {
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
     *  Will liquidate as much as possible at the time. May not be able to liquidate all if anything has been deposited
     *  in the last week. Would then have to be called again after locked period has expired. Note that when this is
     *  called (only during emergencyExit) any funds not retrieved at the time will be treated as a loss.
     */
    function liquidateAllPositions() internal override returns (uint256) {
        withdrawSome(type(uint256).max);
        return balanceOfWant();
    }

    /**
     * @notice Migrate want and reward tokens to our new strategy.
     *
     * @dev
     *  Migration should only be called if all funds are completely liquid. In an emergency,first try manually
     *  withdrawing any liquid keks using manualWithdraw() and wait until the remainder becomes liquid. This will allow
     *  as much of the liquid position to be withdrawn while allowing future withdraws for still locked tokens with no
     *  loss. Setting emergencyExit to true and harvesting is another option, but in this case funds not retrieved at
     *  the time will be recorded as a loss.
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

    /**
     * @notice Use to add or update rewards, rebuilds tradefactory too
     * @dev Do this before updating trade factory if we have extra rewards. Can only be called by governance.
     */
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
        (address[] memory tokenAddresses, ) = getEarnedTokens();
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

    /**
     * @notice Use to update our trade factory.
     * @dev Can only be called by governance.
     * @param _newTradeFactory Address of new trade factory.
     */
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

    /**
     * @notice Use this to remove permissions from our current trade factory.
     * @dev Once this is called, setUpTradeFactory must be called to get things working again.
     * @param _disableTf Specify whether to disable the tradefactory when removing. Option given in case we need to get
     *  around a reverting disable.
     */
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
     *  If our profit exceeds our upper limit, then harvest no matter what. For our lower profit limit, credit
     *  threshold, max delay, and manual force trigger, only harvest if our gas price is acceptable.
     *
     * @param _callCostinEth The keeper's estimated gas cost to call harvest() (in wei).
     * @return True if harvest() should be called, false otherwise.
     */
    function harvestTrigger(
        uint256 _callCostinEth
    ) public view override returns (bool) {
        // Should not trigger if strategy is not active (no assets and no debtRatio). This means we don't need to adjust
        //  keeper job.
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

        // harvest if we have loose want in the strategy and are past our minDelay
        if (
            (balanceOfWant() > uint256(depositInfo.minDeposit)) &&
            (block.timestamp - params.lastReport > minReportDelay)
        ) {
            return true;
        }

        // otherwise, we don't harvest
        return false;
    }

    /**
     * @notice Calculates the profit if all claimable assets were sold for USDC (6 decimals).
     * @return Total return in USDC from selling claimable CRV, CVX, and FXS.
     */
    function claimableProfitInUsdc() public view returns (uint256) {
        (
            address[] memory _tokenAddresses,
            uint256[] memory _tokenAmounts
        ) = getEarnedTokens();

        uint256 tokensLength = _tokenAddresses.length;

        // occasionally we may have more than just FXS/CRV/CVX. however, FXS is always index 0,
        //  and CRV and CVX are always the last two
        (, uint256 indexZeroPrice, , , ) = IOracle(
            0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf
        ).latestRoundData(
                _tokenAddresses[0],
                address(0x0000000000000000000000000000000000000348) // USD, returns 1e8
            );

        (, uint256 indexOnePrice, , , ) = IOracle(
            0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf
        ).latestRoundData(
                _tokenAddresses[tokensLength - 2],
                address(0x0000000000000000000000000000000000000348) // USD, returns 1e8
            );

        (, uint256 indexTwoPrice, , , ) = IOracle(
            0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf
        ).latestRoundData(
                _tokenAddresses[tokensLength - 1],
                address(0x0000000000000000000000000000000000000348) // USD, returns 1e8
            );

        return
            (indexZeroPrice *
                _tokenAmounts[0] +
                indexOnePrice *
                _tokenAmounts[tokensLength - 2] +
                indexTwoPrice *
                _tokenAmounts[tokensLength - 1]) / 1e20;
    }

    /**
     * @notice Convert our keeper's eth cost into want
     * @dev We don't use this since we don't factor call cost into our harvestTrigger.
     * @param _ethAmount Amount of ether spent.
     * @return Value of ether in want.
     */
    function ethToWant(
        uint256 _ethAmount
    ) public view override returns (uint256) {}

    /* ========== FRAX-SPECIFIC FUNCTIONS ========== */

    /**
     * @notice Check how much want we have locked (not just deposited) in the staking contract.
     * @return stillLocked The total amount of want that cannot yet be withdrawn from the staking contract.
     */
    function stillLockedStake() public view returns (uint256 stillLocked) {
        IConvexFrax.LockedStake[] memory stakes = stakingAddress.lockedStakesOf(
            address(userVault)
        );

        // pull down our kek info
        uint256 _nextKek = uint256(kekInfo.nextKek);
        uint256 _maxKeks = uint256(kekInfo.maxKeks);

        IConvexFrax.LockedStake memory stake;
        uint256 time = block.timestamp;
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

    /**
     * @notice This function allows manual withdrawal of a specific kek.
     * @dev Available if the counter or loops fail.
     * @param _index Index of the kek to withdraw.
     */
    function manualWithdraw(uint256 _index) external onlyVaultManagers {
        userVault.withdrawLockedAndUnwrap(
            stakingAddress.lockedStakesOf(address(userVault))[_index].kek_id
        );
    }

    /* ========== SETTERS ========== */
    // These functions are useful for setting parameters of the strategy that may need to be adjusted.

    /**
     * @notice Changes the maximum amount of keks we can deposit into at once.
     * @dev Will withdraw funds if lowering the max. Ideally should harvest after adjusting to prevent loose funds
     *  sitting idle.
     * @param _newMaxKeks New number of maxKeks.
     */
    function setMaxKeks(uint256 _newMaxKeks) external onlyVaultManagers {
        require(_newMaxKeks > 0, "Must be >0");

        // pull down our kek info
        uint256 _nextKek = uint256(kekInfo.nextKek);
        uint256 _maxKeks = uint256(kekInfo.maxKeks);

        // If we are lowering the max we need to withdraw the diff,
        // but only if we are already over the new max
        if (_newMaxKeks < _maxKeks) {
            // this second if statement will likely only be false early on (unless we choose a massive newMaxKeks)
            if (_newMaxKeks < _nextKek) {
                uint256 toWithdraw = _nextKek > _maxKeks
                    ? _maxKeks - _newMaxKeks
                    : _nextKek - _newMaxKeks;
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
        kekInfo.maxKeks = uint128(_newMaxKeks);
    }

    /**
     * @notice Set the lower and upper bounds of our deposit size.
     * @dev Min prevents us from harvesting in dust for a kek, and max is how large we allow one kek to be. We use
     *  uint120 here to be able to more efficiently pack our struct
     * @param _minDeposit Minimum want needed to create a new kek.
     * @param _maxSingleDeposit Maximum size of a single kek.
     * @param _addToExistingKeks Whether new deposits go to an existing or new kek.
     */
    function setDepositParams(
        uint120 _minDeposit,
        uint120 _maxSingleDeposit,
        bool _addToExistingKeks
    ) external onlyVaultManagers {
        require(
            _maxSingleDeposit > _minDeposit,
            "Max must be greater than min"
        );
        depositInfo.minDeposit = _minDeposit;
        depositInfo.maxSingleDeposit = _maxSingleDeposit;
        depositInfo.addToExistingKeks = _addToExistingKeks;
    }

    /**
     * @notice This can be used to update how long the tokens are locked when staked.
     * @dev Care should be taken when increasing the time to only update directly before a harvest, otherwise timestamp
     *  checks when withdrawing could be inaccurate.
     * @param _lockTime Time to lock our LP (in seconds). By default bound to 1 week < t < 1 year.
     */
    function setLockTime(uint256 _lockTime) external onlyVaultManagers {
        require(
            stakingAddress.lock_time_min() <= _lockTime &&
                _lockTime <= stakingAddress.lock_time_for_max_multiplier(),
            "Disallowed by staking address"
        );
        lockTime = _lockTime;
    }

    /**
     * @notice Use this to set or update our keep amounts for this strategy.
     * @dev Must be less than 10,000. Set in basis points. Only governance can set this.
     * @param _keepCrv Percent of each CRV harvest to send to our voter.
     * @param _keepCvx Percent of each CVX harvest to send to our voter.
     * @param _keepFxs Percent of each FXS harvest to send to our voter.
     */
    function setLocalKeepCrvs(
        uint256 _keepCrv,
        uint256 _keepCvx,
        uint256 _keepFxs
    ) external onlyGovernance {
        if (_keepCrv > 10_000 || _keepCvx > 10_000 || _keepFxs > 10_000) {
            revert("Keep max is 10,000");
        }

        if (_keepCrv > 0 && curveVoter == address(0)) {
            revert("Set voter when keep >0");
        }

        if (_keepCvx > 0 && convexVoter == address(0)) {
            revert("Set voter when keep >0");
        }

        if (_keepFxs > 0 && fraxVoter == address(0)) {
            revert("Set voter when keep >0");
        }

        localKeepCRV = _keepCrv;
        localKeepCVX = _keepCvx;
        localKeepFXS = _keepFxs;
    }

    /**
     * @notice Use this to set or update our voter contracts.
     * @dev For Convex Frax strategies, this is simply where we send our keepCRV, keepCVX and keepFXS. Only governance
     *  can set this.
     * @param _curveVoter Address of our curve voter.
     * @param _convexVoter Address of our convex voter.
     * @param _convexFraxVoter Address of our frax voter.
     */
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