pragma solidity 0.8.16;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IStakingToken } from "../interfaces/IStakingToken.sol";

interface ILockerStaking {
    struct PoolInfo {
        uint256 totalStaked;
        address[] rewardTokens;
        uint256[] rewardsPerBlock;
    }

    struct UserInfo {
        uint192 rewardableDeposit;
        uint64 lastRewardBlock;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ClaimedReward(address indexed user, uint256 amount);

    error TokenAlreadyInRewards();
    error InsufficientFunds();
}

contract LockerStaking is ILockerStaking {
    using SafeERC20 for IERC20;
    using SafeERC20 for IStakingToken;
    using SafeCast for uint256;


    address immutable public stakingToken;
    address immutable public wrapperToken;
    address public rewardVault;

    address public gov;

    PoolInfo private poolInfo;
    mapping(address => UserInfo) public users;

    constructor(
        address stakingToken_,
        address wrapperToken_,
        address rewardVault_
    ) {
        stakingToken = stakingToken_;
        wrapperToken = wrapperToken_;
        rewardVault = rewardVault_;
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov);
        _;
    }

    function setGovernance(address gov_) external onlyGov {
        require(gov_ != address(0));
        gov = gov_;
    }

    function setRewardTokensAndAmounts(address[] memory tokens_, uint256[] memory rewards_) external onlyGov {
        PoolInfo storage p = poolInfo;
        uint256 l = p.rewardTokens.length;
        for (uint256 i; i < l;) {
            p.rewardTokens[i] = address(0);
            p.rewardsPerBlock[i] = 0;
            unchecked{ ++i; }
        }

        for (uint256 j; j < l;) {
            p.rewardTokens[j] = tokens_[j];
            p.rewardsPerBlock[j] = rewards_[j];
            unchecked { j++; }
        }

        for (uint256 k; k < tokens_.length - l;){
            p.rewardTokens.push(tokens_[l+k]);
            p.rewardsPerBlock.push(rewards_[l+k]);
            unchecked { k++; }
        }

        require(p.rewardTokens.length == p.rewardsPerBlock.length); //sanity check
    }

    function addRewardToken(address token_, uint256 rewards_) external onlyGov {
        PoolInfo storage p = poolInfo;

        for (uint256 i; i < p.rewardTokens.length;) {
            if (p.rewardTokens[i] == token_){
                revert TokenAlreadyInRewards();
            }
            unchecked { i++; }
        }

        p.rewardTokens.push(token_);
        p.rewardsPerBlock.push(rewards_);
        require(p.rewardTokens.length == p.rewardsPerBlock.length); //sanity check
    }

    function setRewardPerBlock(address token_, uint256 rewards_) external onlyGov {
        PoolInfo memory p = poolInfo;
        for (uint256 i; i < p.rewardTokens.length;) {
            if (p.rewardTokens[i] == token_){
                poolInfo.rewardsPerBlock[i] = rewards_;
                break;
            }
            unchecked { i++; }
        }
    }

    function getRewardParams() external view returns(address[] memory tokens, uint256[] memory rewardsPerBlock) {
        PoolInfo memory p = poolInfo;
        tokens = new address[](p.rewardTokens.length);
        rewardsPerBlock = new uint256[](p.rewardsPerBlock.length);
        for (uint256 i; i < p.rewardTokens.length;i++){
            tokens[i] = p.rewardTokens[i];
            rewardsPerBlock[i] = p.rewardsPerBlock[i];
        }
    }

    function setRewardVault(address vault_) external onlyGov {
        rewardVault = vault_;
    }

    function totalStaked() external view returns(uint256) {
        return poolInfo.totalStaked;
    }

