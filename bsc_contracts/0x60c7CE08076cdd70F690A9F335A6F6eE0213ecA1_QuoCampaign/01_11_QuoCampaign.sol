// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "@shared/lib-contracts/contracts/Dependencies/ManagerUpgradeable.sol";

import "../Interfaces/IRewards.sol";

interface IQuoRewardPool is IRewards {
    function wom() external view returns (address);

    function qWomToken() external view returns (address);

    function rewardTokens() external view returns (address[] memory);

    function getReward(bool _stake) external;
}

contract QuoCampaign is ManagerUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant PRECISION = 1e6;

    address public wom;

    address public qWom;
    IERC20 public quo;
    IQuoRewardPool public quoRewardPool;

    uint256[] public releaseTimes;
    uint256[] public releasePercentages;

    uint256 public startTime;

    uint256 public totalSupply;

    struct UserInfo {
        uint256 amount;
        // last claimed index + 1, 0 means not claimed
        uint256 lastClaimedIndex;
    }

    struct UserReward {
        uint256 userRewardPerTokenPaid;
        uint256 rewards;
    }

    mapping(address => UserInfo) public userInfoMap;

    mapping(address => uint256) public rewardPerTokenStored;

    // user address => token address => userRewards
    mapping(address => mapping(address => UserReward)) public userRewards;

    // events
    event UserQuoAdded(address indexed _user, uint256 _amount);
    event QuoAdded(address indexed _operator, uint256 _number, uint256 _amount);
    event QuoClaimed(
        address indexed _user,
        uint256 _claimIndex,
        uint256 _amount
    );
    event RewardAdded(address indexed _rewardToken, uint256 _reward);
    event RewardPaid(
        address indexed _user,
        address indexed _rewardToken,
        uint256 _reward
    );

    function initialize() public initializer {
        __ManagerUpgradeable_init();
    }

    function setParams(
        address _quoRewardPool,
        uint256[] memory _releaseTimes,
        uint256[] memory _releasePercentage
    ) external onlyManager {
        require(address(quo) == address(0), "already set!");
        require(
            _releaseTimes.length == _releasePercentage.length &&
                _releaseTimes.length > 0,
            "invalid release length"
        );

        for (uint256 i = 0; i < _releaseTimes.length; i++) {
            if (i == 0) {
                require(
                    _releasePercentage[i] > 0,
                    "invalid release percentage"
                );
            } else {
                require(
                    _releaseTimes[i] > _releaseTimes[i - 1],
                    "invalid release time"
                );
                require(
                    _releasePercentage[i] > _releasePercentage[i - 1] &&
                        _releasePercentage[i] <= PRECISION,
                    "invalid release percentage"
                );
            }
            if (i == _releaseTimes.length - 1) {
                require(
                    _releasePercentage[i] == PRECISION,
                    "invalid last release percentage"
                );
            }
        }

        quoRewardPool = IQuoRewardPool(_quoRewardPool);

        wom = quoRewardPool.wom();
        qWom = quoRewardPool.qWomToken();
        quo = quoRewardPool.stakingToken();

        releaseTimes = _releaseTimes;
        releasePercentages = _releasePercentage;
    }

    modifier updateReward(address _user) {
        require(startTime != 0, "not started yet");

        if (totalSupply != 0) {
            address[] memory rewardTokens = getRewardTokens();
            uint256[] memory rewardTokensBalBefore = new uint256[](
                rewardTokens.length
            );
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                rewardTokensBalBefore[i] = IERC20(rewardTokens[i]).balanceOf(
                    address(this)
                );
            }

            // get rewards
            quoRewardPool.getReward(false);

            for (uint256 i = 0; i < rewardTokens.length; i++) {
                address rewardToken = rewardTokens[i];
                uint256 reward = IERC20(rewardToken)
                    .balanceOf(address(this))
                    .sub(rewardTokensBalBefore[i]);
                if (reward == 0) {
                    continue;
                }

                rewardPerTokenStored[rewardToken] = rewardPerTokenStored[
                    rewardToken
                ].add(reward.mul(1e18).div(totalSupply));

                emit RewardAdded(rewardToken, reward);
            }

            UserInfo memory userInfo = userInfoMap[msg.sender];

            if (userInfo.amount > 0 && userInfo.lastClaimedIndex == 0) {
                for (uint256 i = 0; i < rewardTokens.length; i++) {
                    address rewardToken = rewardTokens[i];

                    UserReward storage userReward = userRewards[_user][
                        rewardToken
                    ];

                    userReward.rewards = userReward.rewards.add(
                        userInfo
                            .amount
                            .mul(
                                rewardPerTokenStored[rewardToken].sub(
                                    userReward.userRewardPerTokenPaid
                                )
                            )
                            .div(1e18)
                    );
                    userReward.userRewardPerTokenPaid = rewardPerTokenStored[
                        rewardToken
                    ];
                }
            }
        }

        _;
    }

    function getReleaseTimes() external view returns (uint256[] memory) {
        return releaseTimes;
    }

    function getReleasePercentages() external view returns (uint256[] memory) {
        return releasePercentages;
    }

    function getRewardTokens() public view returns (address[] memory) {
        return quoRewardPool.getRewardTokens();
    }

    function addQuo(address[] memory _users, uint256[] memory _amounts)
        external
        onlyManager
    {
        require(address(quo) != address(0), "not setup");
        require(startTime == 0, "already started!");

        require(
            _users.length == _amounts.length && _users.length > 0,
            "invalid rewards"
        );

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _users.length; i++) {
            address user = _users[i];
            uint256 amount = _amounts[i];
            require(userInfoMap[user].amount == 0, "invalid user");
            require(amount > 0, "invalid amount");

            userInfoMap[user].amount = amount;
            totalAmount = totalAmount.add(amount);

            emit UserQuoAdded(user, amount);
        }

        quo.safeTransferFrom(msg.sender, address(this), totalAmount);
        totalSupply = totalSupply.add(totalAmount);

        emit QuoAdded(msg.sender, _users.length, totalAmount);
    }

    function start() external onlyManager {
        require(address(quo) != address(0), "not set!");
        require(startTime == 0, "already started");

        require(totalSupply > 0, "not rewards added");

        quo.safeApprove(address(quoRewardPool), 0);
        quo.safeApprove(address(quoRewardPool), totalSupply);
        quoRewardPool.stake(totalSupply);

        startTime = block.timestamp;
    }

    function getClaimableAmount(address _user) external view returns (uint256) {
        // not started yet
        if (startTime == 0) {
            return 0;
        }

        UserInfo memory userInfo = userInfoMap[_user];

        (, uint256 claimableAmount) = _getClaimableIndexAndAmount(userInfo);
        return claimableAmount;
    }

    function claim() external updateReward(msg.sender) {
        UserInfo memory userInfo = userInfoMap[msg.sender];

        (
            uint256 claimIndex,
            uint256 claimableAmount
        ) = _getClaimableIndexAndAmount(userInfo);
        if (claimableAmount == 0) {
            return;
        }

        // withdraw user all quo from QuoRewardPool
        if (userInfo.lastClaimedIndex == 0) {
            quoRewardPool.withdraw(userInfo.amount);
            totalSupply = totalSupply.sub(userInfo.amount);
        }

        quo.safeTransfer(msg.sender, claimableAmount);
        userInfoMap[msg.sender].lastClaimedIndex = claimIndex;

        _getReward(msg.sender);

        emit QuoClaimed(msg.sender, claimIndex, claimableAmount);
    }

    function earned(address _user, address _rewardToken)
        external
        view
        returns (uint256)
    {
        if (startTime == 0 || totalSupply == 0) {
            return 0;
        }

        UserInfo memory userInfo = userInfoMap[_user];
        // user has no quo or has claimed
        if (userInfo.amount == 0 || userInfo.lastClaimedIndex > 0) {
            return 0;
        }
        return
            userInfo
                .amount
                .mul(
                    rewardPerTokenStored[_rewardToken]
                        .add(
                            quoRewardPool
                                .earned(address(this), _rewardToken)
                                .mul(1e18)
                                .div(totalSupply)
                        )
                        .sub(
                            userRewards[_user][_rewardToken]
                                .userRewardPerTokenPaid
                        )
                )
                .div(1e18);
    }

    function getReward() external updateReward(msg.sender) {
        _getReward(msg.sender);
    }

    function _getReward(address _user) internal {
        address[] memory rewardTokens = getRewardTokens();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            uint256 reward = userRewards[_user][rewardToken].rewards;
            if (reward == 0) {
                continue;
            }

            userRewards[_user][rewardToken].rewards = 0;

            IERC20(rewardToken).safeTransfer(_user, reward);

            emit RewardPaid(_user, rewardToken, reward);
        }
    }

    function _getClaimableIndexAndAmount(UserInfo memory _userInfo)
        internal
        view
        returns (uint256, uint256)
    {
        if (_userInfo.amount == 0) {
            return (0, 0);
        }

        uint256 claimIndex = _userInfo.lastClaimedIndex;
        while (
            claimIndex < releaseTimes.length &&
            block.timestamp >= startTime.add(releaseTimes[claimIndex])
        ) {
            claimIndex++;
        }

        if (claimIndex == _userInfo.lastClaimedIndex) {
            return (claimIndex, 0);
        }

        return (
            claimIndex,
            _userInfo
                .amount
                .mul(
                    releasePercentages[claimIndex.sub(1)].sub(
                        _userInfo.lastClaimedIndex == 0
                            ? 0
                            : releasePercentages[
                                _userInfo.lastClaimedIndex.sub(1)
                            ]
                    )
                )
                .div(PRECISION)
        );
    }
}