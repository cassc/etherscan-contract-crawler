// SPDX-License-Identifier:MIT
pragma solidity ^0.8.13;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AHTStaking is Pausable, Ownable, AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant DELEGATE_ROLE = keccak256("DELEGATE_ROLE");

    struct Staker {
        uint256 timestamp;
        uint256 amount;
        uint256 interestRate;
        uint256 unclaimedRewards;
        uint256 length;
    }

    struct StakeEntry {
        address stakerAddress;
        uint256 stakeId;
    }

    mapping(address => Staker) public stakers;

    EnumerableSet.AddressSet private users;

    StakeEntry[] public stakesList;

    mapping(address => uint256) public lastClaimedTime;

    IERC20 public token;
    address public tokenAddress;

    //18 Percent per year
    uint256 public interestRate; //18 Percent
    uint256 public lockPeriod; // = 1 days; //365 days;
    uint256 public minimumStakeAmount = 10000000000000000000;

    uint256 public rewardsPoolBalance;
    uint256 public totalStakedBalance; //without interests

    mapping(address => uint256) public totalEarnedTokens;
    uint256 public totalClaimedRewards = 0;

    event LiquidityDeposited(address indexed stakerAddress, uint256 amount);

    event LiquidityWithdrawn(address indexed stakerAddress, uint256 amount);

    event InterestRateUpdated(uint256 timestamp, uint256 rate);

    event RewardsTransferred(address indexed stakerAddress, uint256 rewards);

    event MinimumStakeAmountUpdated(uint256 stakeAmount);
    event LockPeriodUpdated(uint256 lockPeriod);
    event ExcessTokenWithdrawal(address targetAddress, uint256 amount);
    event RewardsPoolTokenTopUp(address sender, uint256 amount);
    event RewardsPoolTokenWithdrawal(address targetAddress, uint256 amount);
    event WithdrawAll(address targetAddress, uint256 amount, uint256 ethAmount);

    /* Only callable by owner or delegate */
    modifier onlyDelegate() {
        require(
            owner() == _msgSender() || hasRole(DELEGATE_ROLE, _msgSender()),
            "Caller is neither owner nor delegate"
        );
        _;
    }

    /*******************
    Contract start
    *******************/
    /**
     * @param _tokenAddress address of the ERC20 contract
     */
    constructor(
        address _tokenAddress,
        uint256 _lockPeriod,
        uint256 _interestRate
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DELEGATE_ROLE, _msgSender());
        token = IERC20(_tokenAddress);
        tokenAddress = _tokenAddress;
        lockPeriod = _lockPeriod;
        interestRate = _interestRate;
    }

    // **********************************************************
    // ******************    STAKE / UNSTAKE METHODS   *****************

    function deposit(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "deposit amount must not be zero.");

        require(
            _amount >= minimumStakeAmount,
            "amount must be at least minimum amount."
        );

        require(
            _amount <= token.balanceOf(_msgSender()),
            "not enough balance."
        );

        if (!users.contains(_msgSender())) {
            users.add(_msgSender());
        }

        if (stakers[_msgSender()].amount == 0) {
            lastClaimedTime[_msgSender()] = 0;
            totalEarnedTokens[_msgSender()] = 0;
            stakers[_msgSender()].unclaimedRewards = 0;
            stakers[_msgSender()].amount = _amount;
            stakers[_msgSender()].interestRate = interestRate;
            stakers[_msgSender()].timestamp = block.timestamp;
            stakers[_msgSender()].length += 1;
        } else {
            uint256 rewards = getPendingRewards(_msgSender());
            lastClaimedTime[_msgSender()] = 0;
            stakers[_msgSender()].unclaimedRewards += rewards;
            stakers[_msgSender()].amount += _amount;
            stakers[_msgSender()].timestamp = block.timestamp;
            stakers[_msgSender()].length += 1;
        }

        uint256 currentStakeId = stakers[_msgSender()].length + 1;
        stakesList.push(
            StakeEntry({stakerAddress: _msgSender(), stakeId: currentStakeId})
        );

        totalStakedBalance += _amount;

        token.transferFrom(_msgSender(), address(this), _amount);

        emit LiquidityDeposited(_msgSender(), _amount);
    }

    function claimRewards() external whenNotPaused {
        _claimRewards();
    }

    /**
     * @notice Withdraws all rewards and staked amounts available to sender.
     *∏
     * @dev public access
     */
    function withdrawTokens(uint256 _amount) external whenNotPaused {
        uint256 stakedAmount = stakers[_msgSender()].amount;
        uint256 timestamp = stakers[_msgSender()].timestamp;

        require(stakedAmount > 0, "nothing to withdraw");

        require(
            stakedAmount >= _amount,
            "amount to withdraw must not be more than staked"
        );

        require(
            block.timestamp > timestamp + lockPeriod,
            "please wait until lockperiod is over."
        );

        _claimRewards();

        stakers[_msgSender()].amount -= _amount;

        totalStakedBalance -= _amount;

        token.transfer(_msgSender(), _amount);

        emit LiquidityWithdrawn(_msgSender(), _amount);
    }

    function getRewardsPoolBalance() external view returns (uint256) {
        return rewardsPoolBalance;
    }

    function getStake(address _forAddress) public view returns (Staker memory) {
        return stakers[_forAddress];
    }

    function getNumberOfStakesForUser(
        address _forAddress
    ) external view returns (uint256 length) {
        length = stakers[_forAddress].length;
    }

    function getStakesLength() external view returns (uint256 length) {
        length = stakesList.length;
    }

    function getUserByIndex(
        uint256 _index
    ) external view returns (address user) {
        user = users.at(_index);
    }

    function getUsersLength() external view returns (uint256 length) {
        length = users.length();
    }

    function getUserAccountInfo(
        address forAddress
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        uint256 principal = stakers[forAddress].amount;

        uint256 unclaimedRewards = stakers[forAddress].unclaimedRewards;

        uint256 pendingRewards = getPendingRewards(forAddress) +
            unclaimedRewards;

        uint256 total = principal + pendingRewards;

        uint256 stakedDate = stakers[forAddress].timestamp;

        uint256 stakedLength = stakers[forAddress].length;

        return (
            principal,
            pendingRewards,
            total,
            stakedDate,
            stakedLength,
            interestRate,
            lockPeriod
        );
    }

    /**
       @dev Even though this is considered as administrative action (is not affected by
            by contract paused state, it can be executed by anyone who wishes to
            top-up the rewards pool (funds are sent in to contract, *not* the other way around).
            The Rewards Pool is exclusively dedicated to cover withdrawals of user' compound interest,
            which is effectively the reward.
     */
    function topUpRewardsPool(uint256 _amount) external {
        require(_amount > 0, "topup amount must not be zero.");

        token.transferFrom(_msgSender(), address(this), _amount);

        rewardsPoolBalance += _amount;
        emit RewardsPoolTokenTopUp(_msgSender(), _amount);
    }

    /**
     * @notice Updates Interest rate per second value
     * @param _rate  Interest rate per second
     * @dev Delegate only
     */
    function updateInterestRate(uint64 _rate) external onlyDelegate {
        _updateInterestRate(_rate);
    }

    /**
     * @notice Updates Lock Period value
     * @param _lockPeriod  seconds of the lock period
     * @dev Delegate only
     */
    function updateLockPeriod(uint64 _lockPeriod) external onlyDelegate {
        _updateLockPeriod(_lockPeriod);
    }

    /**
     * @dev Withdraw tokens from rewards pool.
     *
     * @param amount : amount to withdraw.
     *                 If `amount == 0` then whole amount in rewards pool will be withdrawn.
     * @param targetAddress : address to send tokens to
     */
    function withdrawFromRewardsPool(
        uint256 amount,
        address payable targetAddress
    ) external onlyOwner {
        if (amount == 0) {
            amount = rewardsPoolBalance;
        } else {
            require(
                amount <= rewardsPoolBalance,
                "Amount higher than rewards pool"
            );
        }

        // NOTE(pb): Strictly speaking, consistency check in following lines is not necessary,
        //           the if-else code above guarantees that everything is alright:
        uint256 contractBalance = token.balanceOf(address(this));
        uint256 expectedMinContractBalance = totalStakedBalance + amount;
        require(
            expectedMinContractBalance <= contractBalance,
            "Contract inconsistency."
        );

        rewardsPoolBalance -= amount;

        require(
            token.transfer(targetAddress, amount),
            "Not enough funds on contr. addr."
        );

        emit RewardsPoolTokenWithdrawal(targetAddress, amount);
    }

    /**
     * @dev Withdraw "excess" tokens, which were sent to contract directly via direct ERC20.transfer(...),
     *      without interacting with API of this (Staking) contract, what could be done only by mistake.
     *      Thus this method is meant to be used primarily for rescue purposes, enabling withdrawal of such
     *      "excess" tokens out of contract.
     * @param targetAddress : address to send tokens to
     */
    function withdrawExcessTokens(
        address payable targetAddress
    ) external onlyOwner {
        uint256 contractBalance = token.balanceOf(address(this));
        uint256 expectedMinContractBalance = totalStakedBalance +
            rewardsPoolBalance;
        // NOTE(pb): The following subtraction shall *fail* (revert) IF the contract is in *INCONSISTENT* state,
        //           = when contract balance is less than minial expected balance:
        uint256 excessAmount = contractBalance - expectedMinContractBalance;
        require(
            token.transfer(targetAddress, excessAmount),
            "Not enough funds on contract address"
        );
        emit ExcessTokenWithdrawal(targetAddress, excessAmount);
    }

    /**
     * @notice Transfers the remaining token and ether balance to the specified
       payoutAddress
     * @param _payoutAddress address to transfer the balances to. Ensure that this is able to handle ERC20 tokens
     * @dev owner only + only on or after `_earliestDelete` block
     */
    function withdrawAll(address payable _payoutAddress) external onlyOwner {
        uint256 contractBalance = token.balanceOf(address(this));
        require(token.transfer(_payoutAddress, contractBalance));
        uint256 contractEthBalance = address(this).balance;

        (bool success, ) = payable(_payoutAddress).call{
            value: contractEthBalance
        }("");
        require(success, "payable ETH sending failed.");

        emit WithdrawAll(_payoutAddress, contractBalance, contractEthBalance);
    }

    // **********************************************************
    // ******************    INTERNAL METHODS   *****************

    /**
     * @notice Add new interest rate in to the ordered container of previously added interest rates
     * @param _rate - signed interest rate value in [10**18] units => real_rate [1] = rate [10**18] / 10**18
     */
    function _updateInterestRate(uint256 _rate) internal {
        interestRate = _rate;
        emit InterestRateUpdated(block.timestamp, interestRate);
    }

    /**
     * @notice Updates Lock Period value
     * @param _lockPeriod  length of the lock period
     */
    function _updateLockPeriod(uint256 _lockPeriod) internal {
        lockPeriod = _lockPeriod;
        emit LockPeriodUpdated(lockPeriod);
    }

    /**
     * @notice Updates minimum stake value
     * @param _stakeAmount  length of the min stake amount
     */
    function _updateMinimumStakeAmount(uint256 _stakeAmount) internal {
        minimumStakeAmount = _stakeAmount;
        emit MinimumStakeAmountUpdated(minimumStakeAmount);
    }

    function _claimRewards() internal {
        uint256 unclaimedRewards = stakers[_msgSender()].unclaimedRewards;
        uint256 pendingRewards = getPendingRewards(_msgSender()) +
            unclaimedRewards;

        require(
            pendingRewards <= rewardsPoolBalance,
            "not enough balance in rewards pool"
        );

        if (pendingRewards > 0) {
            token.transfer(_msgSender(), pendingRewards);
            totalEarnedTokens[_msgSender()] = totalEarnedTokens[
                _msgSender()
            ] += pendingRewards;
            totalClaimedRewards = totalClaimedRewards += pendingRewards;

            rewardsPoolBalance -= pendingRewards;

            stakers[_msgSender()].unclaimedRewards = 0;

            uint256 endtime = stakers[_msgSender()].timestamp + lockPeriod;

            if (block.timestamp < endtime) {
                lastClaimedTime[_msgSender()] = block.timestamp;
            } else {
                lastClaimedTime[_msgSender()] = endtime;
            }

            emit RewardsTransferred(_msgSender(), pendingRewards);
        }
    }

    function getPendingRewards(
        address forAddress
    ) public view returns (uint256) {
        if (stakers[forAddress].amount == 0) return 0;

        uint256 stakedAmount = stakers[forAddress].amount;

        uint256 referenceTime = lastClaimedTime[forAddress];

        uint256 endtime = stakers[forAddress].timestamp + lockPeriod;

        if (lastClaimedTime[forAddress] == 0) {
            referenceTime = stakers[forAddress].timestamp;
        }

        uint256 timeDiff;

        if (block.timestamp < endtime) {
            timeDiff = block.timestamp - referenceTime;
        } else {
            timeDiff = endtime - referenceTime;
        }
        uint256 pendingRewardsOne = ((stakedAmount * interestRate * timeDiff) /
            lockPeriod) / 1e4;

        return pendingRewardsOne;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}