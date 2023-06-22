// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import "../interfaces/IVLPenpie.sol";
import "../interfaces/IMasterPenpie.sol";
import "../interfaces/IVLPenpieBaseRewarder.sol";

/// @title A contract for managing rewards for a pool
/// @author Magpie Team
/// @notice You can use this contract for getting informations about rewards for a specific pools
contract vlPenpieBaseRewarder is IVLPenpieBaseRewarder, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    IVLPenpie public vlPenpie; 

    /* ============ State Variables ============ */

    address public  stakingToken;
    address public  masterPenpie;    // master Penpie
    address public  rewardManager;    // pendle staking

    address[] public rewardTokens;
    
    struct Reward {
        address rewardToken;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
    }

    mapping(address => Reward) public rewards;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;                 
    mapping(address => mapping(address => uint256)) public userRewards;
    mapping(address => bool) public isRewardToken;
    mapping(address => bool) public managers;

    uint256 public constant vlPenpieDecimal = 18;

    /* ============ Events ============ */

    event RewardAdded(uint256 _reward, address indexed _token);
    event ForfeitRewardAdded(uint256 _reward, address indexed _token);
    event PenpieHarvested(address indexed _user, uint256 _userReceiveAmount, uint256 _forfeitAmount);
    event Staked(address indexed _user, uint256 _amount);
    event Withdrawn(address indexed _user, uint256 _amount);
    event RewardPaid(address indexed _user, address indexed _receiver, uint256 _reward, address indexed _token);
    event ManagerUpdated(address indexed _manager, bool _allowed);

    /* ============ Errors ============ */

    error OnlyManager();
    error OnlymasterPenpie();
    error NotAllowZeroAddress();
    error InvalidRewardableAmount();

    /* ============ Constructor ============ */

    function __vlPenpieBaseRewarder_init(
        address _vlPenpie,
        address _rewardToken,
        address _masterPenpie,
        address _rewardManager
    ) public initializer {
        __Ownable_init();
        if(
            _vlPenpie == address(0) ||
            _masterPenpie  == address(0) ||
            _rewardManager  == address(0)
        ) revert NotAllowZeroAddress();

        stakingToken = _vlPenpie;
        masterPenpie = _masterPenpie;
        managers[_rewardManager] = true;
        vlPenpie = IVLPenpie(_vlPenpie);

        if (_rewardToken != address(0)) {
            rewards[_rewardToken] = Reward({
                rewardToken: _rewardToken,
                rewardPerTokenStored: 0,
                queuedRewards: 0
            });
            rewardTokens.push(_rewardToken);
            isRewardToken[_rewardToken] = true;
        }
    }

    /* ============ Modifiers ============ */

    modifier updateRewards(address _account, address[] memory _rewards) {
        uint256 length = _rewards.length;
        uint256 userVlPenpieAmount = balanceOf(_account);
        
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = _rewards[index];
            if (userRewardPerTokenPaid[rewardToken][_account] == rewardPerToken(rewardToken))
                continue;

            userRewards[rewardToken][_account] = _earned(_account, rewardToken, userVlPenpieAmount);
            userRewardPerTokenPaid[rewardToken][_account] = rewardPerToken(rewardToken);
        }
        _;
    }

    modifier updateReward(address _account) {
        _updateFor(_account);
        _;
    }

    modifier onlyManager() {
        if (!managers[msg.sender])
            revert OnlyManager();
        _;
    }

    modifier onlymasterPenpie() {
        if (msg.sender != masterPenpie)
            revert OnlymasterPenpie();
        _;
    }

    /* ============ External Getters ============ */

    /// @notice Returns total current lock weighting, lock weighting is calculated by 
    /// amount of Penpie still in lock + amount of Penpie in cool down / 2
    /// @return Returns current amount of staked tokens
    function totalStaked() public override view returns (uint256) {
        return IERC20(address(vlPenpie)).totalSupply();
    }

    /// @notice Returns lock weighting of an user. Lock weighting is calculated by 
    /// amount of Penpie still in lock + amount of Penpie in cool down / 2
    /// @param _account Address account
    /// @return Returns amount of staked tokens by account
    function balanceOf(address _account) public override view returns (uint256) {
        (uint256 staked, ) =  IMasterPenpie(masterPenpie).stakingInfo(stakingToken, _account);
        return staked;
    }

    /// @notice Returns decimals of staking token
    /// @return Returns decimals of staking token
    function stakingDecimals() public override pure returns (uint256) {
        return vlPenpieDecimal;
    }

    /// @notice Returns amount of reward token per staking tokens in pool
    /// @param _rewardToken Address reward token
    /// @return Returns amount of reward token per staking tokens in pool
    function rewardPerToken(address _rewardToken)
        public
        override
        view
        returns (uint256)
    {
        return rewards[_rewardToken].rewardPerTokenStored;
    }

    function rewardTokenInfos()
        override
        external
        view
        returns
        (
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols
        )
    {
        uint256 rewardTokensLength = rewardTokens.length;
        bonusTokenAddresses = new address[](rewardTokensLength);
        bonusTokenSymbols = new string[](rewardTokensLength);
        for (uint256 i; i < rewardTokensLength; i++) {
            bonusTokenAddresses[i] = rewardTokens[i];
            bonusTokenSymbols[i] = IERC20Metadata(address(bonusTokenAddresses[i])).symbol();
        }
    }

    function calExpireForfeit(address _account, address _rewardToken) public view returns(uint256) {
        return _calExpireForfeit(_account, earned(_account, _rewardToken));
    }

    /// @notice Returns amount of reward token earned by a user
    /// @param _account Address account
    /// @param _rewardToken Address reward token
    /// @return Returns amount of reward token earned by a user
    function earned(address _account, address _rewardToken)
        public
        override
        view
        returns (uint256)
    {
        return _earned(_account, _rewardToken, balanceOf(_account));
    }

    /// @notice Returns amount of all reward tokens
    /// @param _account Address account
    /// @return pendingBonusRewards as amounts of all rewards.
    function allEarned(address _account)
        external
        override
        view
        returns (
            uint256[] memory pendingBonusRewards
        )
    {
        uint256 length = rewardTokens.length;
        pendingBonusRewards = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            pendingBonusRewards[i] = earned(_account, rewardTokens[i]);
        }

        return pendingBonusRewards;
    }

    /* ============ External Functions ============ */

    /// @notice Updates the reward information for one account
    /// @param _account Address account
    function updateFor(address _account) external override {
        _updateFor(_account);
    }

    function getReward(address _account, address _receiver)
        public
        onlymasterPenpie
        updateReward(_account)
        returns (bool)
    {
        uint256 length = rewardTokens.length;

        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            _sendReward(rewardToken, _account, _receiver);
        }

        return true;
    }

    function getRewards(address _account, address _receiver, address[] memory _rewardTokens)
        public
        onlymasterPenpie
        updateRewards(_account, _rewardTokens)
        nonReentrant
    {
        uint256 length = _rewardTokens.length;

        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = _rewardTokens[index];
            _sendReward(rewardToken, _account, _receiver);
        }
    }

    function getRewardLength() external view returns(uint256) {
        return rewardTokens.length;
    }

    /* ============ Admin Functions ============ */

    function updateRewardQueuer(address _rewardManager, bool _allowed) external onlyOwner {
        managers[_rewardManager] = _allowed;

        emit ManagerUpdated(_rewardManager, managers[_rewardManager]);
    }

    function queuePenpie(uint256 _amount, address _account, address _receiver) override external onlyManager nonReentrant returns (bool) {
        IERC20(vlPenpie.penpie()).safeTransferFrom(msg.sender, address(this), _amount);
        
        uint256 forfeitAmount = _calExpireForfeit(_account, _amount);
        uint256 rewardableAmount = _amount - forfeitAmount;
        
        if (forfeitAmount > 0)
            _queueNewRewardsWithoutTransfer(forfeitAmount, address(vlPenpie.penpie()));

        if (rewardableAmount > 0) {
            IERC20(vlPenpie.penpie()).safeTransfer(_receiver, rewardableAmount);
            emit PenpieHarvested(_account, rewardableAmount, forfeitAmount);
        }

        return true;
    }

    /// @notice Sends new rewards to be distributed to the users staking. Only callable by manager
    /// @param _amountReward Amount of reward token to be distributed
    /// @param _rewardToken Address reward token
    function queueNewRewards(uint256 _amountReward, address _rewardToken)
        override
        external
        onlyManager
        returns (bool)
    {
        if (!isRewardToken[_rewardToken]) {
            rewardTokens.push(_rewardToken);
            isRewardToken[_rewardToken] = true;
        }
        IERC20Metadata(_rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amountReward
        );
        Reward storage rewardInfo = rewards[_rewardToken];

        if (totalStaked() == 0) {
            rewardInfo.queuedRewards += _amountReward;
        } else {
            if (rewardInfo.queuedRewards > 0) {
                _amountReward += rewardInfo.queuedRewards;
                rewardInfo.queuedRewards = 0;
            }
            rewardInfo.rewardPerTokenStored =
                rewardInfo.rewardPerTokenStored +
                (_amountReward * 10**vlPenpieDecimal) / totalStaked();
        }
        emit RewardAdded(_amountReward, _rewardToken);
        return true;
    }

    /* ============ Internal Functions ============ */

    function _queueNewRewardsWithoutTransfer(uint256 _amountReward, address _rewardToken) internal
    {
        Reward storage rewardInfo = rewards[_rewardToken];
        if (totalStaked() == 0) {
            rewardInfo.queuedRewards += _amountReward;
        } else {
            if (rewardInfo.queuedRewards > 0) {
                _amountReward += rewardInfo.queuedRewards;
                rewardInfo.queuedRewards = 0;
            }
            rewardInfo.rewardPerTokenStored =
                rewardInfo.rewardPerTokenStored +
                (_amountReward * 10**vlPenpieDecimal) / totalStaked();
        }
        emit ForfeitRewardAdded(_amountReward, _rewardToken);
    }

    function _updateFor(address _account) internal {
        uint256 length = rewardTokens.length;
        uint256 userVlPenpieAmount = balanceOf(_account);

        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            if (userRewardPerTokenPaid[rewardToken][_account] == rewardPerToken(rewardToken))
                continue;

            userRewards[rewardToken][_account] = _earned(_account, rewardToken, userVlPenpieAmount);
            userRewardPerTokenPaid[rewardToken][_account] = rewardPerToken(rewardToken);
        }
    }

    function _sendReward(address _rewardToken, address _account, address _receiver) internal {
        uint256 forfeitAmount = _calExpireForfeit(_account, userRewards[_rewardToken][_account]);
        uint256 toSend = userRewards[_rewardToken][_account] - forfeitAmount;


        userRewards[_rewardToken][_account] = 0;
            
        if (toSend > 0) {
            IERC20(_rewardToken).safeTransfer(_receiver, toSend);
            emit RewardPaid(_account, _receiver, toSend, _rewardToken);
        }

        if(forfeitAmount > 0)
            _queueNewRewardsWithoutTransfer(forfeitAmount, _rewardToken);
    }

    function _earned(address _account, address _rewardToken, uint256 _userVlPenpieShare) internal view returns (uint256) {
        return ((_userVlPenpieShare *
                (rewardPerToken(_rewardToken) -
                    userRewardPerTokenPaid[_rewardToken][_account])) /
                10**vlPenpieDecimal) + userRewards[_rewardToken][_account];
    }

    function _calExpireForfeit(address _account, uint256 _amount) internal view returns (uint256) {
        uint256 rewardablePercentWAD = vlPenpie.getRewardablePercentWAD(_account);
        uint256 rewardableAmount = _amount * rewardablePercentWAD / 1e18;
        if (rewardableAmount > _amount)
            revert InvalidRewardableAmount();

        uint256 forfeitAmount = _amount - rewardableAmount;
        
        if (forfeitAmount < (_amount / 1000)) {  // if forfeitAmount is smaller than 0.1% ignore to save gas fee
            forfeitAmount = 0;
            rewardableAmount = _amount;
        }

        return forfeitAmount;
    }
}