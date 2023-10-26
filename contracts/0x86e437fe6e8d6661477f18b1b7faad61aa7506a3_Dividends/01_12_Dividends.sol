// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./interfaces/IDividends.sol";

/*
 * This contract is used to distribute dividends to users that allocated esToken here
 *
 * Dividends can be distributed in the form of one or more tokens
 * They are mainly managed to be received from the FeeManager contract, but other sources can be added (dev wallet for instance)
 *
 * The freshly received dividends are stored in a pending slot
 *
 * The content of this pending slot will be progressively transferred over time into a distribution slot
 * This distribution slot is the source of the dividends distribution to esToken allocators during the current cycle
 *
 * This transfer from the pending slot to the distribution slot is based on cycleDividendsPercent and CYCLE_PERIOD_SECONDS
 *
 */
contract Dividends is OwnableUpgradeable, ReentrancyGuardUpgradeable, IDividends {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct UserInfo {
        uint256 pendingDividends;
        uint256 rewardDebt;
    }

    struct DividendsInfo {
        uint256 currentDistributionAmount; // total amount to distribute during the current cycle
        uint256 currentCycleDistributedAmount; // amount already distributed for the current cycle (times 1e2)
        uint256 pendingAmount; // total amount in the pending slot, not distributed yet
        uint256 distributedAmount; // total amount that has been distributed since initialization
        uint256 accDividendsPerShare; // accumulated dividends per share (times 1e18)
        uint256 lastUpdateTime; // last time the dividends distribution occurred
        uint256 cycleDividendsPercent; // fixed part of the pending dividends to assign to currentDistributionAmount on every cycle
        bool distributionDisabled; // deactivate a token distribution (for temporary dividends)
    }

    // actively distributed tokens
    EnumerableSetUpgradeable.AddressSet private _distributedTokens;
    uint256 public constant MAX_DISTRIBUTED_TOKENS = 10;

    // dividends info for every dividends token
    mapping(address => DividendsInfo) public dividendsInfo;
    mapping(address => mapping(address => UserInfo)) public users;

    address public esToken; // esToken contract

    mapping(address => uint256) public usersAllocation; // User's esToken allocation
    uint256 public totalAllocation; // Contract's total esToken allocation

    uint256 public constant MIN_CYCLE_DIVIDENDS_PERCENT = 1; // 0.01%
    uint256 public constant DEFAULT_CYCLE_DIVIDENDS_PERCENT = 100; // 1%
    uint256 public constant MAX_CYCLE_DIVIDENDS_PERCENT = 10000; // 100%
    // dividends will be added to the currentDistributionAmount on each new cycle
    uint256 public constant CYCLE_DURATION_SECONDS = 7 days;
    uint256 public currentCycleStartTime;

    function initialize(address _esToken, uint256 startTime_) public initializer {
        // DVD_ZA: zero address
        require(_esToken != address(0), "DVD_ZA");

        __Ownable_init();
        __ReentrancyGuard_init();

        esToken = _esToken;
        currentCycleStartTime = startTime_;
    }

    /********************************************/
    /****************** EVENTS ******************/
    /********************************************/

    event UserUpdated(address indexed user, uint256 previousBalance, uint256 newBalance);
    event DividendsCollected(address indexed user, address indexed token, uint256 amount);
    event CycleDividendsPercentUpdated(address indexed token, uint256 previousValue, uint256 newValue);
    event DividendsAddedToPending(address indexed token, uint256 amount);
    event DistributedTokenDisabled(address indexed token);
    event DistributedTokenRemoved(address indexed token);
    event DistributedTokenEnabled(address indexed token);

    /***********************************************/
    /****************** MODIFIERS ******************/
    /***********************************************/

    /**
     * @dev Checks if an index exists
     */
    modifier validateDistributedTokensIndex(uint256 index) {
        // DVD_INE: index does not exists
        require(index < _distributedTokens.length(), "DVD_INE");
        _;
    }

    /**
     * @dev Checks if token exists
     */
    modifier validateDistributedToken(address token) {
        // DVD_TNE: token does not exists
        require(_distributedTokens.contains(token), "DVD_TNE");
        _;
    }

    /**
     * @dev Checks if caller is the esToken contract
     */
    modifier esTokenOnly() {
        // DVD_OEST: only EsToken
        require(msg.sender == esToken, "DVD_OEST");
        _;
    }

    /*******************************************/
    /****************** VIEWS ******************/
    /*******************************************/

    function cycleDurationSeconds() external pure returns (uint256) {
        return CYCLE_DURATION_SECONDS;
    }

    /**
     * @dev Returns the number of dividends tokens
     */
    function distributedTokensLength() external view returns (uint256) {
        return _distributedTokens.length();
    }

    /**
     * @dev Returns dividends token address from given index
     */
    function distributedToken(uint256 index) external view validateDistributedTokensIndex(index) returns (address) {
        return address(_distributedTokens.at(index));
    }

    /**
     * @dev Returns true if given token is a dividends token
     */
    function isDistributedToken(address token) external view returns (bool) {
        return _distributedTokens.contains(token);
    }

    /**
     * @dev Returns time at which the next cycle will start
     */
    function nextCycleStartTime() public view returns (uint256) {
        return currentCycleStartTime.add(CYCLE_DURATION_SECONDS);
    }

    /**
     * @dev Returns user's dividends pending amount for a given token
     */
    function pendingDividendsAmount(address token, address userAddress) external view returns (uint256) {
        if (totalAllocation == 0) {
            return 0;
        }

        DividendsInfo storage dividendsInfo_ = dividendsInfo[token];

        uint256 accDividendsPerShare = dividendsInfo_.accDividendsPerShare;
        uint256 lastUpdateTime = dividendsInfo_.lastUpdateTime;
        uint256 dividendAmountPerSecond_ = _dividendsAmountPerSecond(token);

        // check if the current cycle has changed since last update
        if (_currentBlockTimestamp() > nextCycleStartTime()) {
            // get remaining rewards from last cycle
            accDividendsPerShare = accDividendsPerShare.add(
                (nextCycleStartTime().sub(lastUpdateTime)).mul(dividendAmountPerSecond_).mul(1e16).div(totalAllocation)
            );
            lastUpdateTime = nextCycleStartTime();
            dividendAmountPerSecond_ = dividendsInfo_
                .pendingAmount
                .mul(dividendsInfo_.cycleDividendsPercent)
                .div(100)
                .div(CYCLE_DURATION_SECONDS);
        }

        // get pending rewards from current cycle
        accDividendsPerShare = accDividendsPerShare.add(
            (_currentBlockTimestamp().sub(lastUpdateTime)).mul(dividendAmountPerSecond_).mul(1e16).div(totalAllocation)
        );

        return
            usersAllocation[userAddress]
                .mul(accDividendsPerShare)
                .div(1e18)
                .sub(users[token][userAddress].rewardDebt)
                .add(users[token][userAddress].pendingDividends);
    }

    /**************************************************/
    /****************** PUBLIC FUNCTIONS **************/
    /**************************************************/

    /**
     * @dev Updates the current cycle start time if previous cycle has ended
     */
    function updateCurrentCycleStartTime() public {
        uint256 nextCycleStartTime_ = nextCycleStartTime();

        if (_currentBlockTimestamp() >= nextCycleStartTime_) {
            currentCycleStartTime = nextCycleStartTime_;
        }
    }

    /**
     * @dev Updates dividends info for a given token
     */
    function updateDividendsInfo(address token) external validateDistributedToken(token) {
        _updateDividendsInfo(token);
    }

    /****************************************************************/
    /****************** EXTERNAL PUBLIC FUNCTIONS  ******************/
    /****************************************************************/

    /**
     * @dev Updates all dividendsInfo
     */
    function massUpdateDividendsInfo() external {
        uint256 length = _distributedTokens.length();
        for (uint256 index = 0; index < length; ++index) {
            _updateDividendsInfo(_distributedTokens.at(index));
        }
    }

    /**
     * @dev Harvests caller's pending dividends of a given token
     */
    function harvestDividends(address token) external nonReentrant {
        if (!_distributedTokens.contains(token)) {
            // DVD_IT: invalid token
            require(dividendsInfo[token].distributedAmount > 0, "DVD_IT");
        }

        _harvestDividends(token);
    }

    /**
     * @dev Harvests all caller's pending dividends
     */
    function harvestAllDividends() external nonReentrant {
        uint256 length = _distributedTokens.length();
        for (uint256 index = 0; index < length; ++index) {
            _harvestDividends(_distributedTokens.at(index));
        }
    }

    /**
     * @dev Transfers the given amount of token from caller to pendingAmount
     *
     * Must only be called by a trustable address
     */
    function addDividendsToPending(address token, uint256 amount) external nonReentrant {
        uint256 prevTokenBalance = IERC20Upgradeable(token).balanceOf(address(this));
        DividendsInfo storage dividendsInfo_ = dividendsInfo[token];

        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);

        // handle tokens with transfer tax
        uint256 receivedAmount = IERC20Upgradeable(token).balanceOf(address(this)).sub(prevTokenBalance);
        dividendsInfo_.pendingAmount = dividendsInfo_.pendingAmount.add(receivedAmount);

        emit DividendsAddedToPending(token, receivedAmount);
    }

    /**
     * @dev Emergency withdraw token's balance on the contract
     */
    function emergencyWithdraw(IERC20Upgradeable token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        // DVD_TBN: token balance is null
        require(balance > 0, "DVD_TBN");
        _safeTokenTransfer(token, msg.sender, balance);
    }

    /**
     * @dev Emergency withdraw all dividend tokens' balances on the contract
     */
    function emergencyWithdrawAll() external onlyOwner {
        for (uint256 index = 0; index < _distributedTokens.length(); ++index) {
            emergencyWithdraw(IERC20Upgradeable(_distributedTokens.at(index)));
        }
    }

    /****************************************************************/
    /*********************** OWNABLE FUNCTIONS  *********************/
    /****************************************************************/

    /**
     * Allocates "userAddress" user's "amount" of esToken to this dividends contract
     *
     * Can only be called by esToken contract, which is trusted to verify amounts
     */
    function allocate(address userAddress, uint256 amount) external override nonReentrant esTokenOnly {
        uint256 newUserAllocation = usersAllocation[userAddress].add(amount);
        uint256 newTotalAllocation = totalAllocation.add(amount);
        _updateUser(userAddress, newUserAllocation, newTotalAllocation);
    }

    /**
     * Deallocates "userAddress" user's "amount" of esToken allocation from this dividends contract
     *
     * Can only be called by esToken contract, which is trusted to verify amounts
     */
    function deallocate(address userAddress, uint256 amount) external override nonReentrant esTokenOnly {
        uint256 newUserAllocation = usersAllocation[userAddress].sub(amount);
        uint256 newTotalAllocation = totalAllocation.sub(amount);
        _updateUser(userAddress, newUserAllocation, newTotalAllocation);
    }

    /**
     * @dev Enables a given token to be distributed as dividends
     *
     * Effective from the next cycle
     */
    function enableDistributedToken(address token) external onlyOwner {
        DividendsInfo storage dividendsInfo_ = dividendsInfo[token];
        // DVD_AET: Already enabled token
        require(dividendsInfo_.lastUpdateTime == 0 || dividendsInfo_.distributionDisabled, "DVD_AET");
        // DVD_TMT: too many distributedTokens
        require(_distributedTokens.length() < MAX_DISTRIBUTED_TOKENS, "DVD_TMT");
        // initialize lastUpdateTime if never set before
        if (dividendsInfo_.lastUpdateTime == 0) {
            dividendsInfo_.lastUpdateTime = _currentBlockTimestamp();
        }
        // initialize cycleDividendsPercent to the minimum if never set before
        if (dividendsInfo_.cycleDividendsPercent == 0) {
            dividendsInfo_.cycleDividendsPercent = DEFAULT_CYCLE_DIVIDENDS_PERCENT;
        }
        dividendsInfo_.distributionDisabled = false;
        _distributedTokens.add(token);
        emit DistributedTokenEnabled(token);
    }

    /**
     * @dev Disables distribution of a given token as dividends
     *
     * Effective from the next cycle
     */
    function disableDistributedToken(address token) external onlyOwner {
        DividendsInfo storage dividendsInfo_ = dividendsInfo[token];
        // DVD_ADT : already disabled token
        require(dividendsInfo_.lastUpdateTime > 0 && !dividendsInfo_.distributionDisabled, "DVD_ADT");
        dividendsInfo_.distributionDisabled = true;
        emit DistributedTokenDisabled(token);
    }

    /**
     * @dev Updates the percentage of pending dividends that will be distributed during the next cycle
     *
     * Must be a value between MIN_CYCLE_DIVIDENDS_PERCENT and MAX_CYCLE_DIVIDENDS_PERCENT
     */
    function updateCycleDividendsPercent(address token, uint256 percent) external onlyOwner {
        // DVD_PEMAX: percent exceed maximum
        require(percent <= MAX_CYCLE_DIVIDENDS_PERCENT, "DVD_PEMAX");
        // DVD_PEMIN: percent exceed minimum
        require(percent >= MIN_CYCLE_DIVIDENDS_PERCENT, "DVD_PEMIN");
        DividendsInfo storage dividendsInfo_ = dividendsInfo[token];
        uint256 previousPercent = dividendsInfo_.cycleDividendsPercent;
        dividendsInfo_.cycleDividendsPercent = percent;
        emit CycleDividendsPercentUpdated(token, previousPercent, dividendsInfo_.cycleDividendsPercent);
    }

    /**
     * @dev remove an address from _distributedTokens
     *
     * Can only be valid for a disabled dividends token and if the distribution has ended
     */
    function removeTokenFromDistributedTokens(address tokenToRemove) external onlyOwner {
        DividendsInfo storage _dividendsInfo = dividendsInfo[tokenToRemove];
        // DVD_CNR: can not be removed
        require(_dividendsInfo.distributionDisabled && _dividendsInfo.currentDistributionAmount == 0, "DVD_CNR");
        _distributedTokens.remove(tokenToRemove);
        emit DistributedTokenRemoved(tokenToRemove);
    }

    /********************************************************/
    /****************** INTERNAL FUNCTIONS ******************/
    /********************************************************/

    /**
     * @dev Returns the amount of dividends token distributed every second (times 1e2)
     */
    function _dividendsAmountPerSecond(address token) internal view returns (uint256) {
        if (!_distributedTokens.contains(token)) return 0;
        return dividendsInfo[token].currentDistributionAmount.mul(1e2).div(CYCLE_DURATION_SECONDS);
    }

    /**
     * @dev Updates every user's rewards allocation for each distributed token
     */
    function _updateDividendsInfo(address token) internal {
        uint256 currentBlockTimestamp = _currentBlockTimestamp();
        DividendsInfo storage dividendsInfo_ = dividendsInfo[token];

        updateCurrentCycleStartTime();

        uint256 lastUpdateTime = dividendsInfo_.lastUpdateTime;
        uint256 accDividendsPerShare = dividendsInfo_.accDividendsPerShare;
        if (currentBlockTimestamp <= lastUpdateTime) {
            return;
        }

        // if no esToken is allocated or initial distribution has not started yet
        if (totalAllocation == 0 || currentBlockTimestamp < currentCycleStartTime) {
            dividendsInfo_.lastUpdateTime = currentBlockTimestamp;
            return;
        }

        uint256 currentDistributionAmount = dividendsInfo_.currentDistributionAmount; // gas saving
        uint256 currentCycleDistributedAmount = dividendsInfo_.currentCycleDistributedAmount; // gas saving

        // check if the current cycle has changed since last update
        if (lastUpdateTime < currentCycleStartTime) {
            // update accDividendPerShare for the end of the previous cycle
            accDividendsPerShare = accDividendsPerShare.add(
                (currentDistributionAmount.mul(1e2).sub(currentCycleDistributedAmount)).mul(1e16).div(totalAllocation)
            );

            // check if distribution is enabled
            if (!dividendsInfo_.distributionDisabled) {
                // transfer the token's cycleDividendsPercent part from the pending slot to the distribution slot
                dividendsInfo_.distributedAmount = dividendsInfo_.distributedAmount.add(currentDistributionAmount);

                uint256 pendingAmount = dividendsInfo_.pendingAmount;
                currentDistributionAmount = pendingAmount.mul(dividendsInfo_.cycleDividendsPercent).div(10000);
                dividendsInfo_.currentDistributionAmount = currentDistributionAmount;
                dividendsInfo_.pendingAmount = pendingAmount.sub(currentDistributionAmount);
            } else {
                // stop the token's distribution on next cycle
                dividendsInfo_.distributedAmount = dividendsInfo_.distributedAmount.add(currentDistributionAmount);
                currentDistributionAmount = 0;
                dividendsInfo_.currentDistributionAmount = 0;
            }

            currentCycleDistributedAmount = 0;
            lastUpdateTime = currentCycleStartTime;
        }

        uint256 toDistribute = (currentBlockTimestamp.sub(lastUpdateTime)).mul(_dividendsAmountPerSecond(token));
        // ensure that we can't distribute more than currentDistributionAmount (for instance w/ a > 24h service interruption)
        if (currentCycleDistributedAmount.add(toDistribute) > currentDistributionAmount.mul(1e2)) {
            toDistribute = currentDistributionAmount.mul(1e2).sub(currentCycleDistributedAmount);
        }

        dividendsInfo_.currentCycleDistributedAmount = currentCycleDistributedAmount.add(toDistribute);
        dividendsInfo_.accDividendsPerShare = accDividendsPerShare.add(toDistribute.mul(1e16).div(totalAllocation));
        dividendsInfo_.lastUpdateTime = currentBlockTimestamp;
    }

    /**
     * Updates "userAddress" user's and total allocations for each distributed token
     */
    function _updateUser(address userAddress, uint256 newUserAllocation, uint256 newTotalAllocation) internal {
        uint256 previousUserAllocation = usersAllocation[userAddress];

        // for each distributedToken
        uint256 length = _distributedTokens.length();
        for (uint256 index = 0; index < length; ++index) {
            address token = _distributedTokens.at(index);
            _updateDividendsInfo(token);

            UserInfo storage user = users[token][userAddress];
            uint256 accDividendsPerShare = dividendsInfo[token].accDividendsPerShare;

            uint256 pending = previousUserAllocation.mul(accDividendsPerShare).div(1e18).sub(user.rewardDebt);
            user.pendingDividends = user.pendingDividends.add(pending);
            user.rewardDebt = newUserAllocation.mul(accDividendsPerShare).div(1e18);
        }

        usersAllocation[userAddress] = newUserAllocation;
        totalAllocation = newTotalAllocation;

        emit UserUpdated(userAddress, previousUserAllocation, newUserAllocation);
    }

    /**
     * @dev Harvests msg.sender's pending dividends of a given token
     */
    function _harvestDividends(address token) internal {
        _updateDividendsInfo(token);

        UserInfo storage user = users[token][msg.sender];
        uint256 accDividendsPerShare = dividendsInfo[token].accDividendsPerShare;

        uint256 userEsTokenAllocation = usersAllocation[msg.sender];
        uint256 pending = user.pendingDividends.add(
            userEsTokenAllocation.mul(accDividendsPerShare).div(1e18).sub(user.rewardDebt)
        );

        user.pendingDividends = 0;
        user.rewardDebt = userEsTokenAllocation.mul(accDividendsPerShare).div(1e18);

        _safeTokenTransfer(IERC20Upgradeable(token), msg.sender, pending);
        emit DividendsCollected(msg.sender, token, pending);
    }

    /**
     * @dev Safe token transfer function, in case rounding error causes pool to not have enough tokens
     */
    function _safeTokenTransfer(IERC20Upgradeable token, address to, uint256 amount) internal {
        if (amount > 0) {
            uint256 tokenBal = token.balanceOf(address(this));
            if (amount > tokenBal) {
                token.safeTransfer(to, tokenBal);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    /**
     * @dev Utility function to get the current block timestamp
     */
    function _currentBlockTimestamp() internal view virtual returns (uint256) {
        /* solhint-disable not-rely-on-time */
        return block.timestamp;
    }
}