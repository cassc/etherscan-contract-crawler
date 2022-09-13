// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IFTFarm.sol";

abstract contract AccessControl is Ownable {
    mapping(address => bool) public operators;

    struct Proof {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event SetOperator(address indexed add, bool value);

    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function verifyProof(bytes memory encode, Proof memory _proof)
        internal
        view
        returns (bool)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(getChainID(), address(this), encode)
        );
        address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
        return operators[signatory];
    }

    function setOperator(address _operator, bool _v) external onlyOwner {
        operators[_operator] = _v;
        emit SetOperator(_operator, _v);
    }
}

contract FTFarm is IFTFarm, AccessControl {
    using SafeMath for uint256;
    using Math for uint256;
    using SignedMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant REWARDS_DAYS = 1 days;

    IERC20 public immutable ft;
    IERC20 public immutable usdt;
    IUniswapV2Router02 public immutable uniswapV2Router;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalSupply;

    mapping(address => uint256) private _userRewardPerTokenPaids;
    mapping(address => uint256) private _rewards;
    mapping(address => uint256) private _balances;

    constructor(IERC20 ft_, IERC20 usdt_,IUniswapV2Router02 uniswapV2Router_) {
        ft = ft_;
        usdt = usdt_;
        uniswapV2Router = uniswapV2Router_;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }


    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
                (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((_balances[account] *
                (rewardPerToken() - _userRewardPerTokenPaids[account])) / 1e18) +
                    _rewards[account];
    }

    

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * REWARDS_DAYS;
    }

    function getHash(address _address) public view returns (uint256) {
        return _balances[_address];
    }

    function stake(address _owner, uint256 _amount)
        external
        onlyOperator
        updateReward(_owner)
    {
        _stake(_owner, _amount);
        emit Staked(_owner, _amount);
    }

    function getReward(uint256 _reward) external updateReward(msg.sender) {
        address user = msg.sender;
        uint256 balance = getHash(user);
        uint256 hashReward = _u2ft(balance);
        uint256 farmReward = _rewards[user].min(_reward);

        uint256 reward = hashReward.min(farmReward);
        if (farmReward >= hashReward) {
            _withdraw(user, balance);
        } else {
            _withdraw(user, balance.min(_ft2u(reward)));
        }
        if (reward > 0) {
            _rewards[msg.sender] = _rewards[msg.sender].sub(reward);
            ft.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function _stake(address _address, uint256 _amount) private {
        totalSupply += _amount;
        _balances[_address] += _amount;
    }

    function _withdraw(address _address, uint256 _amount) private {
        totalSupply -= _amount;
        _balances[_address] -= _amount;
    }

    function _u2ft(uint256 _amount) private view returns (uint256) {
        if(_amount<=0)return 0;
        address[] memory path = new address[](2);
        path[0] = address(ft);
        path[1] = address(usdt);
        return uniswapV2Router.getAmountsIn(_amount,path)[0];
    }

    function _ft2u(uint256 _amount) private view returns (uint256) {
        if(_amount<=0)return 0;
        address[] memory path = new address[](2);
        path[0] = address(ft);
        path[1] = address(usdt);
        return uniswapV2Router.getAmountsOut(_amount,path)[1];
    }

    function withdraw(address _owner, uint256 _amount)
        external
        onlyOwner
        updateReward(_owner)
    {
        require(getHash(_owner) >= _amount, "Amount gt hash");
        _withdraw(_owner, _amount);
        emit Withdrawn(_owner, _amount);
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / REWARDS_DAYS;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / REWARDS_DAYS;
        }
        uint256 balance = ft.balanceOf(address(this));
        require(
            rewardRate <= balance / REWARDS_DAYS,
            "Staking: Provided reward too high"
        );
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + REWARDS_DAYS;
        emit RewardAdded(reward);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaids[account] = rewardPerTokenStored;
        }
        _;
    }
}