    function deposit(uint224 amount) external {
        require(amount > 0);
        UserInfo storage u = users[msg.sender];

        uint256 totalStaked = poolInfo.totalStaked;
        uint256 userRewardableDeposit = u.rewardableDeposit;

        (address[] memory tokens, uint256[] memory rewards) = _pendingRewards(userRewardableDeposit, u.lastRewardBlock, totalStaked);
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        poolInfo.totalStaked = totalStaked + amount;
        u.lastRewardBlock = block.number.toUint64();
        u.rewardableDeposit = (userRewardableDeposit + amount).toUint192();

        for (uint256 i; i < tokens.length;) {
            if(rewards[i] > 0) {
                IERC20(tokens[i]).safeTransferFrom(rewardVault, msg.sender, rewards[i]);
            }
            unchecked{ ++i;}
        }
        IStakingToken(wrapperToken).mint(msg.sender, amount);

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint224 amount) external {
        require(amount > 0);
        UserInfo storage u = users[msg.sender];

        uint256 totalStaked = poolInfo.totalStaked;
        uint256 userRewardableDeposit = u.rewardableDeposit;
        if (userRewardableDeposit < amount) revert InsufficientFunds();
        (address[] memory tokens, uint256[] memory rewards) = _pendingRewards(userRewardableDeposit, u.lastRewardBlock, totalStaked);

        poolInfo.totalStaked = totalStaked - amount;
        u.lastRewardBlock = block.number.toUint64();
        unchecked{
            u.rewardableDeposit = (userRewardableDeposit - amount).toUint192();
        }

        for (uint256 i; i < tokens.length;) {
            if(rewards[i] > 0) {
                IERC20(tokens[i]).safeTransferFrom(rewardVault, msg.sender, rewards[i]);
            }
            unchecked{ ++i;}
        }

        IStakingToken(wrapperToken).burnFrom(msg.sender, amount);
        IERC20(stakingToken).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    function emergencyWithdraw() external {
        uint256 rewardableDeposit = users[msg.sender].rewardableDeposit;
        // in case of emergency over/underflow check is not necessary,
        // but totalStaked still must be counted during normal operation
        unchecked {
            poolInfo.totalStaked -= rewardableDeposit;
        }
        uint256 userBalance = IStakingToken(wrapperToken).balanceOf(msg.sender);

        delete users[msg.sender];

        IStakingToken(wrapperToken).burnFrom(msg.sender, userBalance);
        IERC20(stakingToken).safeTransfer(msg.sender, rewardableDeposit);
    }

    function claim() external {
        UserInfo storage u = users[msg.sender];

        uint256 totalStaked = poolInfo.totalStaked;
        uint256 userRewardableDeposit = u.rewardableDeposit;

        (address[] memory tokens, uint256[] memory rewards) = _pendingRewards(userRewardableDeposit, u.lastRewardBlock, totalStaked);

        u.lastRewardBlock = block.number.toUint64();

        for (uint i; i < tokens.length;) {
            if(rewards[i] > 0) {
                IERC20(tokens[i]).safeTransferFrom(rewardVault, msg.sender, rewards[i]);
            }
            unchecked{ ++i;}
        }
    }
    

    function pendingRewards(address user) external view returns(address[] memory tokens, uint256[] memory rewards) {
        UserInfo memory u = users[user];
        (tokens, rewards) = _pendingRewards(u.rewardableDeposit, u.lastRewardBlock, poolInfo.totalStaked);
    }

    function _pendingRewards(
        uint256 rewardableDeposit,
        uint64 lastRewardBlock,
        uint256 totalStaked
    ) internal view returns(address[] memory tokens, uint256[] memory rewards) {
        if ( totalStaked == 0 || lastRewardBlock == 0 ) return (tokens, rewards);
        PoolInfo memory p = poolInfo;

        tokens = new address[](p.rewardTokens.length);
        rewards = new uint256[](tokens.length);

        for (uint256 i; i < p.rewardTokens.length;){
            tokens[i] = p.rewardTokens[i];
            rewards[i] = (rewardableDeposit * p.rewardsPerBlock[i] * (block.number - lastRewardBlock)) / totalStaked;
            unchecked{ ++i; }
        }
    }
}