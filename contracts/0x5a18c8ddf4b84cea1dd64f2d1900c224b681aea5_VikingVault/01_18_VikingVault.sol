// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Context.sol";
import "./Fees.sol";
import "./Events.sol";
 
contract VikingVault is Context, Fees {
    using SafeERC20 for IERC20;

    /// @notice enum Status contains multiple status.
    enum Status { Pause, Collecting, Staking, Completed }

    struct VaultInfo {
        Status status; // vault status
        uint256 stakingPeriod; // the timestamp length of staking vault.
        uint256 startTimestamp;  // block.number when the vault start accouring rewards.
        uint256 stopTimestamp; // the block.number to end the staking vault.
        uint256 totalVaultShares; // total tokens deposited into Vault.
        uint256 totalVaultRewards; // amount of tokens to reward this vault.
    }

    struct RewardInfo {
        uint256 lastRewardUpdateTimeStamp;
        uint256 rewardRate; // rewardRate is totalVaultRewards / stakingPeriod.
        uint256 pendingVaultRewards;
        uint256 claimedVaultRewards; // claimed rewards for the vault.
        uint256 remainingVaultRewards; // remaining rewards for this vault.        
    }
    
    VaultInfo public vault;
    RewardInfo public _reward;

    /// @notice modifier checks that a user is staking.
    /// @param account The account address to check.
    modifier isStakeholder(address account) {
        if (_balances[account] == 0) revert NotAuthorized();
        _;
    }

    /// @notice modifier checks that contract is in status Collecting.
    modifier isCollecting() {
        if (vault.status != Status.Collecting) revert NotCollecting();
        _;
    }

    /// @notice modifier checks that contract has status Staking.
    modifier isStaking() {
        if (vault.status != Status.Staking) revert NotStaking();
        _;
    }

    /// @notice modifier checks that contract has status Completed.
    modifier isCompleted() {
        if (vault.status != Status.Completed) revert NotCompleted();
        _;
    }

    /// @notice modifier checks for zero values.
    /// @param amount The user amount to deposit in Wei.
    modifier noZeroValues(uint256 amount) {
        if (_msgSender() == address(0) || amount <= 0) revert NoZeroValues();
        _;
    }

    /// @notice modifier sets a max limit to 1 million tokens staked per user.
    modifier limiter(uint256 amount) {
        uint256 balance = _balances[_msgSender()];
        uint256 totalBalance = balance + amount;
        if (totalBalance >= 1000000000000000000000000) revert MaxStaked();
        _;
    }

    /// @notice modifier updates the vault reward stats.
    modifier updateVaultRewards() {
        require(_reward.remainingVaultRewards > 0);
        
        uint256 _currentValue = _reward.rewardRate * (block.timestamp - _reward.lastRewardUpdateTimeStamp);
        _reward.pendingVaultRewards += _currentValue;
        _reward.remainingVaultRewards -= _currentValue;
        _reward.lastRewardUpdateTimeStamp = block.timestamp;
        _;
    }

    /// @notice contructor sets the token address, fee address and operator address.
    constructor(address payable fee, address operator) {
        _setupRole(DEFAULT_ADMIN_ROLE, creator);
        _setupRole(ADMIN_ROLE, creator);
        _setupRole(OPERATOR_ROLE, operator);
        
        feeAddress = fee;
        vault.status = Status.Pause;
    }   
    
    /// @notice receive function reverts and returns the funds to the sender.
    receive() external payable {
        revert("not payable receive");
    }

    /// ------------------------------- PUBLIC METHODS -------------------------------

    /// Method to get the users erc20 balance.
    /// @param account The account of the user to check.
    /// @return user erc20 balance.
    function getAccountErc20Balance(address account) external view returns (uint256) {
        return token.balanceOf(account);
    }

    /// Method to get the users vault balance.
    /// @param account The account of the user to check.
    /// @return user balance staked in vault.
    function getAccountVaultBalance(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// Method to get the vaults RewardInfo.
    function getRewardInfo() external view returns (
        uint256 lastRewardUpdateTimeStamp,
        uint256 rewardRate, 
        uint256 pendingVaultRewards,
        uint256 claimedVaultRewards, 
        uint256 remainingVaultRewards
    ) {
        return (
            _reward.lastRewardUpdateTimeStamp,
            _reward.rewardRate,
            _reward.pendingVaultRewards,
            _reward.claimedVaultRewards,
            _reward.remainingVaultRewards);
    }

    /// @notice Method to let a user deposit funds into the vault.
    /// @param amount The amount to be staked.
    function deposit(uint256 amount) external isCollecting limiter(amount) noZeroValues(amount) {
        _balances[_msgSender()] += amount;
        vault.totalVaultShares += amount;
        _deposit(_msgSender(), amount);
        emit Deposit(_msgSender(), amount);
    }
    
    /// @notice Lets a user exit their position while status is Collecting. 
    /// @notice ATT. The user is subject to an 7% early withdraw fee.
    /// @dev Can only be executed while status is Collecting.
    function exitWhileCollecting() external isStakeholder(_msgSender()) isCollecting {
        require(_msgSender() != address(0), "Not zero address");

        uint256 _totalUserShares = _balances[_msgSender()];
        delete _balances[_msgSender()];

        (uint256 _contractAmount, uint256 _feeAmount, uint256 _withdrawAmount) = super._calculateFee(_totalUserShares);
        vault.totalVaultShares -= _totalUserShares;
        
        // Pay 7% withdrawFee before withdraw.
        _withdraw(address(feeAddress), _feeAmount);
        _withdraw(address(creator), _contractAmount);
        _withdraw(address(_msgSender()), _withdrawAmount);
        
        emit ExitWithFees(_msgSender(), _withdrawAmount);
    }

    /// @notice Lets a user exit their position while staking. 
    /// @notice ATT. The user is subject to an 7% early withdraw fee.
    /// @dev Can only be executed while status is Staking.
    function exitWhileStaking() external isStakeholder(_msgSender()) isStaking updateVaultRewards {
        require(_msgSender() != address(0), "Not zero address");

        uint256 _totalUserShares = _balances[_msgSender()];
        delete _balances[_msgSender()];

        (uint256 _contractAmount, uint256 _feeAmount, uint256 _withdrawAmount) = super._calculateFee(_totalUserShares);

        // if withdrawPenaltyPeriod is over, calculate user rewards.
        if (block.timestamp >= (vault.startTimestamp + withdrawPenaltyPeriod)) {
            uint256 _pendingUserReward = _calculateUserReward(_totalUserShares);
            _withdrawAmount += _pendingUserReward;

            _reward.pendingVaultRewards -= _pendingUserReward;
            _reward.remainingVaultRewards -= _pendingUserReward;
            _reward.claimedVaultRewards += _pendingUserReward;
        }
        vault.totalVaultShares -= _totalUserShares;

        // Pay preset % in withdrawFee before the withdraw is transacted.
        _withdraw(address(feeAddress), _feeAmount);
        _withdraw(address(creator), _contractAmount);
        _withdraw(address(_msgSender()), _withdrawAmount);

        emit ExitWithFees(_msgSender(), _withdrawAmount);
    }

    /// @notice Let the user remove their stake and receive the accumulated rewards, without paying extra fees.
    function withdraw() external isStakeholder(_msgSender()) isCompleted {
        require(_msgSender() != address(0), "Not zero adress");
        
        uint256 _totalUserShares =  _balances[_msgSender()];
        delete _balances[_msgSender()];
    
        uint256 _pendingUserReward = _calculateUserReward(_totalUserShares);
        
        
        _reward.pendingVaultRewards -= _pendingUserReward;
        _reward.claimedVaultRewards += _pendingUserReward;
        vault.totalVaultShares -= _totalUserShares;
        
        _withdraw(_msgSender(), _pendingUserReward);
        _withdraw(_msgSender(), _totalUserShares);

        emit Withdraw(_msgSender(), _totalUserShares, _pendingUserReward);
    }

/// ------------------------------- ADMIN METHODS -------------------------------

    /// @notice Add reward amount to the vault.
    /// @param amount The amount to deposit in Wei.
    /// @dev Restricted to onlyOwner.  
    function addRewards(uint256 amount) external onlyRole(OPERATOR_ROLE) noZeroValues(amount) {
        _deposit(_msgSender(), amount);
        
        vault.totalVaultRewards += amount;
        _reward.rewardRate = (vault.totalVaultRewards / vault.stakingPeriod);
        _reward.remainingVaultRewards += amount;
    }

    /// @notice Sets the contract status to Staking.
    function startStaking() external isCollecting onlyRole(OPERATOR_ROLE) {
        vault.status = Status.Staking;
        vault.startTimestamp = block.timestamp;
        vault.stopTimestamp = vault.startTimestamp + vault.stakingPeriod;
        _reward.lastRewardUpdateTimeStamp = vault.startTimestamp;

        emit StakingStarted();
    }

    /// @notice Sets the contract status to Completed.
    /// @dev modifier updateVaultRewards is called before status is set to Completed.
    function stopStaking() external isStaking onlyRole(OPERATOR_ROLE) {
        vault.status = Status.Completed;
        _reward.pendingVaultRewards += _reward.remainingVaultRewards;
        _reward.remainingVaultRewards = 0;
        emit StakingCompleted();
    }


    
/// ------------------------------- PRIVATE METHODS -------------------------------

    /// @notice Internal function to deposit funds to vault.
    /// @param _from The from address that deposits the funds.
    /// @param _amount The amount to be deposited in Wei.
    /// @return true if valid.
    function _deposit(address _from, uint256 _amount) private returns (bool) {
        token.safeTransferFrom(_from, address(this), _amount);
        return true;
    }
 
    /// @notice Internal function to withdraw funds from the vault.
    /// @param _to The address that receives the withdrawn funds.
    /// @param _amount The amount to be withdrawn.
    function _withdraw(address _to, uint256 _amount) private {
        token.safeTransfer(_to, _amount);
    }

    /// @notice Internal function to calculate the pending user rewards.
    /// @param _totalUserShares The total amount deposited to vault by user.
    /// @return pending user reward amount.
    function _calculateUserReward(uint256 _totalUserShares) private view returns (uint256) {
        require(_reward.pendingVaultRewards > 0, "No pending rewards");
        
        uint256 _userPercentOfVault = _totalUserShares * 10000 / vault.totalVaultShares;
        uint256 _pendingUserReward = _reward.pendingVaultRewards * _userPercentOfVault / 10000;

        return _pendingUserReward;
    }

    /// @notice Function to initiate the Collecting status.
    /// @param period The staking period in seconds.
    /// @param penaltyPeriod The penalty period in seconds.
    /// @dev Restricted to OPERATOR_ROLE.
    function initCollecting(address tokenAddress, uint256 period, uint256 penaltyPeriod) external onlyRole(OPERATOR_ROLE) {
        token = IERC20(tokenAddress);
        vault.stakingPeriod = period; 
        withdrawFeePeriod = vault.stakingPeriod;
        withdrawPenaltyPeriod =  penaltyPeriod;
        vault.status = Status.Collecting;
    } 
}