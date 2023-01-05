// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract Ludicrous is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");

    uint256 private constant PRECISION = 1e18;

    struct UserInfo {
        uint256 amount; // amount of token user provided
        int256 rewardDebt;
    }

    struct RewardInfo {
        uint256 accRewardPerShare;
        uint256 lastRewardTimestamp;
        uint256 tokenPerSecond;
    }

    RewardInfo public rewardInfo; // poolInfo

    // user => user info
    mapping(address => UserInfo) public userInfo;

    IERC20Upgradeable public token;

    IERC20Upgradeable public rewardToken;

    uint256 public deadline;

    event UpdateRewardInfo(uint256 accRewardPerShare);
    event Deposit(uint256 amount, address to);
    event Withdraw(address user, uint256 amount);
    event Harvest(address user, uint256 pendingReward);

    function initialize(
        address admin,
        address setter,
        address pauser,
        address rewarder
    ) public initializer {
        __Pausable_init();
        __AccessControlEnumerable_init();

        rewardInfo = RewardInfo({
            accRewardPerShare: 0,
            lastRewardTimestamp: block.timestamp,
            tokenPerSecond: 0
        });

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UNPAUSER_ROLE, admin);
        _grantRole(SETTER_ROLE, setter);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(REWARDER_ROLE, rewarder);

        _pause();
    }

    function setAddresses(address _token, address _rewardToken)
        external
        onlyRole(SETTER_ROLE)
    {
        token = IERC20Upgradeable(_token);
        rewardToken = IERC20Upgradeable(_rewardToken);
    }

    function depositReward(uint256 amount, uint256 _deadline)
        external
        onlyRole(REWARDER_ROLE)
    {
        require(_deadline > block.timestamp, "DEADLINE_EXPIRED");

        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        deadline = _deadline;
        amount = rewardToken.balanceOf(address(this));

        rewardInfo.tokenPerSecond = amount / (deadline - block.timestamp);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }

    function getCurrentAccRewardPerShare() public view returns (uint256) {
        RewardInfo memory tokenRewardInfo = rewardInfo;
        uint256 tokenTotalSupply = token.totalSupply();

        uint256 delta;
        if (block.timestamp < deadline) {
            delta = block.timestamp - tokenRewardInfo.lastRewardTimestamp;
        } else {
            delta = 0;
        }

        if (tokenTotalSupply != 0) {
            uint256 reward = delta * tokenRewardInfo.tokenPerSecond;
            tokenRewardInfo.accRewardPerShare +=
                (reward * PRECISION) /
                tokenTotalSupply;
        }
        return tokenRewardInfo.accRewardPerShare;
    }

    function pendingReward(address _user)
        public
        view
        returns (uint256 accumulatedReward, uint256 pending)
    {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = getCurrentAccRewardPerShare();
        accumulatedReward = (user.amount * accRewardPerShare) / PRECISION;
        pending = uint256(int256(accumulatedReward) - user.rewardDebt);
    }

    function updateRewardInfo() public returns (RewardInfo memory) {
        RewardInfo storage tokenRewardInfo = rewardInfo;
        tokenRewardInfo.accRewardPerShare = getCurrentAccRewardPerShare();
        tokenRewardInfo.lastRewardTimestamp = block.timestamp;
        emit UpdateRewardInfo(rewardInfo.accRewardPerShare);
        return rewardInfo;
    }

    function deposit(uint256 _amount, address _to) external onlyToken {
        RewardInfo memory rewardInfo_ = updateRewardInfo();
        UserInfo storage userInfo_ = userInfo[_to];

        userInfo_.amount += _amount;
        userInfo_.rewardDebt += int256(
            (_amount * rewardInfo_.accRewardPerShare) / PRECISION
        );

        emit Deposit(_amount, _to);
    }

    function withdraw(address _from, uint256 _amount) external onlyToken {
        RewardInfo memory rewardInfo_ = updateRewardInfo();
        UserInfo storage userInfo_ = userInfo[_from];

        userInfo_.rewardDebt -= int256(
            (_amount * rewardInfo_.accRewardPerShare) / PRECISION
        );
        userInfo_.amount -= _amount;

        emit Withdraw(_from, _amount);
    }

    function harvest(address _to) public whenNotPaused {
        UserInfo storage userInfo_ = userInfo[msg.sender];

        (uint256 accumulatedReward, uint256 _pendingReward) = pendingReward(
            msg.sender
        );

        // Effects
        userInfo_.rewardDebt = int256(accumulatedReward);

        if (_pendingReward > 0) {
            rewardToken.safeTransfer(_to, _pendingReward);
            emit Harvest(msg.sender, _pendingReward);
        }
    }

    error OnlyToken();

    modifier onlyToken() {
        if (msg.sender != address(token)) revert OnlyToken();
        _;
    }
}