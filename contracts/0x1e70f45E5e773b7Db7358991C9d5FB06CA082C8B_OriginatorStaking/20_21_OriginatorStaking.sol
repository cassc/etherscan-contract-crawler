// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import './bases/staking/StakingRewards.sol';
import './bases/BaseTokenUpgradeable.sol';
import './bases/staking/interfaces/IOriginatorStaking.sol';
import '../reserve/IReserve.sol';
import '../utils/SafeMathUint128.sol';

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/Initializable.sol';


/**
 * @title  OriginatorStaking
 * @notice Contract to stake Originator Hub tokens, tokenize the position and get rewards, inheriting from a distribution manager contract
 * @author Aave / Ethichub
 **/
contract OriginatorStaking is Initializable, StakingRewards, BaseTokenUpgradeable, IStaking, IProjectFundedRewards, IOriginatorManager {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using SafeMathUint128 for uint128;

    enum OriginatorStakingState {
        UNINITIALIZED,
        STAKING,
        STAKING_END,
        DEFAULT
    }

    OriginatorStakingState public state;

    IERC20Upgradeable public STAKED_TOKEN;

    /// @notice IReserve to pull from the rewards, needs to have this contract as WITHDRAW role
    IReserve public REWARDS_VAULT;

    bytes32 public constant GOVERNANCE_ROLE = keccak256('GOVERNANCE_ROLE');
 
    uint256 public stakingGoal;
    uint256 public defaultedAmount;

    mapping(address => uint256) public stakerRewardsToClaim;

    bytes32 public constant ORIGINATOR_ROLE = keccak256('ORIGINATOR_ROLE');
    bytes32 public constant AUDITOR_ROLE = keccak256('AUDITOR_ROLE');

    uint256 public DEFAULT_DATE;

    mapping(bytes32 => uint256) public proposerBalances;

    event StateChange(uint256 state);

    event Staked(address indexed from, address indexed onBehalfOf, uint256 amount);
    event Redeem(address indexed from, address indexed to, uint256 amount);
    
    event Withdraw(address indexed proposer, uint256 amount);

    event RewardsAccrued(address user, uint256 amount);
    event RewardsClaimed(address indexed from, address indexed to, uint256 amount);

    event StartRewardsProjectFunded(uint128 previousEmissionPerSecond, uint128 extraEmissionsPerSecond, address lendingContractAddress);
    event EndRewardsProjectFunded(uint128 restoredEmissionsPerSecond, uint128 extraEmissionsPerSecond, address lendingContractAddress);

    modifier onlyGovernance() {
        require(hasRole(GOVERNANCE_ROLE, msg.sender), 'ONLY_GOVERNANCE');
        _;
    }

    modifier onlyEmissionManager() {
        require(hasRole(EMISSION_MANAGER_ROLE, msg.sender), 'ONLY_EMISSION_MANAGER');
        _;
    }

    modifier onlyOnStakingState() {
        require(state == OriginatorStakingState.STAKING, 'ONLY_ON_STAKING_STATE');
        _;
    }

    modifier notZeroAmount(uint256 _amount) {
        require(_amount > 0, 'INVALID_ZERO_AMOUNT');
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        IERC20Upgradeable _lockedToken,
        IReserve _rewardsVault,
        address _emissionManager,
        uint128 _distributionDuration
    ) public initializer {
        __BaseTokenUpgradeable_init(
            msg.sender,
            0,
            _name,
            _symbol,
            _name
        );
        __StakingRewards_init(_emissionManager, _distributionDuration);
        STAKED_TOKEN = _lockedToken;
        REWARDS_VAULT = _rewardsVault;
        _changeState(OriginatorStakingState.UNINITIALIZED);
    }

    /**
     * @notice Function to set up proposers (originator and auditor)
     * in proposal period.
     * @param _auditor address
     * @param _originator address
     * @param _auditorPercentage uint256 (value * 100 e.g. 20% == 2000)
     * @param _originatorPercentage uint256 (value * 100 e.g. 20% == 2000)
     * @param _stakingGoal uint256 wei amount in Ethix
     * @param _defaultDelay uint256 seconds
     */
    function setUpTerms(
        address _auditor, 
        address _originator,
        address _governance,
        uint256 _auditorPercentage, 
        uint256 _originatorPercentage, 
        uint256 _stakingGoal,
        uint256 _defaultDelay
    ) external override notZeroAmount(_stakingGoal) onlyEmissionManager {
        require(_auditor != _originator, 'PROPOSERS_CANNOT_BE_THE_SAME');
        require(_auditorPercentage != 0 && _originatorPercentage != 0, 'INVALID_PERCENTAGE_ZERO');
        require(state == OriginatorStakingState.UNINITIALIZED, 'ONLY_ON_UNINITILIZED_STATE');

        _setupRole(AUDITOR_ROLE, _auditor);
        _setupRole(ORIGINATOR_ROLE, _originator);
        _setupRole(GOVERNANCE_ROLE, _governance);
            
        _depositProposer(_auditor, _auditorPercentage, _stakingGoal);
        _depositProposer(_originator, _originatorPercentage, _stakingGoal);
        stakingGoal = _stakingGoal;
        DEFAULT_DATE = _defaultDelay.add(DISTRIBUTION_END);
        _changeState(OriginatorStakingState.STAKING);
    }

    /**
     * @notice Function to renew terms in STAKING_END or DEFAULT period.
     * @param _newAuditorPercentage uint256 (value * 100 e.g. 20% == 2000)
     * @param _newOriginatorPercentage uint256 (value * 100 e.g. 20% == 2000)
     * @param _newStakingGoal uint256 wei amount in Ethix
     * @param _newDistributionDuration uint128 seconds (e.g. 365 days == 31536000)
     * @param _newDefaultDelay uint256 seconds (e.g 90 days == 7776000)
     */
    function renewTerms(
        uint256 _newAuditorPercentage,
        uint256 _newOriginatorPercentage,
        uint256 _newStakingGoal,
        uint128 _newDistributionDuration,
        uint256 _newDefaultDelay) external override notZeroAmount(_newStakingGoal) onlyGovernance {
        require(state == OriginatorStakingState.STAKING_END || state == OriginatorStakingState.DEFAULT, 'INVALID_STATE');
        DISTRIBUTION_END = block.timestamp.add(_newDistributionDuration);
        _depositProposer(getRoleMember(AUDITOR_ROLE, 0), _newAuditorPercentage, _newStakingGoal);
        _depositProposer(getRoleMember(ORIGINATOR_ROLE, 0), _newOriginatorPercentage, _newStakingGoal);
        stakingGoal = _newStakingGoal;
        DEFAULT_DATE = _newDefaultDelay.add(DISTRIBUTION_END);
        _changeState(OriginatorStakingState.STAKING);
    }

    /**
     * @notice Function to stake tokens
     * @param _onBehalfOf Address to stake to
     * @param _amount Amount to stake
     **/
    function stake(address _onBehalfOf, uint256 _amount) external override notZeroAmount(_amount) onlyOnStakingState {
        require(!hasReachedGoal(), 'GOAL_HAS_REACHED');

        if (STAKED_TOKEN.balanceOf(address(this)).add(_amount) > stakingGoal) {
            _amount = stakingGoal.sub(STAKED_TOKEN.balanceOf(address(this)));
        }
        uint256 balanceOfUser = balanceOf(_onBehalfOf);
        uint256 accruedRewards =
            _updateUserAssetInternal(_onBehalfOf, address(this), balanceOfUser, totalSupply());
        if (accruedRewards != 0) {
            emit RewardsAccrued(_onBehalfOf, accruedRewards);
            stakerRewardsToClaim[_onBehalfOf] = stakerRewardsToClaim[_onBehalfOf].add(accruedRewards);
        }

        _mint(_onBehalfOf, _amount);
        IERC20Upgradeable(STAKED_TOKEN).safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _onBehalfOf, _amount);
    }

    /**
     * @dev Redeems staked tokens, and stop earning rewards
     * @param _to Address to redeem to
     * @param _amount Amount to redeem
     **/
    function redeem(address _to, uint256 _amount) external override notZeroAmount(_amount) {
        require(_checkRedeemEligibilityState(), 'WRONG_STATE');
        require(balanceOf(msg.sender) != 0, 'SENDER_BALANCE_ZERO');

        uint256 balanceOfMessageSender = balanceOf(msg.sender);

        uint256 amountToRedeem =
            (_amount > balanceOfMessageSender) ? balanceOfMessageSender : _amount;

        _updateCurrentUnclaimedRewards(msg.sender, balanceOfMessageSender, true);

        _burn(msg.sender, amountToRedeem);

        IERC20Upgradeable(STAKED_TOKEN).safeTransfer(_to, amountToRedeem);

        emit Redeem(msg.sender, _to, amountToRedeem);
    }

    /**
     * @notice method to withdraw deposited amount.
     * @param _amount Amount to withdraw
     */
    function withdrawProposerStake(uint256 _amount) external override {
        require(state == OriginatorStakingState.STAKING_END, 'ONLY_ON_STAKING_END_STATE');
        bytes32 senderRole = 0x00;
        
        if (msg.sender == getRoleMember(ORIGINATOR_ROLE, 0)) {
            senderRole = ORIGINATOR_ROLE;
        } else if (msg.sender == getRoleMember(AUDITOR_ROLE, 0)) {
            senderRole = AUDITOR_ROLE;
        } else {
            revert('WITHDRAW_PERMISSION_DENIED');
        }
        require(proposerBalances[senderRole] != 0, 'INVALID_ZERO_AMOUNT');

        uint256 amountToWithdraw =
            (_amount > proposerBalances[senderRole]) ? proposerBalances[senderRole] : _amount;

        proposerBalances[senderRole] = proposerBalances[senderRole].sub(amountToWithdraw);
        IERC20Upgradeable(STAKED_TOKEN).safeTransfer(msg.sender, amountToWithdraw);
        emit Withdraw(msg.sender, amountToWithdraw);
    }

    /**
     * @dev Claims an `amount` from Rewards reserve to the address `to`
     * @param _to Address to stake for
     * @param _amount Amount to stake
     **/
    function claimRewards(address payable _to, uint256 _amount) external override {
        uint256 newTotalRewards = _updateCurrentUnclaimedRewards(msg.sender, balanceOf(msg.sender), false);
        uint256 amountToClaim = (_amount == type(uint256).max) ? newTotalRewards : _amount;

        stakerRewardsToClaim[msg.sender] = newTotalRewards.sub(amountToClaim, 'INVALID_AMOUNT');
        require(REWARDS_VAULT.transfer(_to, amountToClaim), 'ERROR_TRANSFER_FROM_VAULT');

        emit RewardsClaimed(msg.sender, _to, amountToClaim);
    }

    /**
     * Function to add an extra emissions per second corresponding to staker rewards when a lending project by this originator
     * is funded.
     * @param _extraEmissionsPerSecond  emissions per second to be added to current ones.
     * @param _lendingContractAddress lending contract address is relationated with this rewards
     */
    function startProjectFundedRewards(uint128 _extraEmissionsPerSecond, address _lendingContractAddress) external override onlyOnStakingState {
        AssetData storage currentDistribution = assets[address(this)];
        uint128 currentEmission = currentDistribution.emissionPerSecond;

        uint128 newEmissionsPerSecond = currentDistribution.emissionPerSecond.add(_extraEmissionsPerSecond);
        DistributionTypes.AssetConfigInput[] memory newAssetConfig = new DistributionTypes.AssetConfigInput[](1);
        newAssetConfig[0] = DistributionTypes.AssetConfigInput({
            emissionPerSecond: newEmissionsPerSecond,
            totalStaked: totalSupply(),
            underlyingAsset: address(this)
        });
        configureAssets(newAssetConfig);

        emit StartRewardsProjectFunded(currentEmission, _extraEmissionsPerSecond, _lendingContractAddress);
    }

    /**
     * Function to end extra emissions per second corresponding to staker rewards when a lending project by this originator
     * is funded.
     * @param _extraEmissionsPerSecond  emissions per second to be added to current ones.
     * @param _lendingContractAddress lending contract address is relationated with this rewards.
     */
    function endProjectFundedRewards(uint128 _extraEmissionsPerSecond, address _lendingContractAddress) external override onlyOnStakingState {
        AssetData storage currentDistribution = assets[address(this)];
        uint128 currentEmission = currentDistribution.emissionPerSecond;
        uint128 newEmissionsPerSecond = currentDistribution.emissionPerSecond.sub(_extraEmissionsPerSecond);
        DistributionTypes.AssetConfigInput[] memory newAssetConfig = new DistributionTypes.AssetConfigInput[](1);
        newAssetConfig[0] = DistributionTypes.AssetConfigInput({
            emissionPerSecond: newEmissionsPerSecond,
            totalStaked: totalSupply(),
            underlyingAsset: address(this)
        });
        configureAssets(newAssetConfig);
        emit EndRewardsProjectFunded(currentEmission, _extraEmissionsPerSecond, _lendingContractAddress);
    }

    /**
     * @notice Amount to substract of the contract when state is default 
     * @param _amount amount to substract
     * @param _role role to substract the amount (Originator, Auditor)
     */
    function liquidateProposerStake(uint256 _amount, bytes32 _role) external override notZeroAmount(_amount) onlyGovernance {
        require(state == OriginatorStakingState.DEFAULT, 'ONLY_ON_DEFAULT');
        require(_role == AUDITOR_ROLE || _role == ORIGINATOR_ROLE, 'INVALID_PROPOSER_ROLE');
        proposerBalances[_role] = proposerBalances[_role].sub(_amount, 'INVALID_LIQUIDATE_AMOUNT');
        IERC20Upgradeable(STAKED_TOKEN).safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Function to declare contract on staking end state
     * Only governance could change to this state
     **/
    function declareStakingEnd() external override onlyGovernance onlyOnStakingState {
        _endDistributionIfNeeded();
        _changeState(OriginatorStakingState.STAKING_END);
    }

    /**
     * @notice Function to declare as DEFAULT
     * @param _defaultedAmount uint256
     **/
    function declareDefault(uint256 _defaultedAmount) external override onlyGovernance onlyOnStakingState {
        require(block.timestamp >= DEFAULT_DATE, 'DEFAULT_DATE_NOT_REACHED');
        defaultedAmount = _defaultedAmount;
        _endDistributionIfNeeded();
        _changeState(OriginatorStakingState.DEFAULT);
    }

    /**
     * @dev Return the total rewards pending to claim by an staker
     * @param _staker The staker address
     * @return The rewards
     */
    function getTotalRewardsBalance(address _staker) external override view returns (uint256) {
        DistributionTypes.UserStakeInput[] memory userStakeInputs =
            new DistributionTypes.UserStakeInput[](1);
        userStakeInputs[0] = DistributionTypes.UserStakeInput({
            underlyingAsset: address(this),
            stakedByUser: balanceOf(_staker),
            totalStaked: totalSupply()
        });
        return stakerRewardsToClaim[_staker].add(_getUnclaimedRewards(_staker, userStakeInputs));
    }

    /**
     * @notice Check if fulfilled the objective (Only valid on STAKING state!!)
     */
    function hasReachedGoal() public override notZeroAmount(stakingGoal) view returns (bool) {
        if (proposerBalances[ORIGINATOR_ROLE].add(proposerBalances[AUDITOR_ROLE]).add(totalSupply()) >= stakingGoal) {
            return true;
        }
        return  false;
    }

    /**
     * @notice Function to transfer participation amount (originator or auditor)
     */
    function _depositProposer(address _proposer, uint256 _percentage, uint256 _goalAmount) internal {
        uint256 percentageAmount = _calculatePercentage(_goalAmount, _percentage);
        uint256 depositAmount = 0;

        if (_proposer == getRoleMember(ORIGINATOR_ROLE, 0)) {
            depositAmount = _calculateDepositAmount(ORIGINATOR_ROLE, percentageAmount);
            proposerBalances[ORIGINATOR_ROLE] = proposerBalances[ORIGINATOR_ROLE].add(depositAmount);
        } else if (_proposer == getRoleMember(AUDITOR_ROLE, 0)) {
            depositAmount = _calculateDepositAmount(AUDITOR_ROLE, percentageAmount);
            proposerBalances[AUDITOR_ROLE] = proposerBalances[AUDITOR_ROLE].add(depositAmount);
        }
        IERC20Upgradeable(STAKED_TOKEN).safeTransferFrom(_proposer, address(this), depositAmount);
    }

    /**
     * @dev Internal ERC20 _transfer of the tokenized staked tokens
     * @param _from Address to transfer from
     * @param _to Address to transfer to
     * @param _amount Amount to transfer
     **/
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        uint256 balanceOfFrom = balanceOf(_from);
        // Sender
        _updateCurrentUnclaimedRewards(_from, balanceOfFrom, true);

        // Recipient
        if (_from != _to) {
            uint256 balanceOfTo = balanceOf(_to);
            _updateCurrentUnclaimedRewards(_to, balanceOfTo, true);
        }

        super._transfer(_from, _to, _amount);
    }

    /** 
     * @dev Check if the state of contract is suitable to redeem
     */
    function _checkRedeemEligibilityState() internal view returns (bool) {
        if (state == OriginatorStakingState.STAKING_END) {
            return true;
        } else if (state == OriginatorStakingState.DEFAULT && defaultedAmount <= proposerBalances[ORIGINATOR_ROLE].add(proposerBalances[AUDITOR_ROLE])) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Updates the user state related with his accrued rewards
     * @param _user Address of the user
     * @param _userBalance The current balance of the user
     * @param _updateStorage Boolean flag used to update or not the stakerRewardsToClaim of the user
     * @return The unclaimed rewards that were added to the total accrued
     **/
    function _updateCurrentUnclaimedRewards(
        address _user,
        uint256 _userBalance,
        bool _updateStorage
    ) internal returns (uint256) {
        uint256 accruedRewards =
            _updateUserAssetInternal(_user, address(this), _userBalance, totalSupply());
        uint256 unclaimedRewards = stakerRewardsToClaim[_user].add(accruedRewards);

        if (accruedRewards != 0) {
            if (_updateStorage) {
                stakerRewardsToClaim[_user] = unclaimedRewards;
            }
            emit RewardsAccrued(_user, accruedRewards);
        }

        return unclaimedRewards;
    }

    /**
     * @notice Function to calculate a percentage of an amount
     * @param _amount Amount to calculate the percentage of
     * @param _percentage Percentage to calculate of this amount
     * @return (amount)
     */
    function _calculatePercentage(uint256 _amount, uint256 _percentage) internal pure returns (uint256) {
        return uint256(_amount.mul(_percentage).div(10000));
    }

    /**
     * @notice Function to get the actual participation amount
     * of proposers according the amount that already exists in the contract
     * @param _role Auditor or originator role
     * @param _percentageAmount Percentage of staking goal amount
     * Note _percentageAmount SHOULD BE GREATER than the previously existing amount
     */
    function _calculateDepositAmount(bytes32 _role, uint256 _percentageAmount) internal view returns (uint256){
        return uint256(_percentageAmount.sub(proposerBalances[_role]));
    }

    /**
     * @notice Function to change contract state
     * @param _newState New contract state
     **/
    function _changeState(OriginatorStakingState _newState) internal {
        state = _newState;
        emit StateChange(uint256(_newState));
    }

    /**
     * @notice Function to change DISTRIBUTION_END if timestamp is less than the initial one
     **/
    function _endDistributionIfNeeded() internal {
        if (block.timestamp <= DISTRIBUTION_END) {
            _changeDistributionEndDate(block.timestamp);
        }
    }
}