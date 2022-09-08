//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../external/IERC677Receiver.sol";
import "../external/IERC677Token.sol";
import "../lib/Utils.sol";
import "../upgrade/FsBase.sol";
import "./TokenLocker.sol";
import "./interfaces/ITradingFeeIncentives.sol";

contract TradingFeeIncentives is FsBase, ITradingFeeIncentives, IERC677Receiver {
    using SafeERC20 for IERC677Token;
    uint256 constant PERIOD = 1 days;

    /// @inheritdoc ITradingFeeIncentives
    IERC677Token public override rewardsToken;
    /// @inheritdoc ITradingFeeIncentives
    address public override tokenLocker;
    /// @inheritdoc ITradingFeeIncentives
    address public override feeUpdater;

    /// Fee's generate rewards only in the period they occur. Hence each
    /// period needs its own data struct to calculate the incentives for
    /// each fee in that period.
    struct PeriodData {
        uint256 totalShares;
        uint256 totalRewards;
    }

    mapping(uint256 => PeriodData) periodData;
    mapping(address => UserData) userDataByAddress;

    uint256 public rewardsLeft; // rewards left to distribute till endPeriod
    uint256 public endPeriod;

    struct AddRewards {
        // Used as parameter in onTokenTransfer
        uint256 periods;
    }

    struct UserData {
        uint256 lastUpdatedPeriod; // period the shares belong too.
        uint256 shares; // shares belonging to the period in periodData.
        uint256 accumulatedTokens;
    }

    /// @notice We allow `feeUpdater` to be `0`, as there is a cycle in the dependencies: exchange
    ///         points to the incentives contract and the incentives contract points back at the
    ///         exchange.  As we deploy one contract at a time one, we need one of them to point to
    ///         `0` during the initialization process.  It is not allowed for the `feeUpdater` to be
    ///         `0` after initialization is complete.
    function initialize(
        address _tokenLocker,
        address _rewardsToken,
        address _feeUpdater
    ) external initializer {
        // slither-disable-next-line missing-zero-check
        tokenLocker = nonNull(_tokenLocker, "tokenLocker is zero");
        // slither-disable-next-line missing-zero-check
        rewardsToken = IERC677Token(nonNull(_rewardsToken, "rewardsToken is zero"));
        // See function level comment as to why this can be `0`.
        // slither-disable-next-line missing-zero-check
        feeUpdater = _feeUpdater;
        initializeFsOwnable();
    }

    function addFee(address user, uint256 amount) external override {
        require(msg.sender == feeUpdater, "Only fee updater");

        uint256 currentPeriod = getCurrentPeriod();

        if (currentPeriod >= endPeriod) {
            return;
        }

        UserData memory userData = userDataByAddress[user];

        update(userData, currentPeriod);

        uint256 totalShares = periodData[currentPeriod].totalShares;
        if (totalShares == 0) {
            // This is the first fee added this day, initialize periodData.
            if (rewardsLeft == 0) return;
            uint256 rewardsPerPeriod = rewardsLeft / (endPeriod - currentPeriod);
            periodData[currentPeriod].totalRewards = rewardsPerPeriod;
            rewardsLeft -= rewardsPerPeriod;
        }
        userData.shares += amount;
        periodData[currentPeriod].totalShares = totalShares + amount;

        userDataByAddress[user] = userData;

        emit FeeAdded(user, amount, userData.accumulatedTokens, userData.shares);
    }

    function claim(uint256 _lockupTime) external {
        uint256 currentPeriod = getCurrentPeriod();
        UserData memory userData = userDataByAddress[msg.sender];
        update(userData, currentPeriod);

        uint256 amount = userData.accumulatedTokens;
        require(amount > 0, "No reward");
        userData.accumulatedTokens = 0;
        userDataByAddress[msg.sender] = userData;

        // If there is no lockup time, send the tokens directly to the user.
        if (TokenLocker(tokenLocker).maxLockupTime() == 0) {
            rewardsToken.safeTransfer(msg.sender, amount);
            return;
        }

        // slither-disable-next-line uninitialized-local
        TokenLocker.AddLockup memory al;
        al.lockupTime = _lockupTime;
        al.receiver = msg.sender;

        // `TokenLocker` either reverts or returns `true`, so it should be OK to ignore the return
        // value here.  We should probably change this to `require(...transferAndCall(...))` should
        // we be updating this code, just to be safe.
        // slither-disable-next-line unused-return
        rewardsToken.transferAndCall(tokenLocker, amount, abi.encode(al));
    }

    function onTokenTransfer(
        address _from,
        uint256 _amount,
        bytes calldata _data
    ) external override returns (bool success) {
        require(msg.sender == address(rewardsToken), "wrong token");
        require(_from == owner(), "Only owner");

        AddRewards memory ar = abi.decode(_data, (AddRewards));

        // Some numbers
        require(ar.periods < 120, "period too long");

        uint256 currentPeriod = getCurrentPeriod();
        uint256 newEndPeriod = Math.max(endPeriod, currentPeriod + ar.periods);
        endPeriod = newEndPeriod;
        rewardsLeft += _amount;

        emit RewardsAdded(_amount, rewardsLeft, currentPeriod, newEndPeriod);

        return true;
    }

    /// @notice Ends rewards after the current ongoing period and refunds
    ///         extra tokens to the owner.
    function endRewardsAndRefund() external onlyOwner {
        uint256 currentPeriod = getCurrentPeriod();
        endPeriod = currentPeriod;
        uint256 refund = rewardsLeft;
        rewardsLeft = 0;

        emit RewardsEnded(refund, currentPeriod);

        if (refund > 0) {
            rewardsToken.safeTransfer(msg.sender, refund);
        }
    }

    function setFeeUpdater(address _feeUpdater) external onlyOwner {
        if (_feeUpdater == feeUpdater) {
            return;
        }

        emit FeeUpdaterChanged(feeUpdater, _feeUpdater);
        // slither-disable-next-line missing-zero-check
        feeUpdater = nonNull(_feeUpdater, "New feeUpdater is zero");
    }

    /// @inheritdoc ITradingFeeIncentives
    function periodLength() external pure override returns (uint256) {
        return PERIOD;
    }

    /// @inheritdoc ITradingFeeIncentives
    function currentPeriodRewards() external view override returns (uint256) {
        uint256 currentPeriod = getCurrentPeriod();

        if (currentPeriod >= endPeriod) {
            return 0;
        }

        uint256 totalShares = periodData[currentPeriod].totalShares;
        if (totalShares == 0) {
            return rewardsLeft / (endPeriod - currentPeriod);
        } else {
            return periodData[currentPeriod].totalRewards;
        }
    }

    /// @inheritdoc ITradingFeeIncentives
    function getClaimableTokens(address _account) external view override returns (uint256) {
        uint256 currentPeriod = getCurrentPeriod();

        UserData memory userData = userDataByAddress[_account];

        uint256 tokens = userData.accumulatedTokens;
        if (userData.lastUpdatedPeriod < currentPeriod && userData.shares > 0) {
            PeriodData memory pData = periodData[userData.lastUpdatedPeriod];

            tokens += (pData.totalRewards * userData.shares) / pData.totalShares;
        }
        return tokens;
    }

    function getCurrentPeriod() private view returns (uint256) {
        return getTime() / PERIOD;
    }

    function update(UserData memory userData, uint256 currentPeriod) private {
        // Checks if the user's last vesting period is lower than the current period
        // and if so vests the old period
        if (userData.lastUpdatedPeriod < currentPeriod && userData.shares > 0) {
            PeriodData memory pData = periodData[userData.lastUpdatedPeriod];

            uint256 tokens = (pData.totalRewards * userData.shares) / pData.totalShares;
            pData.totalRewards -= tokens;
            userData.accumulatedTokens += tokens;
            pData.totalShares -= userData.shares;
            userData.shares = 0;
            periodData[userData.lastUpdatedPeriod] = pData;
        }
        userData.lastUpdatedPeriod = currentPeriod;
    }

    function setRewardsToken(address newRewardsToken) external onlyOwner {
        if (newRewardsToken == address(rewardsToken)) {
            return;
        }
        address oldRewardsToken = address(rewardsToken);
        rewardsToken = IERC677Token(FsUtils.nonNull(newRewardsToken));
        emit RewardsTokenUpdated(oldRewardsToken, newRewardsToken);
    }

    // Present so we can override in unit tests
    // Not really sure why Slither detects this as dead code.  It is used in a number of other
    // functions in this contract.  Maybe it is the `virtual` that is confusing it.
    // slither-disable-next-line dead-code
    function getTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}