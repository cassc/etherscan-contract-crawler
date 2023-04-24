/**
 *Submitted for verification at BscScan.com on 2023-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
pragma solidity ^0.8.0;

contract StakeKingPlatform {
    using SafeMath for uint256;

    IERC20 public stakingToken;
    uint256 public constant APY = 15;
    uint256 public constant ONE_YEAR = 365 days;
    uint256 public constant UNSTAKING_FEE = 3;
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    uint256 public constant STAKE_BURN_FEE = 3;
    uint256 public totalStaked;
    uint256 public totalRewards;
    uint256 public totalBurned;

    address public owner;
    mapping(address => uint256) public stakingBalances;
    mapping(address => uint256) public rewardBalances;
    mapping(address => uint256) public startTime;

    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 timestamp);
    event RewardClaimed(
        address indexed user,
        uint256 reward,
        uint256 timestamp
    );

    constructor(IERC20 _stakingToken) {
        stakingToken = _stakingToken;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount should be greater than 0");
        require(
            stakingToken.balanceOf(msg.sender) >= _amount,
            "Insufficient token balance"
        );

        uint256 burnFee = _amount.mul(STAKE_BURN_FEE).div(100);
        uint256 netStakeAmount = _amount.sub(burnFee);

        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakingToken.transfer(BURN_ADDRESS, burnFee);

        stakingBalances[msg.sender] = stakingBalances[msg.sender].add(netStakeAmount);
        totalStaked = totalStaked.add(netStakeAmount);
        startTime[msg.sender] = block.timestamp;

        totalBurned = totalBurned.add(burnFee);
        emit Staked(msg.sender, netStakeAmount, block.timestamp);
    }

    function unstake(uint256 _amount) external {
        require(
            stakingBalances[msg.sender] >= _amount,
            "Insufficient staking balance"
        );

        claimReward();
        uint256 fee = _amount.mul(UNSTAKING_FEE).div(100);
        uint256 unstakeAmount = _amount.sub(fee);
        stakingBalances[msg.sender] = stakingBalances[msg.sender].sub(_amount);
        totalStaked = totalStaked.sub(_amount);
        stakingToken.transfer(msg.sender, unstakeAmount);

        emit Unstaked(msg.sender, _amount, block.timestamp);
    }

    function getTotalRewards() external view returns (uint256) {
        return totalRewards;
    }

    function claimReward() public {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No rewards available");

        rewardBalances[msg.sender] = 0;
        startTime[msg.sender] = block.timestamp;
        totalRewards = totalRewards.add(reward);
        stakingToken.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward, block.timestamp);
    }

    function calculateReward(address _user) public view returns (uint256) {
        uint256 elapsedTime = block.timestamp.sub(startTime[_user]);
        uint256 reward = stakingBalances[_user].mul(APY).mul(elapsedTime).div(
            ONE_YEAR
        );
        return reward;
    }

    function getStakingBalance(address _user) external view returns (uint256) {
        return stakingBalances[_user];
    }

    function getRewardBalance(address _user) external view returns (uint256) {
        return calculateReward(_user);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 contractBalance = stakingToken.balanceOf(address(this));
        stakingToken.transfer(owner, contractBalance);
    }
}