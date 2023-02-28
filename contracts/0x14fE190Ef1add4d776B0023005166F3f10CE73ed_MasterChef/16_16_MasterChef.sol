// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./IERC20MintableUpgradeable.sol";

/// @title A contract for staking USC and earn USC tokens with yearly ROI.
/// @author Huy Tran
contract MasterChef is Initializable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20MintableUpgradeable;

    /// @dev Information of each user that participated in the staking process
    struct UserInfo {
        uint256 amount; // How many staking tokens the user has provided.
        uint256 lastRewardTimestamp; // The last block that the reward was paid
        uint256 accumulatedRewards; // The rewards accumulated.
    }

    /// @dev The USC Token
    IERC20MintableUpgradeable public uscToken;

    /// @dev The sum of all USC staked in the MasterChef
    uint256 public totalStaked;

    /// @dev The ROI per year that each user gets for staking USC
    /// @notice ROI per year is fixed at 10% per year
    uint256 public roiPerYear;

    /// @dev mapping to save user staking info by user address
    mapping(address => UserInfo) public userInfo;

    /* ========== EVENTS ========== */
    event Deposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event ROIChanged(uint256 oldROIAmount, uint256 newROIAmount);

    /* ========== MODIFIERS ========== */

    modifier updateReward() {
        UserInfo storage user = userInfo[msg.sender];

        user.accumulatedRewards = earnedUSC(msg.sender);
        user.lastRewardTimestamp = block.timestamp;

        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev The initialize function for upgradeable smart contract's initialization phase
    function initialize(
        address _uscToken,
        uint256 _roiPerYear
    ) external initializer {
        require(_uscToken != address(0), "usc address must not be empty");

        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        uscToken = IERC20MintableUpgradeable(_uscToken);
        roiPerYear = _roiPerYear;
    }

    /// @dev Pause the smart contract in case of emergency
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev unpause the smart contract when everything is safe
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Withdraw USC tokens from MasterChef.
    /// @notice This function will work regardless of the pausing status to protect user's interest.
    function withdraw(uint256 _amount) external nonReentrant updateReward() {
        require(_amount > 0, "withdraw: cannot withdraw 0");

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: amount exceeds balance");

        user.amount -= _amount;
        totalStaked -= _amount;

        uscToken.safeTransfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }

    /// @dev Deposit USC tokens to MasterChef to stake for USC rewards
    /// @notice When the contract is paused, this function will not work as a safety mechanism for new users.
    function deposit(uint256 _amount) external whenNotPaused nonReentrant updateReward() {
        require (_amount > 0, "deposit: amount must be larger than 0");

        UserInfo storage user = userInfo[msg.sender];

        uscToken.safeTransferFrom(msg.sender, address(this), _amount);

        user.amount += _amount;
        totalStaked += _amount;

        emit Deposit(msg.sender, _amount);
    }

     /// @dev Withdraw the USC rewards that a user has accumulated over time.
    function getReward() external whenNotPaused nonReentrant updateReward() {
        UserInfo storage user = userInfo[msg.sender];

        uint256 rewardAmount = user.accumulatedRewards;
        if (rewardAmount > 0) {
            user.accumulatedRewards = 0;

            // Mint USC tokens to pay for reward
            uscToken.mint(address(this), rewardAmount);

            // Send rewards
            uscToken.safeTransfer(msg.sender, rewardAmount);

            emit RewardPaid(msg.sender, rewardAmount);
        }
    }

    /// @dev View function to see USC rewards of an address.
    function earnedUSC(address _userAddress) public view returns (uint256) {
        UserInfo storage user = userInfo[_userAddress];

        uint256 secondsInAYear = 365 days;
        uint256 timeDiff = block.timestamp - user.lastRewardTimestamp; // timediff in seconds
        uint256 newRewards = user.amount * roiPerYear * timeDiff / (secondsInAYear * 1e4);

        uint256 totalRewards = user.accumulatedRewards + newRewards;

        return totalRewards;
    }

    function _authorizeUpgrade(address)
        internal
        onlyOwner
        override
    {}
}