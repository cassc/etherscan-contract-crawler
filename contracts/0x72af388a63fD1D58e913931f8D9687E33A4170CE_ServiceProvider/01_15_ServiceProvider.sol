// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {StakingRewards} from "./StakingRewards.sol";

contract ServiceProvider is ReentrancyGuard, Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct WithdrawalRequest {
        uint256 withdrawalPermittedFrom;
        uint256 amount;
        uint256 lastStakedBlock;
    }

    mapping(address => WithdrawalRequest) public withdrawalRequest;
    address public controller; // StakingRewards

    address public serviceProvider;
    address public serviceProviderManager;

    IERC20 public cudosToken;

    /// @notice Allows the rewards fee to be specified to 2 DP
    uint256 public constant PERCENTAGE_MODULO = 100_00;

    /// @notice True when contract is initialised and the service provider has staked the required bond
    bool public isServiceProviderFullySetup;

    bool public exited;

    /// @notice Defined by the service provider when depositing their bond
    uint256 public rewardsFeePercentage;

    event StakedServiceProviderBond(address indexed serviceProvider, address indexed serviceProviderManager, uint256 indexed pid, uint256 rewardsFeePercentage);
    event IncreasedServiceProviderBond(address indexed serviceProvider, uint256 indexed pid, uint256 amount, uint256 totalAmount);
    event DecreasedServiceProviderBond(address indexed serviceProvider, uint256 indexed pid, uint256 amount, uint256 totalAmount);
    event ExitedServiceProviderBond(address indexed serviceProvider, uint256 indexed pid);
    event WithdrewServiceProviderStake(address indexed serviceProvider, uint256 amount, uint256 totalAmount);
    event AddDelegatedStake(address indexed user, uint256 amount, uint256 totalAmount);
    event WithdrawDelegatedStakeRequested(address indexed user, uint256 amount, uint256 totalAmount);
    event WithdrewDelegatedStake(address indexed user, uint256 amount, uint256 totalAmount);
    event ExitDelegatedStake(address indexed user, uint256 amount);
    event CalibratedServiceProviderFee(address indexed user, uint256 newFee);

    mapping(address => uint256) public delegatedStake;

    mapping(address => uint256) public rewardDebt;
    // rewardDebt is the total amount of rewards a user would have received if the state of the network were the same as now from the beginning.

    uint256 public totalDelegatedStake;

    uint256 public rewardsProgrammeId;

    uint256 public minStakingLength;

    uint256 public accTokensPerShare; // Accumulated reward tokens per share, times 1e18. See below.
    // accTokensPerShare is the average reward amount a user would have received per each block so far
    // if the state of the network were the same as now from the beginning.

    // Service provider not setup
    modifier notSetupSP() {
    	require(isServiceProviderFullySetup, "SPC2");
	    _;
    }

    // Only Service Provider
    modifier onlySP() {
    	require(_msgSender() == serviceProvider, "SPC1");
	    _;
    }

    // Only Service Provider Manager
    modifier onlySPM() {
        require(_msgSender() == serviceProviderManager, "SPC3");
        _;
    }

    // Not a service provider method
    modifier allowedSP() {
    	require(_msgSender() != serviceProviderManager && _msgSender() != serviceProvider, "SPC4");
   	    _;
   }

    // Service provider has left
    modifier isExitedSP() {
    	require(!exited, "SPHL");
	    _;
    }

    // _amount cannot be 0
    modifier notZero(uint256 _amount) {
    	require(_amount > 0, "SPC6");
         _; 
    }

    // this is called by StakingRewards to whitelist a service provider and is equivalent of the constructor
    function init(address _serviceProvider, IERC20 _cudosToken) external {
        // ServiceProvider.init: Fn can only be called once
        require(serviceProvider == address(0), "SPI1");
	    // ServiceProvider.init: Service provider cannot be zero address
        require(_serviceProvider != address(0), "SPI2");
	    // ServiceProvider.init: Cudos token cannot be zero address
        require(address(_cudosToken) != address(0), "SPI3");
        serviceProvider = _serviceProvider;
        cudosToken = _cudosToken;

        controller = _msgSender();
        // StakingRewards contract currently
    }

    // Called by the Service Provider to stake initial minimum cudo required to become a validator
    function stakeServiceProviderBond(uint256 _rewardsProgrammeId, uint256 _rewardsFeePercentage) nonReentrant external onlySP {
        serviceProviderManager = serviceProvider;
        _stakeServiceProviderBond(_rewardsProgrammeId, _rewardsFeePercentage);
    }

    function adminStakeServiceProviderBond(uint256 _rewardsProgrammeId, uint256 _rewardsFeePercentage) nonReentrant external {
        require(
            StakingRewards(controller).hasAdminRole(_msgSender()),
	    // ServiceProvider.adminStakeServiceProviderBond: Only admin
            "OA"
        );

        serviceProviderManager = _msgSender();
        _stakeServiceProviderBond(_rewardsProgrammeId, _rewardsFeePercentage);
    }

    function increaseServiceProviderStake(uint256 _amount) nonReentrant external notSetupSP onlySPM notZero(_amount) {
        StakingRewards rewards = StakingRewards(controller);
        uint256 maxStakingAmountForServiceProviders = rewards.maxStakingAmountForServiceProviders();
        uint256 amountStakedSoFar = rewards.amountStakedByUserInRewardProgramme(rewardsProgrammeId, address(this));

	    // ServiceProvider.increaseServiceProviderStake: Exceeds max staking
        require(amountStakedSoFar.add(_amount) <= maxStakingAmountForServiceProviders, "SPS1");

        // Get and distribute any pending rewards
        _getAndDistributeRewardsWithMassUpdate();

        // increase the service provider stake
        StakingRewards(controller).stake(rewardsProgrammeId, serviceProviderManager, _amount);

        // Update delegated stake
        delegatedStake[serviceProvider] = delegatedStake[serviceProvider].add(_amount);
        totalDelegatedStake = totalDelegatedStake.add(_amount);

        // Store date for lock-up calculation
        WithdrawalRequest storage withdrawalReq = withdrawalRequest[_msgSender()];
        withdrawalReq.lastStakedBlock = rewards._getBlock();

        emit IncreasedServiceProviderBond(serviceProvider, rewardsProgrammeId, _amount, delegatedStake[serviceProvider]);
    }

    function requestExcessServiceProviderStakeWithdrawal(uint256 _amount) nonReentrant external notSetupSP onlySPM notZero(_amount) {
        StakingRewards rewards = StakingRewards(controller);
        WithdrawalRequest storage withdrawalReq = withdrawalRequest[_msgSender()];
        
        // Check if lockup has passed
        uint256 stakeStart = withdrawalReq.lastStakedBlock;               
	    // StakingRewards.withdraw: Min staking period has not yet passed
        require(rewards._getBlock() >= stakeStart.add(minStakingLength), "SPW5");

        uint256 amountLeftAfterWithdrawal = delegatedStake[serviceProvider].sub(_amount);
        require(
            amountLeftAfterWithdrawal >= rewards.minRequiredStakingAmountForServiceProviders(),
	    // ServiceProvider.requestExcessServiceProviderStakeWithdrawal: Remaining stake for a service provider cannot fall below minimum
            "SPW7"
        );

        // Get and distribute any pending rewards
        _getAndDistributeRewardsWithMassUpdate();

        // Apply the unbonding period
        uint256 unbondingPeriod = rewards.unbondingPeriod();

        withdrawalReq.withdrawalPermittedFrom = rewards._getBlock().add(unbondingPeriod);
        withdrawalReq.amount = withdrawalReq.amount.add(_amount);

        delegatedStake[serviceProvider] = amountLeftAfterWithdrawal;
        totalDelegatedStake = totalDelegatedStake.sub(_amount);

        rewards.withdraw(rewardsProgrammeId, address(this), _amount);

        emit DecreasedServiceProviderBond(serviceProvider, rewardsProgrammeId, _amount, delegatedStake[serviceProvider]);
    }

    // only called by service provider
    // all CUDOs staked by service provider and any delegated stake plus rewards will be returned to this contract
    // delegators will have to call their own exit methods to get their original stake and rewards
    function exitAsServiceProvider() nonReentrant external onlySPM {
        StakingRewards rewards = StakingRewards(controller);
        WithdrawalRequest storage withdrawalReq = withdrawalRequest[_msgSender()];
        
        // Check if lockup has passed
        uint256 stakeStart = withdrawalReq.lastStakedBlock;               
	    // StakingRewards.withdraw: Min staking period has not yet passed
        require(rewards._getBlock() >= stakeStart.add(minStakingLength), "SPW5");
        
        // Distribute rewards to the service provider and update delegator reward entitlement
        _getAndDistributeRewardsWithMassUpdate();

        // Assign the unbonding period
        uint256 unbondingPeriod = rewards.unbondingPeriod();

        withdrawalReq.withdrawalPermittedFrom = rewards._getBlock().add(unbondingPeriod);
        withdrawalReq.amount = withdrawalReq.amount.add(delegatedStake[serviceProvider]);

        // Exit the rewards program bringing in all staked CUDO and earned rewards
        StakingRewards(controller).exit(rewardsProgrammeId);

        // Update service provider state
        uint256 serviceProviderDelegatedStake = delegatedStake[serviceProvider];
        delegatedStake[serviceProvider] = 0;
        totalDelegatedStake = totalDelegatedStake.sub(serviceProviderDelegatedStake);

        // this will mean a service provider could start the program again with stakeServiceProviderBond()
        isServiceProviderFullySetup = false;

        // prevents a SP from re-entering and causing loads of problems!!!
        exited = true;

         // Don't transfer tokens at this point. The service provider needs to wait for the unbonding period first, then needs to call withdrawServiceProviderStake()

        emit ExitedServiceProviderBond(serviceProvider, rewardsProgrammeId);
    }

    // To be called only by a service provider
    function withdrawServiceProviderStake() nonReentrant external onlySPM {
        WithdrawalRequest storage withdrawalReq = withdrawalRequest[_msgSender()];

	    // ServiceProvider.withdrawServiceProviderStake: no withdrawal request in flight
        require(withdrawalReq.amount > 0, "SPW5");
        require(
            StakingRewards(controller)._getBlock() >= withdrawalReq.withdrawalPermittedFrom,
	    // ServiceProvider.withdrawServiceProviderStake: Not passed unbonding period
            "SPW3"
            );

        uint256 withdrawalRequestAmount = withdrawalReq.amount;
        withdrawalReq.amount = 0;

        cudosToken.transfer(_msgSender(), withdrawalRequestAmount);

        emit WithdrewServiceProviderStake(_msgSender(), withdrawalRequestAmount, delegatedStake[serviceProvider]);
    }

    // Called by a CUDO holder that wants to delegate their stake to a service provider
    function delegateStake(uint256 _amount) nonReentrant external notSetupSP allowedSP notZero(_amount) {
        // get and distribute any pending rewards
        _getAndDistributeRewardsWithMassUpdate();

        // now stake - no rewards will be sent back
        StakingRewards(controller).stake(rewardsProgrammeId, _msgSender(), _amount);

        // Update user and total delegated stake after _distributeRewards so that calc issues don't arise in _distributeRewards
        uint256 previousDelegatedStake = delegatedStake[_msgSender()];
        delegatedStake[_msgSender()] = previousDelegatedStake.add(_amount);
        totalDelegatedStake = totalDelegatedStake.add(_amount);

        // we need to update the reward debt so that the user doesn't suddenly have rewards due
        rewardDebt[_msgSender()] = delegatedStake[_msgSender()].mul(accTokensPerShare).div(1e18);

        // Store date for lock-up calculation
        WithdrawalRequest storage withdrawalReq = withdrawalRequest[_msgSender()];
        withdrawalReq.lastStakedBlock = StakingRewards(controller)._getBlock();

        emit AddDelegatedStake(_msgSender(), _amount, delegatedStake[_msgSender()]);
    }

    // Called by a CUDO holder that has previously delegated stake to the service provider
    function requestDelegatedStakeWithdrawal(uint256 _amount) nonReentrant external isExitedSP notSetupSP notZero(_amount) allowedSP {
        // ServiceProvider.requestDelegatedStakeWithdrawal: Amount exceeds delegated stake
        require(delegatedStake[_msgSender()] >= _amount, "SPW4");

        StakingRewards rewards = StakingRewards(controller);
        WithdrawalRequest storage withdrawalReq = withdrawalRequest[_msgSender()];
        
        // Check if lockup has passed
        uint256 stakeStart = withdrawalReq.lastStakedBlock;
	    // StakingRewards.withdraw: Min staking period has not yet passed
        require(rewards._getBlock() >= stakeStart.add(minStakingLength), "SPW5");
        
        _getAndDistributeRewardsWithMassUpdate();

        uint256 unbondingPeriod = rewards.unbondingPeriod();

        withdrawalReq.withdrawalPermittedFrom = rewards._getBlock().add(unbondingPeriod);
        withdrawalReq.amount = withdrawalReq.amount.add(_amount);

        delegatedStake[_msgSender()] = delegatedStake[_msgSender()].sub(_amount);
        totalDelegatedStake = totalDelegatedStake.sub(_amount);

        rewards.withdraw(rewardsProgrammeId, address(this), _amount);

        // we need to update the reward debt so that the reward debt is not too high due to the decrease in staked amount
        rewardDebt[_msgSender()] = delegatedStake[_msgSender()].mul(accTokensPerShare).div(1e18);

        emit WithdrawDelegatedStakeRequested(_msgSender(), _amount, delegatedStake[_msgSender()]);
    }

    function withdrawDelegatedStake() nonReentrant external isExitedSP notSetupSP allowedSP {
        WithdrawalRequest storage withdrawalReq = withdrawalRequest[_msgSender()];
	    // ServiceProvider.withdrawDelegatedStake: no withdrawal request in flight
        require(withdrawalReq.amount > 0, "SPW2");
        
        require(
            StakingRewards(controller)._getBlock() >= withdrawalReq.withdrawalPermittedFrom,
	    // ServiceProvider.withdrawDelegatedStake: Not passed unbonding period
            "SPW3"
        );
        uint256 withdrawalRequestAmount = withdrawalReq.amount;
        withdrawalReq.amount = 0;

        cudosToken.transfer(_msgSender(), withdrawalRequestAmount);

        emit WithdrewDelegatedStake(_msgSender(), withdrawalRequestAmount, delegatedStake[_msgSender()]);
    }

    // Can be called by a delegator when a service provider exits
    // Service provider must have exited when the delegator calls this method. Otherwise, they call withdrawDelegatedStake
    function exitAsDelegator() nonReentrant external {
        // ServiceProvider.exitAsDelegator: Service provider has not exited
	    require(exited, "SPE1");
        
        WithdrawalRequest storage withdrawalReq = withdrawalRequest[_msgSender()];
        uint256 withdrawalRequestAmount = withdrawalReq.amount;
        uint256 userDelegatedStake = delegatedStake[_msgSender()];
        uint256 totalPendingWithdrawal = withdrawalRequestAmount.add(userDelegatedStake);

	    // ServiceProvider.exitAsDelegator: No pending withdrawal
        require(totalPendingWithdrawal > 0, "SPW1");

        if (userDelegatedStake > 0) {
            // accTokensPerShare would have already been updated when the service provider exited
            _sendDelegatorAnyPendingRewards();
        }        

        withdrawalReq.amount = 0;
        delegatedStake[_msgSender()] = 0;
        totalDelegatedStake = totalDelegatedStake.sub(userDelegatedStake);

        // Send them back their stake
        cudosToken.transfer(_msgSender(), totalPendingWithdrawal);

        // update rewardDebt to avoid errors in the pendingRewards function
        rewardDebt[_msgSender()] = 0;

        emit ExitDelegatedStake(_msgSender(), totalPendingWithdrawal);
    }

    // Should be possible for anyone to call this to get the reward from the StakingRewards contract
    // The total rewards due to all delegators will have the rewardsFeePercentage deducted and sent to the Service Provider
    function getReward() external isExitedSP notSetupSP {
        _getAndDistributeRewards();
    }

    function callibrateServiceProviderFee() external {
        StakingRewards rewards = StakingRewards(controller);
        uint256 minServiceProviderFee = rewards.minServiceProviderFee();

        // current fee is too low - increase to minServiceProviderFee
        if (rewardsFeePercentage < minServiceProviderFee) {
            rewardsFeePercentage = minServiceProviderFee;
            emit CalibratedServiceProviderFee(_msgSender(), rewardsFeePercentage);
        }
    }

    /////////////////
    // View methods
    /////////////////

    function pendingRewards(address _user) public view returns (uint256) {
        uint256 pendingRewardsServiceProviderAndDelegators = StakingRewards(controller).pendingCudoRewards(
            rewardsProgrammeId,
            address(this)
        );

        (
            uint256 stakeDelegatedToServiceProvider,
            uint256 rewardsFee,
            uint256 baseRewardsDueToServiceProvider,
            uint256 netRewardsDueToDelegators
        ) = _workOutHowMuchDueToServiceProviderAndDelegators(pendingRewardsServiceProviderAndDelegators);

        if (_user == serviceProvider && _user == serviceProviderManager) {
            return baseRewardsDueToServiceProvider.add(rewardsFee);
        }   else if (_user == serviceProvider){
                return rewardsFee;
        }   else if (_user == serviceProviderManager){
                return baseRewardsDueToServiceProvider;
        }

        uint256 _accTokensPerShare = accTokensPerShare;
        if (stakeDelegatedToServiceProvider > 0) {
            // Update accTokensPerShare which governs rewards token due to each delegator
            _accTokensPerShare = _accTokensPerShare.add(
                netRewardsDueToDelegators.mul(1e18).div(stakeDelegatedToServiceProvider)
            );
        }

        return delegatedStake[_user].mul(_accTokensPerShare).div(1e18).sub(rewardDebt[_user]);
    }

    ///////////////////
    // Private methods
    ///////////////////

    function _getAndDistributeRewards() private {
        uint256 cudosBalanceBeforeGetReward = cudosToken.balanceOf(address(this));

        StakingRewards(controller).getReward(rewardsProgrammeId);

        uint256 cudosBalanceAfterGetReward = cudosToken.balanceOf(address(this));

        // This is the amount of CUDO that we received from the the above getReward() call
        uint256 rewardDelta = cudosBalanceAfterGetReward.sub(cudosBalanceBeforeGetReward);

        // If this service provider contract has earned additional rewards since the last time, they must be distributed first
        if (rewardDelta > 0) {
            _distributeRewards(rewardDelta);
        }

        // Service provider(s) always receive their rewards first. 
        // If sender is not serviceProvider or serviceProviderManager, we send them their share here.
        if (_msgSender() != serviceProviderManager && _msgSender() != serviceProvider) {
            // check sender has a delegatedStake
            if (delegatedStake[_msgSender()] > 0) {
                _sendDelegatorAnyPendingRewards();
            }
        }
    }

    function _getAndDistributeRewardsWithMassUpdate() private {
        uint256 cudosBalanceBeforeGetReward = cudosToken.balanceOf(address(this));

        StakingRewards(controller).getRewardWithMassUpdate(rewardsProgrammeId);

        uint256 cudosBalanceAfterGetReward = cudosToken.balanceOf(address(this));

        // This is the amount of CUDO that we received from the the above getReward() call
        uint256 rewardDelta = cudosBalanceAfterGetReward.sub(cudosBalanceBeforeGetReward);

        // If this service provider contract has earned additional rewards since the last time, they must be distributed first
        if (rewardDelta > 0) {
            _distributeRewards(rewardDelta);
        }

        // Service provider(s) always receive their rewards first. 
        // If sender is not serviceProvider or serviceProviderManager, we send them their share here.
        if (_msgSender() != serviceProviderManager && _msgSender() != serviceProvider) {
            // check sender has a delegatedStake
            if (delegatedStake[_msgSender()] > 0) {
                _sendDelegatorAnyPendingRewards();
            }
        }
    }

    // Called when this service provider contract has earned additional rewards.
    // Increases delagators' pending rewards, and sends sevice provider(s) their share.
    function _distributeRewards(uint256 _amount) private {
        (
            uint256 stakeDelegatedToServiceProvider,
            uint256 rewardsFee,
            uint256 baseRewardsDueToServiceProvider,
            uint256 netRewardsDueToDelegators
        ) = _workOutHowMuchDueToServiceProviderAndDelegators(_amount);

        // Delegators' pending rewards are updated
        if (stakeDelegatedToServiceProvider > 0) {
            // Update accTokensPerShare which governs rewards token due to each delegator
            accTokensPerShare = accTokensPerShare.add(
                netRewardsDueToDelegators.mul(1e18).div(stakeDelegatedToServiceProvider)
            );
        }

        // Service provider(s) receive their share(s)
        if (serviceProvider == serviceProviderManager){
            cudosToken.transfer(serviceProvider, baseRewardsDueToServiceProvider.add(rewardsFee));
        } else {
            cudosToken.transfer(serviceProviderManager, baseRewardsDueToServiceProvider);
            cudosToken.transfer(serviceProvider, rewardsFee);
        }
    }

    function _workOutHowMuchDueToServiceProviderAndDelegators(uint256 _amount) private view returns (uint256, uint256, uint256, uint256) {

        // In case everyone (validator and delegators) has exited, we still want the pendingRewards function to return a number, which is zero in this case,
        // rather than some kind of a message. So we first treat this edge case separately.
        if (totalDelegatedStake == 0) {
            return (0, 0, 0, 0);
        }
        
        // With this edge case out of the way, first work out the total stake of the delegators
        uint256 stakeDelegatedToServiceProvider = totalDelegatedStake.sub(delegatedStake[serviceProvider]);
        uint256 percentageOfStakeThatIsDelegatedToServiceProvider = stakeDelegatedToServiceProvider.mul(PERCENTAGE_MODULO).div(totalDelegatedStake);

        // Delegators' share before the commission cut
        uint256 grossRewardsDueToDelegators = _amount.mul(percentageOfStakeThatIsDelegatedToServiceProvider).div(PERCENTAGE_MODULO);

        // Validator's share before the commission
        uint256 baseRewardsDueToServiceProvider = _amount.sub(grossRewardsDueToDelegators);

        // Validator's commission
        uint256 rewardsFee = grossRewardsDueToDelegators.mul(rewardsFeePercentage).div(PERCENTAGE_MODULO);

        // Delegators' share after the commission cut
        uint256 netRewardsDueToDelegators = grossRewardsDueToDelegators.sub(rewardsFee);        

        return (stakeDelegatedToServiceProvider, rewardsFee, baseRewardsDueToServiceProvider, netRewardsDueToDelegators);
    }

    // Ensure this is not called when sender is service provider
    function _sendDelegatorAnyPendingRewards() private {
        uint256 pending = delegatedStake[_msgSender()].mul(accTokensPerShare).div(1e18).sub(rewardDebt[_msgSender()]);

        if (pending > 0) {
            rewardDebt[_msgSender()] = delegatedStake[_msgSender()].mul(accTokensPerShare).div(1e18);
            cudosToken.transfer(_msgSender(), pending);
        }
    }

    function _stakeServiceProviderBond(uint256 _rewardsProgrammeId, uint256 _rewardsFeePercentage) private {
        // ServiceProvider.stakeServiceProviderBond: Service provider already set up
        require(!isServiceProviderFullySetup, "SPC7");
	    // ServiceProvider.stakeServiceProviderBond: Exited service provider cannot reenter
        require(!exited, "ECR1");
        // ServiceProvider.stakeServiceProviderBond: Fee percentage must be between zero and one
	    require(_rewardsFeePercentage > 0 && _rewardsFeePercentage < PERCENTAGE_MODULO, "FP2");

        StakingRewards rewards = StakingRewards(controller);
        uint256 minRequiredStakingAmountForServiceProviders = rewards.minRequiredStakingAmountForServiceProviders();
        uint256 minServiceProviderFee = rewards.minServiceProviderFee();

        //ServiceProvider.stakeServiceProviderBond: Fee percentage must be greater or equal to minServiceProviderFee
        require(_rewardsFeePercentage >= minServiceProviderFee, "SPF1");

        rewardsFeePercentage = _rewardsFeePercentage;
        rewardsProgrammeId = _rewardsProgrammeId;
        minStakingLength = rewards._findMinStakingLength(_rewardsProgrammeId);
        isServiceProviderFullySetup = true;

        delegatedStake[serviceProvider] = minRequiredStakingAmountForServiceProviders;
        totalDelegatedStake = totalDelegatedStake.add(minRequiredStakingAmountForServiceProviders);

        // A mass update is required at this point
        _getAndDistributeRewardsWithMassUpdate();

        rewards.stake(
            _rewardsProgrammeId,
            _msgSender(),
            minRequiredStakingAmountForServiceProviders
        );

        // Store date for lock-up calculation
        WithdrawalRequest storage withdrawalReq = withdrawalRequest[_msgSender()];
        withdrawalReq.lastStakedBlock = rewards._getBlock();
        
        emit StakedServiceProviderBond(serviceProvider, serviceProviderManager, _rewardsProgrammeId, rewardsFeePercentage);
    }

    // *** CUDO Admin Emergency only **

    function recoverERC20(address _erc20, address _recipient, uint256 _amount) external {
        // ServiceProvider.recoverERC20: Only admin
        require(StakingRewards(controller).hasAdminRole(_msgSender()), "OA");
        IERC20(_erc20).transfer(_recipient, _amount);
    }
}