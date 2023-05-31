// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import { ServiceProvider } from "./ServiceProvider.sol";
import { CloneFactory } from "./CloneFactory.sol";
import { CudosAccessControls } from "../CudosAccessControls.sol";
import { StakingRewardsGuild } from "./StakingRewardsGuild.sol";

// based on MasterChef from sushi swap
contract StakingRewards is CloneFactory, ReentrancyGuard, Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user that is staked into a specific reward program i.e. 3 month, 6 month, 12 month
    struct UserInfo {
        uint256 amount;     // How many cudos tokens the user has staked.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of cudos
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * rewardProgramme.accTokensPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a rewardProgramme. Here's what happens:
        //   1. The rewardProgramme's `accTokensPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.

        // Hence the rewardDebt is the total amount of rewards a service provider contract would have received
        // if the state of the network were the same as now from the beginning.
    }

    // Info about a reward program where each differs in minimum required length of time for locking up CUDOs.
    struct RewardProgramme {
        uint256 minStakingLengthInBlocks; // once staked, amount of blocks the staker has to wait before being able to withdraw
        uint256 allocPoint;       // Percentage of total CUDOs rewards (across all programmes) that this programme will get
        uint256 lastRewardBlock;  // Last block number that CUDOs was claimed for reward programme users.
        uint256 accTokensPerShare; // Accumulated tokens per share, times 1e18. See below.
        // accTokensPerShare is the average reward amount a service provider contract would have received per each block so far
        // if the state of the network were the same as now from the beginning. 
        uint256 totalStaked; // total staked in this reward programme
    }

    bool public userActionsPaused;

    // staking and reward token - CUDOs
    IERC20 public token;

    CudosAccessControls public accessControls;
    StakingRewardsGuild public rewardsGuildBank;

    // tokens rewarded per block.
    uint256 public tokenRewardPerBlock;

    // Info of each reward programme.
    RewardProgramme[] public rewardProgrammes;

    /// @notice minStakingLengthInBlocks -> is active / valid reward programme
    mapping(uint256 => bool) public isActiveRewardProgramme;

    // Info of each user that has staked in each programme.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    // total staked across all programmes
    uint256 public totalCudosStaked;

    // weighted total staked across all programmes
    uint256 public weightedTotalCudosStaked;

    // The block number when rewards start.
    uint256 public startBlock;

    // service provider -> proxy and reverse mapping
    mapping(address => address) public serviceProviderToWhitelistedProxyContracts;
    mapping(address => address) public serviceProviderContractToServiceProvider;

    /// @notice Used as a base contract to clone for all new whitelisted service providers
    address public cloneableServiceProviderContract;

    /// @notice By default, 2M CUDO must be supplied to be a validator
    uint256 public minRequiredStakingAmountForServiceProviders = 2_000_000 * 10 ** 18;
    uint256 public maxStakingAmountForServiceProviders = 1_000_000_000 * 10 ** 18;

    /// @notice Allows the rewards fee to be specified to 2 DP
    uint256 public constant PERCENTAGE_MODULO = 100_00;
    uint256 public minServiceProviderFee = 2_00; // initially 2%

    uint256 public constant numOfBlocksInADay = 6500;
    uint256 public unbondingPeriod = numOfBlocksInADay.mul(21); // Equivalent to solidity 21 days

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event MinRequiredStakingAmountForServiceProvidersUpdated(uint256 oldValue, uint256 newValue);
    event MaxStakingAmountForServiceProvidersUpdated(uint256 oldValue, uint256 newValue);
    event MinServiceProviderFeeUpdated(uint256 oldValue, uint256 newValue);
    event ServiceProviderWhitelisted(address indexed serviceProvider, address indexed serviceProviderContract);
    event RewardPerBlockUpdated(uint256 oldValue, uint256 newValue);
    event RewardProgrammeAdded(uint256 allocPoint, uint256 minStakingLengthInBlocks);
    event RewardProgrammeAllocPointUpdated(uint256 oldValue, uint256 newValue);
    event UserActionsPausedToggled(bool isPaused);

    // paused
    modifier paused() {
    	require(userActionsPaused == false, "PSD");
        _;
    }

    // Amount cannot be 0
    modifier notZero(uint256 _amount) {
        require(_amount > 0, "SPC6");
         _;
    }

    // Unknown service provider
    modifier unkSP() {
    	require(serviceProviderContractToServiceProvider[_msgSender()] != address(0), "SPU1");
	_;
    }

    // Only whitelisted
    modifier whitelisted() {
    	require(accessControls.hasWhitelistRole(_msgSender()), "OWL");
    	_;
    }
    constructor(
        IERC20 _token,
        CudosAccessControls _accessControls,
        StakingRewardsGuild _rewardsGuildBank,
        uint256 _tokenRewardPerBlock,
        uint256 _startBlock,
        address _cloneableServiceProviderContract
    ) {
        require(address(_accessControls) != address(0), "StakingRewards.constructor: Invalid access controls");
        require(address(_token) != address(0), "StakingRewards.constructor: Invalid token address");
        require(_cloneableServiceProviderContract != address(0), "StakingRewards.constructor: Invalid cloneable service provider");

        token = _token;
        accessControls = _accessControls;
        rewardsGuildBank = _rewardsGuildBank;
        tokenRewardPerBlock = _tokenRewardPerBlock;
        startBlock = _startBlock;
        cloneableServiceProviderContract = _cloneableServiceProviderContract;
    }

    // Update reward variables of the given programme to be up-to-date.
    function updateRewardProgramme(uint256 _programmeId) public {
        RewardProgramme storage rewardProgramme = rewardProgrammes[_programmeId];

        if (_getBlock() <= rewardProgramme.lastRewardBlock) {
            return;
        }

        uint256 totalStaked = rewardProgramme.totalStaked;

        if (totalStaked == 0) {
            rewardProgramme.lastRewardBlock = _getBlock();
            return;
        }

        uint256 blocksSinceLastReward = _getBlock().sub(rewardProgramme.lastRewardBlock);
        // we want to divide proportionally by all the tokens staked in the RPs, not to distribute first to RP
        // so what we want here is rewardProgramme.allocPoint.mul(rewardProgramme.totalStaked).div(the sum of the products of allocPoint times totalStake for each RP)
        uint256 rewardPerShare = blocksSinceLastReward.mul(tokenRewardPerBlock).mul(rewardProgramme.allocPoint).mul(1e18).div(weightedTotalCudosStaked);
        rewardProgramme.accTokensPerShare = rewardProgramme.accTokensPerShare.add(rewardPerShare);
        rewardProgramme.lastRewardBlock = _getBlock();
    }

    function getReward(uint256 _programmeId) external nonReentrant {
        updateRewardProgramme(_programmeId);
        _getReward(_programmeId);
    }

    function massUpdateRewardProgrammes() public {
        uint256 programmeLength = rewardProgrammes.length;
        for(uint256 i = 0; i < programmeLength; i++) {
            updateRewardProgramme(i);
        }
    }

    function getRewardWithMassUpdate(uint256 _programmeId) external nonReentrant {
        massUpdateRewardProgrammes();
        _getReward(_programmeId);
    }

    // stake CUDO in a specific reward programme that dictates a minimum lockup period
    function stake(uint256 _programmeId, address _from, uint256 _amount) external nonReentrant paused notZero(_amount) unkSP {
        RewardProgramme storage rewardProgramme = rewardProgrammes[_programmeId];
        UserInfo storage user = userInfo[_programmeId][_msgSender()];


        user.amount = user.amount.add(_amount);
        rewardProgramme.totalStaked = rewardProgramme.totalStaked.add(_amount);
        totalCudosStaked = totalCudosStaked.add(_amount);
        // weigted sum gets updated when new tokens are staked
        weightedTotalCudosStaked = weightedTotalCudosStaked.add(_amount.mul(rewardProgramme.allocPoint));

        user.rewardDebt = user.amount.mul(rewardProgramme.accTokensPerShare).div(1e18);

        token.safeTransferFrom(address(_from), address(rewardsGuildBank), _amount);
        emit Deposit(_from, _programmeId, _amount);
    }

    // Withdraw stake and rewards
    function withdraw(uint256 _programmeId, address _to, uint256 _amount) public nonReentrant paused notZero(_amount) unkSP {
        RewardProgramme storage rewardProgramme = rewardProgrammes[_programmeId];
        UserInfo storage user = userInfo[_programmeId][_msgSender()];

	// StakingRewards.withdraw: Amount exceeds balance
        require(user.amount >= _amount, "SRW1");

        user.amount = user.amount.sub(_amount);
        rewardProgramme.totalStaked = rewardProgramme.totalStaked.sub(_amount);
        totalCudosStaked = totalCudosStaked.sub(_amount);
        // weigted sum gets updated when new tokens are withdrawn
        weightedTotalCudosStaked = weightedTotalCudosStaked.sub(_amount.mul(rewardProgramme.allocPoint));

        user.rewardDebt = user.amount.mul(rewardProgramme.accTokensPerShare).div(1e18);

        rewardsGuildBank.withdrawTo(_to, _amount);
        emit Withdraw(_msgSender(), _programmeId, _amount);
    }

    function exit(uint256 _programmeId) external unkSP {
        withdraw(_programmeId, _msgSender(), userInfo[_programmeId][_msgSender()].amount);
    }

    // *****
    // View
    // *****

    function numberOfRewardProgrammes() external view returns (uint256) {
        return rewardProgrammes.length;
    }

    function getRewardProgrammeInfo(uint256 _programmeId) external view returns (
        uint256 minStakingLengthInBlocks,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accTokensPerShare,
        uint256 totalStaked
    ) {
        RewardProgramme storage rewardProgramme = rewardProgrammes[_programmeId];
        return (
        rewardProgramme.minStakingLengthInBlocks,
        rewardProgramme.allocPoint,
        rewardProgramme.lastRewardBlock,
        rewardProgramme.accTokensPerShare,
        rewardProgramme.totalStaked
        );
    }

    function amountStakedByUserInRewardProgramme(uint256 _programmeId, address _user) external view returns (uint256) {
        return userInfo[_programmeId][_user].amount;
    }

    function totalStakedInRewardProgramme(uint256 _programmeId) external view returns (uint256) {
        return rewardProgrammes[_programmeId].totalStaked;
    }

    function totalStakedAcrossAllRewardProgrammes() external view returns (uint256) {
        return totalCudosStaked;
    }

    // View function to see pending CUDOs on frontend.
    function pendingCudoRewards(uint256 _programmeId, address _user) external view returns (uint256) {
        RewardProgramme storage rewardProgramme = rewardProgrammes[_programmeId];
        UserInfo storage user = userInfo[_programmeId][_user];
        uint256 accTokensPerShare = rewardProgramme.accTokensPerShare;
        uint256 totalStaked = rewardProgramme.totalStaked;

        if (_getBlock() > rewardProgramme.lastRewardBlock && totalStaked != 0) {
            uint256 blocksSinceLastReward = _getBlock().sub(rewardProgramme.lastRewardBlock);
            // reward distribution is changed in line with the change within the updateRewardProgramme function
            uint256 rewardPerShare = blocksSinceLastReward.mul(tokenRewardPerBlock).mul(rewardProgramme.allocPoint).mul(1e18).div(weightedTotalCudosStaked);
            accTokensPerShare = accTokensPerShare.add(rewardPerShare);
        }

        return user.amount.mul(accTokensPerShare).div(1e18).sub(user.rewardDebt);
    }

    // proxy for service provider
    function hasAdminRole(address _caller) external view returns (bool) {
        return accessControls.hasAdminRole(_caller);
    }

    // *********
    // Whitelist
    // *********
    // methods that check for whitelist role in access controls are for any param changes that could be done via governance

    function updateMinRequiredStakingAmountForServiceProviders(uint256 _newValue) external whitelisted {
        require(_newValue < maxStakingAmountForServiceProviders, "StakingRewards.updateMinRequiredStakingAmountForServiceProviders: Min staking must be less than max staking amount");

        emit MinRequiredStakingAmountForServiceProvidersUpdated(minRequiredStakingAmountForServiceProviders, _newValue);

        minRequiredStakingAmountForServiceProviders = _newValue;
    }

    function updateMaxStakingAmountForServiceProviders(uint256 _newValue) external whitelisted {
        //require(accessControls.hasWhitelistRole(_msgSender()), "StakingRewards.updateMaxStakingAmountForServiceProviders: Only whitelisted");
        require(_newValue > minRequiredStakingAmountForServiceProviders, "StakingRewards.updateMaxStakingAmountForServiceProviders: Max staking must be greater than min staking amount");

        emit MaxStakingAmountForServiceProvidersUpdated(maxStakingAmountForServiceProviders, _newValue);

        maxStakingAmountForServiceProviders = _newValue;
    }

    function updateMinServiceProviderFee(uint256 _newValue) external whitelisted {
        //require(accessControls.hasWhitelistRole(_msgSender()), "StakingRewards.updateMinServiceProviderFee: Only whitelisted");
        require(_newValue > 0 && _newValue < PERCENTAGE_MODULO, "StakingRewards.updateMinServiceProviderFee: Fee percentage must be between zero and one");

        emit MinServiceProviderFeeUpdated(minServiceProviderFee, _newValue);

        minServiceProviderFee = _newValue;
    }

    // *****
    // Admin
    // *****

    function recoverERC20(address _erc20, address _recipient, uint256 _amount) external {
        // StakingRewards.recoverERC20: Only admin
        require(accessControls.hasAdminRole(_msgSender()), "OA");
        IERC20(_erc20).safeTransfer(_recipient, _amount);
    }

    function whitelistServiceProvider(address _serviceProvider) external {
        // StakingRewards.whitelistServiceProvider: Only admin
        require(accessControls.hasAdminRole(_msgSender()), "OA");
        require(serviceProviderToWhitelistedProxyContracts[_serviceProvider] == address(0), "StakingRewards.whitelistServiceProvider:  Already whitelisted service provider");
        address serviceProviderContract = createClone(cloneableServiceProviderContract);
        serviceProviderToWhitelistedProxyContracts[_serviceProvider] = serviceProviderContract;
        serviceProviderContractToServiceProvider[serviceProviderContract] = _serviceProvider;
        ServiceProvider(serviceProviderContract).init(_serviceProvider, token);

        emit ServiceProviderWhitelisted(_serviceProvider, serviceProviderContract);
    }

    function updateTokenRewardPerBlock(uint256 _tokenRewardPerBlock) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "StakingRewards.updateTokenRewardPerBlock: Only admin"
        );

        // If this is not done, any pending rewards could be potentially lost
        massUpdateRewardProgrammes();

        // Log old and new value
        emit RewardPerBlockUpdated(tokenRewardPerBlock, _tokenRewardPerBlock);

        // this is safe to be set to zero - it would effectively turn off all staking rewards
        tokenRewardPerBlock = _tokenRewardPerBlock;
    }

    // Admin - Add a rewards programme
    function addRewardsProgramme(uint256 _allocPoint, uint256 _minStakingLengthInBlocks, bool _withUpdate) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
	    // StakingRewards.addRewardsProgramme: Only admin
            "OA"
        );

        require(
            isActiveRewardProgramme[_minStakingLengthInBlocks] == false,
	    // StakingRewards.addRewardsProgramme: Programme is already active
            "PAA"
        );

        // StakingRewards.addRewardsProgramme: Invalid alloc point
        require(_allocPoint > 0, "IAP");

        if (_withUpdate) {
            massUpdateRewardProgrammes();
        }

        uint256 lastRewardBlock = _getBlock() > startBlock ? _getBlock() : startBlock;
        rewardProgrammes.push(
            RewardProgramme({
        minStakingLengthInBlocks: _minStakingLengthInBlocks,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accTokensPerShare: 0,
        totalStaked: 0
        })
        );

        isActiveRewardProgramme[_minStakingLengthInBlocks] = true;

        emit RewardProgrammeAdded(_allocPoint, _minStakingLengthInBlocks);
    }

    // Update the given reward programme's CUDO allocation point. Can only be called by admin.
    function updateAllocPointForRewardProgramme(uint256 _programmeId, uint256 _allocPoint, bool _withUpdate) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            // StakingRewards.updateAllocPointForRewardProgramme: Only admin
	    "OA"
        );

        if (_withUpdate) {
            massUpdateRewardProgrammes();
        }

        weightedTotalCudosStaked = weightedTotalCudosStaked.sub(rewardProgrammes[_programmeId].totalStaked.mul(rewardProgrammes[_programmeId].allocPoint));

        emit RewardProgrammeAllocPointUpdated(rewardProgrammes[_programmeId].allocPoint, _allocPoint);

        rewardProgrammes[_programmeId].allocPoint = _allocPoint;

        weightedTotalCudosStaked = weightedTotalCudosStaked.add(rewardProgrammes[_programmeId].totalStaked.mul(rewardProgrammes[_programmeId].allocPoint));
    }

    function updateUserActionsPaused(bool _isPaused) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            // StakingRewards.updateAllocPointForRewardProgramme: Only admin
	    "OA"
        );

        userActionsPaused = _isPaused;

        emit UserActionsPausedToggled(_isPaused);
    }

    // ********
    // Internal
    // ********

    function _getReward(uint256 _programmeId) internal {
        RewardProgramme storage rewardProgramme = rewardProgrammes[_programmeId];
        UserInfo storage user = userInfo[_programmeId][_msgSender()];

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(rewardProgramme.accTokensPerShare).div(1e18).sub(user.rewardDebt);
            if (pending > 0) {
                user.rewardDebt = user.amount.mul(rewardProgramme.accTokensPerShare).div(1e18);
                rewardsGuildBank.withdrawTo(_msgSender(), pending);
            }
        }
    }

    function _getBlock() public virtual view returns (uint256) {
        return block.number;
    }

    function _findMinStakingLength(uint256 _programmeId) external view returns (uint256) {
        RewardProgramme storage rewardProgramme = rewardProgrammes[_programmeId];
        uint256 minStakingLength = rewardProgramme.minStakingLengthInBlocks;
        return minStakingLength;
    }
}