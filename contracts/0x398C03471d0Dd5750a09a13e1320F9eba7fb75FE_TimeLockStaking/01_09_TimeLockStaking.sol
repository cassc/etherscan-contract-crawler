// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./OwnPauseAuth.sol";

contract TimeLockStaking is OwnPauseAuth, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ERC20 token for staking
    IERC20 public token;

    // Campaign Name
    string public name;

    // Locking timelock (in second) after that possible to claim
    uint256 public timelock;

    // Annual Percentage Rate
    uint256 public apr;

    // Max allowable tokens for deposit
    uint256 public maxCap;

    // Campaign expiry time (in second) after that impossible to deposit
    uint256 public expiryTime;

    uint256 public minTokensPerDeposit;

    uint256 public maxTokensPerDeposit;

    // Total amount of deposited and reward tokens that have already been paid out
    uint256 public totalPayout;

    // Total amount of reward tokens
    uint256 public totalRewardTokens;

    uint256 public totalDepositedTokens;

    bool public isMaxCapReached = false;

    struct DepositInfo {
        uint256 seq;
        uint256 amount;
        uint256 reward;
        bool isPaidOut;
        uint256 unlockTime;
    }

    mapping(address => DepositInfo[]) public stakingList;

    event Deposited(
        address indexed sender,
        uint256 seq,
        uint256 amount,
        uint256 timestamp
    );

    event Claimed(
        address indexed sender,
        uint256 seq,
        uint256 amount,
        uint256 reward,
        uint256 timestamp
    );

    event OwnerClaimed(address indexed sender, uint256 _remainingReward, address _to);
    event OwnerWithdrawn(address indexed sender, uint256 _amount, address _to);
    event OwnerWithdrawnAll(address indexed sender, uint256 _amount, address _to);

    event EvtSetName(string _name);
    event EvtSetTimelock(uint256 _timelock);
    event EvtSetAPR(uint256 _apr);
    event EvtSetMaxCap(uint256 _maxCap);
    event EvtSetExpiryTime(uint256 _expiryTime);
    event EvtSetMinTokensPerDeposit(uint256 _minTokensPerDeposit);
    event EvtSetMaxTokensPerDeposit(uint256 _maxTokensPerDeposit);

    constructor(
        IERC20 _token,
        string memory _campaignName,
        uint256 _expiryTime, // set to zero to disable expiry
        uint256 _maxCap,
        uint256 _maxTokensPerDeposit,
        uint256 _minTokensPerDeposit,
        uint256 _timelock,
        uint256 _apr
    ) {
        token = _token;
        name = _campaignName;

        if (_expiryTime > 0) {
            expiryTime = block.timestamp + _expiryTime;
        }

        maxCap = _maxCap;
        maxTokensPerDeposit = _maxTokensPerDeposit;
        minTokensPerDeposit = _minTokensPerDeposit;
        timelock = _timelock;
        apr = _apr;
    }

    function deposit(uint256 _amountIn) external whenNotPaused nonReentrant {
        require(isMaxCapReached == false, "TimeLockStaking: Max cap reached");

        uint256 _amount;
        if (totalDepositedTokens + _amountIn <= maxCap) {
            _amount = _amountIn;
        } else {
            isMaxCapReached = true;
            _amount = maxCap - totalDepositedTokens;
        }

        require(
            _amount >= minTokensPerDeposit,
            "TimeLockStaking: Depositing amount smaller than minTokensPerDeposit"
        );
        require(
            _amount <= maxTokensPerDeposit,
            "TimeLockStaking: Depositing amount larger than maxTokensPerDeposit"
        );
        require(
            expiryTime == 0 || block.timestamp < expiryTime,
            "TimeLockStaking: Campaign over"
        );

        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 unlockTime = block.timestamp + timelock;
        uint256 seq = stakingList[msg.sender].length + 1;
        uint256 reward = (_amount * apr * timelock) /
            (365 * 24 * 60 * 60 * 100);

        DepositInfo memory staking = DepositInfo(
            seq,
            _amount,
            reward,
            false,
            unlockTime
        );
        stakingList[msg.sender].push(staking);

        totalDepositedTokens += _amount;
        totalRewardTokens += reward;

        emit Deposited(msg.sender, seq, _amount, block.timestamp);
    }

    function claim(uint256 _seq) external whenNotPaused nonReentrant {
        DepositInfo[] memory userStakings = stakingList[msg.sender];
        require(
            _seq > 0 && userStakings.length >= _seq,
            "TimeLockStaking: Invalid seq"
        );

        uint256 idx = _seq - 1;

        DepositInfo memory staking = userStakings[idx];

        require(!staking.isPaidOut, "TimeLockStaking: Already paid out");
        require(
            staking.unlockTime <= block.timestamp,
            "TimeLockStaking: Staking still locked"
        );

        uint256 payout = staking.amount + staking.reward;

        token.safeTransfer(msg.sender, payout);
        totalPayout += payout;

        stakingList[msg.sender][idx].isPaidOut = true;

        emit Claimed(
            msg.sender,
            _seq,
            staking.amount,
            staking.reward,
            block.timestamp
        );
    }

    // Get the total tokens that still need to be paid out (including deposited tokens and reward tokens)
    function getRemainingPayout() public view returns (uint256) {
        uint256 remainingPayoutAmount = totalDepositedTokens +
            totalRewardTokens -
            totalPayout;
        return remainingPayoutAmount;
    }

    // Get the token balance of this contract
    function getTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // Get the total tokens that still need to be rewarded
    function getRemainingReward() public view returns (uint256) {
        uint256 remainingPayoutAmount = getRemainingPayout();
        uint256 balance = getTokenBalance();
        return balance - remainingPayoutAmount;
    }

    // Owner can withdraw all remaining reward tokens
    function ownerClaimRemainingReward(address _to)
        external
        isOwner
        nonReentrant
    {
        require(
            block.timestamp > expiryTime,
            "TimeLockStaking: Campaign not yet expired"
        );

        uint256 remainingReward = getRemainingReward();
        token.safeTransfer(_to, remainingReward);

        emit OwnerClaimed(msg.sender, remainingReward, _to);
    }

    // Owner can withdraw a specified amount of tokens
    function ownerWithdraw(address _to, uint256 _amount)
        external
        isOwner
        nonReentrant
    {
        token.safeTransfer(_to, _amount);

        emit OwnerWithdrawn(msg.sender, _amount, _to);
    }

    // Owner can withdraw all tokens
    function ownerWithdrawAll(address _to) external isOwner nonReentrant {
        uint256 tokenBal = getTokenBalance();
        token.safeTransfer(_to, tokenBal);

        emit OwnerWithdrawnAll(msg.sender, tokenBal, _to);
    }

    function setName(string memory _name) external isAuthorized {
        name = _name;
        emit EvtSetName(_name);
    }

    function setTimelock(uint256 _timelock) external isAuthorized {
        timelock = _timelock;
        emit EvtSetTimelock(_timelock);
    }

    function setAPR(uint256 _apr) external isAuthorized {
        apr = _apr;
        emit EvtSetAPR(_apr);
    }

    function setMaxCap(uint256 _maxCap) external isAuthorized {
        maxCap = _maxCap;
        isMaxCapReached = false;
        emit EvtSetMaxCap(_maxCap);
    }

    function setExpiryTime(uint256 _expiryTime) external isAuthorized {
        expiryTime = _expiryTime;
        emit EvtSetExpiryTime(_expiryTime);
    }

    function setMinTokensPerDeposit(uint256 _minTokensPerDeposit)
        external
        isAuthorized
    {
        minTokensPerDeposit = _minTokensPerDeposit;
        emit EvtSetMinTokensPerDeposit(_minTokensPerDeposit);
    }

    function setMaxTokensPerDeposit(uint256 _maxTokensPerDeposit)
        external
        isAuthorized
    {
        maxTokensPerDeposit = _maxTokensPerDeposit;
        emit EvtSetMaxTokensPerDeposit(_maxTokensPerDeposit);
    }

    function getCampaignInfo()
        external
        view
        returns (
            IERC20 _token,
            string memory _campaignName,
            uint256 _expiryTime,
            uint256 _maxCap,
            uint256 _maxTokensPerDeposit,
            uint256 _minTokensPerDeposit,
            uint256 _timelock,
            uint256 _apr,
            uint256 _totalDepositedTokens,
            uint256 _totalPayout
        )
    {
        return (
            token,
            name,
            expiryTime,
            maxCap,
            maxTokensPerDeposit,
            minTokensPerDeposit,
            timelock,
            apr,
            totalDepositedTokens,
            totalPayout
        );
    }

    function getStakings(address _staker)
        external
        view
        returns (
            uint256[] memory _seqs,
            uint256[] memory _amounts,
            uint256[] memory _rewards,
            bool[] memory _isPaidOuts,
            uint256[] memory _timestamps
        )
    {
        DepositInfo[] memory userStakings = stakingList[_staker];

        uint256 length = userStakings.length;

        uint256[] memory seqList = new uint256[](length);
        uint256[] memory amountList = new uint256[](length);
        uint256[] memory rewardList = new uint256[](length);
        bool[] memory isPaidOutList = new bool[](length);
        uint256[] memory timeList = new uint256[](length);

        for (uint256 idx = 0; idx < length; idx++) {
            DepositInfo memory stakingInfo = userStakings[idx];

            seqList[idx] = stakingInfo.seq;
            amountList[idx] = stakingInfo.amount;
            rewardList[idx] = stakingInfo.reward;
            isPaidOutList[idx] = stakingInfo.isPaidOut;
            timeList[idx] = stakingInfo.unlockTime;
        }

        return (seqList, amountList, rewardList, isPaidOutList, timeList);
    }
}