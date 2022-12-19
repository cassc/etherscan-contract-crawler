pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakeRabBitcoin is Ownable {
    uint256 public constant DECIMAL = 10**30;

    ERC20 public stakeToken;
    ERC20 public distributionToken;

    uint256 public rewardPerBlock;

    uint256 public cumulativeSum;
    uint256 public lastUpdate;

    uint256 public totalPoolStaked;

    struct UserInfo {
        uint256 stakedAmount;
        uint256 lastCumulativeSum;
        uint256 aggregatedReward;
    }

    mapping(address => UserInfo) public userInfos;

    event TokensStaked(address _staker, uint256 _stakeAmount);
    event TokensWithdrawn(address _staker, uint256 _withdrawAmount);
    event RewardsClaimed(address _claimer, uint256 _rewardsAmount);

    constructor(
        address _stakeToken,
        address _distributioToken,
        uint256 _rewardPerBlock
    ) {
        stakeToken = ERC20(_stakeToken);
        distributionToken = ERC20(_distributioToken);
        rewardPerBlock = _rewardPerBlock;
    }

    modifier updateRewards() {
        _updateUserRewards(_updateCumulativeSum());
        _;
    }

    function updateRewardPerBlock(uint256 _newRewardPerBlock) external onlyOwner {
        _updateCumulativeSum();
        rewardPerBlock = _newRewardPerBlock;
    }

    function stake(uint256 _stakeAmount) external updateRewards {
        userInfos[msg.sender].stakedAmount += _stakeAmount;
        totalPoolStaked += _stakeAmount;

        stakeToken.transferFrom(msg.sender, address(this), _stakeAmount);

        emit TokensStaked(msg.sender, _stakeAmount);
    }

    function withdrawFunds(uint256 _amountToWithdraw) external updateRewards {
        uint256 _currentStakedAmount = userInfos[msg.sender].stakedAmount;

        require(
            _currentStakedAmount >= _amountToWithdraw,
            "TokenFarming: Not enough staked tokens to withdraw"
        );

        userInfos[msg.sender].stakedAmount = _currentStakedAmount - _amountToWithdraw;
        totalPoolStaked -= _amountToWithdraw;

        stakeToken.transfer(msg.sender, _amountToWithdraw);

        emit TokensWithdrawn(msg.sender, _amountToWithdraw);
    }

    function claimRewards() external updateRewards {
        uint256 _currentRewards = userInfos[msg.sender].aggregatedReward;

        require(_currentRewards > 0, "TokenFarming: Nothing to claim");

        delete userInfos[msg.sender].aggregatedReward;

        distributionToken.transfer(msg.sender, _currentRewards);

        emit RewardsClaimed(msg.sender, _currentRewards);
    }

    function _updateCumulativeSum() internal returns (uint256 _newCumulativeSum) {
        uint256 _totalPool = totalPoolStaked;
        uint256 _lastUpdate = lastUpdate;
        _lastUpdate = _lastUpdate == 0 ? block.number : _lastUpdate;

        if (_totalPool > 0) {
            _newCumulativeSum = _getNewCumulativeSum(
                rewardPerBlock,
                _totalPool,
                cumulativeSum,
                block.number - _lastUpdate
            );

            cumulativeSum = _newCumulativeSum;
        }

        lastUpdate = block.number;
    }

    function _getNewCumulativeSum(
        uint256 _rewardPerBlock,
        uint256 _totalPool,
        uint256 _prevAP,
        uint256 _blocksDelta
    ) internal pure returns (uint256) {
        uint256 _newPrice = (_rewardPerBlock * DECIMAL) / _totalPool;
        return _blocksDelta * _newPrice + _prevAP;
    }

    function _updateUserRewards(uint256 _newCumulativeSum) internal {
        UserInfo storage userInfo = userInfos[msg.sender];

        uint256 _currentUserStakedAmount = userInfo.stakedAmount;

        if (_currentUserStakedAmount > 0) {
            userInfo.aggregatedReward +=
                ((_newCumulativeSum - userInfo.lastCumulativeSum) * _currentUserStakedAmount) /
                DECIMAL;
        }

        userInfo.lastCumulativeSum = _newCumulativeSum;
    }

    function getLatestUserRewards(address _userAddr) external view returns (uint256) {
        uint256 _totalPool = totalPoolStaked;
        uint256 _lastUpdate = lastUpdate;

        uint256 _newCumulativeSum;

        _lastUpdate = _lastUpdate == 0 ? block.number : _lastUpdate;

        if (_totalPool > 0) {
            _newCumulativeSum = _getNewCumulativeSum(
                rewardPerBlock,
                _totalPool,
                cumulativeSum,
                block.number - _lastUpdate
            );
        }

        UserInfo memory userInfo = userInfos[_userAddr];

        uint256 _currentUserStakedAmount = userInfo.stakedAmount;
        uint256 _agregatedRewards;

        if (_currentUserStakedAmount > 0) {
            _agregatedRewards =
                userInfo.aggregatedReward +
                ((_newCumulativeSum - userInfo.lastCumulativeSum) * _currentUserStakedAmount) /
                DECIMAL;
        }

        return _agregatedRewards;
    }
}