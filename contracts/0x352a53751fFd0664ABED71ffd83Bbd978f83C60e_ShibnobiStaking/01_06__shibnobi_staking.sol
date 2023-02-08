pragma solidity ^0.8.17;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

error InsufficientBalance(uint256 availableAmount, uint256 requiredAmount);
error NotYetStarted();
error AlreadyStarted();
error AlreadyFinished();

interface IDecimals {
    function decimals() external view returns (uint8);
}

contract ShibnobiStaking is Ownable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 startTime;
        uint256 totalRewards;
    }

    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public lastRewardTimestamp;
    uint256 public accTokenPerShare;
    uint256 public rewardPerSecond;
    uint256 public rewardSupply;

    uint8 public stakingDecimals;
    uint8 public rewardDecimals;

    mapping(address => UserInfo) public userInfo;
    uint256 public totalStaked;
    uint256 public usersStaking;

    uint256 public startTime;
    bool public started;
    bool public finished;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(address _stakingToken, address _rewardToken, uint256 _rewardPerSecond) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardPerSecond = _rewardPerSecond;
        stakingDecimals = IDecimals(_stakingToken).decimals();
        rewardDecimals = IDecimals(_rewardToken).decimals();
    }

    function pendingRewards(address _user) external view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        uint256 _accTokenPerShare = accTokenPerShare;
        uint256 balance = totalStaked;
        if (block.timestamp > lastRewardTimestamp && balance != 0) {
            uint256 tokenReward = (block.timestamp - lastRewardTimestamp) * rewardPerSecond;
            _accTokenPerShare += (tokenReward * 1e36 / balance);
        }
        return (user.amount * _accTokenPerShare / 1e36) - user.rewardDebt;
    }

    function updatePool() public {
        uint256 timestamp = block.timestamp;
        if (!started) {
            revert NotYetStarted();
        }
        if (timestamp <= lastRewardTimestamp) {
            return;
        }
        uint256 _totalStaked = totalStaked;
        if (_totalStaked == 0) {
            lastRewardTimestamp = timestamp;
            return;
        }
        uint256 reward = (timestamp - lastRewardTimestamp) * rewardPerSecond;
        accTokenPerShare += (reward * 1e36 / _totalStaked);
        lastRewardTimestamp = timestamp;
        rewardSupply += reward;
    }

    function _claimRewards(uint256 amount, uint256 rewardDebt) internal returns (uint256 amountToSend) {
        uint256 totalRewards = (amount * accTokenPerShare / 1e36) - rewardDebt;
        uint bal = rewardToken.balanceOf(address(this));
        if (stakingToken == rewardToken) {
            bal -= totalStaked;
        }
        amountToSend = totalRewards > bal ? bal : totalRewards;
        IERC20(rewardToken).transfer(msg.sender, amountToSend);
        rewardSupply -= totalRewards;
        emit RewardClaimed(msg.sender, totalRewards);
    }

    function deposit(uint256 _tokenAmount) external {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 amountTransferred = _claimRewards(user.amount, user.rewardDebt);
            user.totalRewards += amountTransferred;
        } else {
            usersStaking++;
        }
        if (_tokenAmount > 0) {
            stakingToken.safeTransferFrom(address(msg.sender), address(this), _tokenAmount);
            //for apy calculations
            if (user.amount == 0) {
                user.startTime = block.timestamp;
                user.totalRewards = 0;
            }
            //update balances
            user.amount += _tokenAmount;
            totalStaked += _tokenAmount;
            emit Deposit(msg.sender, _tokenAmount);
        }
        user.rewardDebt = user.amount * accTokenPerShare / 1e36;
    }

    function withdraw(uint256 _tokenAmount) external {
        UserInfo storage user = userInfo[msg.sender];
        if (_tokenAmount > user.amount) {
            revert InsufficientBalance(user.amount, _tokenAmount);
        }
        updatePool();
        if (user.amount > 0) {
            uint256 amountTransferred = _claimRewards(user.amount, user.rewardDebt);
            user.totalRewards += amountTransferred;
        }
        if (_tokenAmount > 0) {
            user.amount -= _tokenAmount;
            stakingToken.safeTransfer(address(msg.sender), _tokenAmount);
            totalStaked -= _tokenAmount;
            emit Withdraw(msg.sender, _tokenAmount);
            if (user.amount == 0 && usersStaking > 0) {
                usersStaking--;
            }
        }
        user.rewardDebt = user.amount * accTokenPerShare / 1e36;
    }

    function setRewardRate(uint256 _rewardPerSecond) external onlyOwner {
        if (finished) {
            revert AlreadyFinished();
        }
        rewardPerSecond = _rewardPerSecond;
    }

    function startPool(uint256 _startTime) external onlyOwner {
        if (started) {
            revert AlreadyStarted();
        }
        started = true;
        startTime = _startTime;
        lastRewardTimestamp = _startTime;
    }

    function apy() public view returns (uint256) {
        if (totalStaked == 0) {
            return 0;
        }
        return (10 ** stakingDecimals * rewardPerSecond * 86400 * 365 / totalStaked) - 10 ** stakingDecimals;
    }

    function info() external view returns (uint256, uint256, uint256, address, address, uint8, uint8) {
        return (
            totalStaked,
            usersStaking,
            apy(),
            address(stakingToken),
            address(rewardToken),
            stakingDecimals,
            rewardDecimals
        );
    }

    function finishPool() external onlyOwner {
        if (finished) {
            revert AlreadyFinished();
        }
        finished = true;
        updatePool();
        rewardPerSecond = 0;
        if (rewardToken == stakingToken) {
            if (totalStaked > rewardSupply) {
                IERC20(stakingToken).transfer(owner(), totalStaked - rewardSupply);
            }
        } else {
            if (rewardSupply > 0) {
                IERC20(rewardToken).transfer(owner(), rewardSupply);
            }
        }
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTokens(IERC20 tokenAddress, address walletAddress)
        external
        onlyOwner
    {
        require(
            walletAddress != address(0),
            "walletAddress can't be 0 address"
        );
        SafeERC20.safeTransfer(
            tokenAddress,
            walletAddress,
            tokenAddress.balanceOf(address(this))
        );
    }

}