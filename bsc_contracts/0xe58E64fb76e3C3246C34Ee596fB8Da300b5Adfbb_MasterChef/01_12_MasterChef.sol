// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/SignedSafeMath.sol";

contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;

    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenIndices;
    }

    struct PoolInfo {
        uint256 accRewardPerShare;
        uint256 lastRewardTime;
    }

    /// @notice Address of WBNB contract.
    IERC20 public WBNB;
    /// @notice Address of the NFT token for each MCV2 pool.
    IERC721 public NFT;

    /// @notice Info of each MCV2 pool.
    PoolInfo public poolInfo;

    /// @notice Mapping from token ID to owner address
    mapping(uint256 => address) public tokenOwner;

    /// @notice Info of each user that stakes nft tokens.
    mapping(address => UserInfo) public userInfo;

    /// @notice Keeper register. Return true if 'address' is a keeper.
    mapping(address => bool) public isKeeper;

    uint256 public rewardPerSecond;
    uint256 private ACC_WBNB_PRECISION;

    uint256 public distributePeriod;
    uint256 public lastDistributedTime;

    event Deposit(address indexed user, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 amount);
    event LogUpdatePool(
        uint256 lastRewardTime,
        uint256 nftSupply,
        uint256 accRewardPerShare
    );
    event LogRewardPerSecond(uint256 rewardPerSecond);


    modifier onlyKeeper {
        require(msg.sender == owner() || isKeeper[msg.sender],'not keeper'); 
        _;
    }

    constructor(IERC20 _WBNB, IERC721 _NFT) {
        WBNB = _WBNB;
        NFT = _NFT;
        distributePeriod = 1 weeks;
        ACC_WBNB_PRECISION = 1e12;
        poolInfo = PoolInfo({
            lastRewardTime: block.timestamp,
            accRewardPerShare: 0
        });
    }

    /// @notice add keepers
    function addKeeper(address[] memory _keepers) external onlyOwner {
        uint256 i = 0;
        uint256 len = _keepers.length;

        for(i; i < len; i++){
            address _keeper = _keepers[i];
            if(!isKeeper[_keeper]){
                isKeeper[_keeper] = true;
            }
        }
    }

    /// @notice remove keepers
    function removeKeeper(address[] memory _keepers) external onlyOwner {
        uint256 i = 0;
        uint256 len = _keepers.length;

        for(i; i < len; i++){
            address _keeper = _keepers[i];
            if(isKeeper[_keeper]){
                isKeeper[_keeper] = false;
            }
        }
    }  


    /// @notice Sets the reward per second to be distributed. Can only be called by the owner.
    /// @param _rewardPerSecond The amount of Reward to be distributed per second.
    function setRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
        updatePool();
        rewardPerSecond = _rewardPerSecond;
        emit LogRewardPerSecond(_rewardPerSecond);
    }

    function setDistributionRate(uint256 amount) public onlyKeeper {
        updatePool();
        uint256 notDistributed;
        if (lastDistributedTime > 0 && block.timestamp < lastDistributedTime) {
            uint256 timeLeft = lastDistributedTime.sub(block.timestamp);
            notDistributed = rewardPerSecond.mul(timeLeft);
        }

        amount = amount.add(notDistributed);
        uint256 _rewardPerSecond = amount.div(distributePeriod);
        rewardPerSecond = _rewardPerSecond;
        lastDistributedTime = block.timestamp.add(distributePeriod);
        emit LogRewardPerSecond(_rewardPerSecond);
    }

    /// @notice View function to see pending WBNB on frontend.
    /// @param _user Address of user.
    /// @return pending WBNB reward for a given user.
    function pendingReward(address _user)
        external
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 nftSupply = NFT.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && nftSupply != 0) {
            uint256 time = block.timestamp.sub(pool.lastRewardTime);
            uint256 reward = time.mul(rewardPerSecond);
            accRewardPerShare = accRewardPerShare.add(
                reward.mul(ACC_WBNB_PRECISION) / nftSupply
            );
        }
        pending = int256(
            user.amount.mul(accRewardPerShare) / ACC_WBNB_PRECISION
        ).sub(user.rewardDebt).toUInt256();
    }

    /// @notice View function to see token Ids on frontend.
    /// @param _user Address of user.
    /// @return tokenIds Staked Token Ids for a given user.
    function stakedTokenIds(address _user)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        tokenIds = userInfo[_user].tokenIds;
    }

    /// @notice Update reward variables of the given pool.
    /// @return pool Returns the pool that was updated.
    function updatePool() public returns (PoolInfo memory pool) {
        pool = poolInfo;
        if (block.timestamp > pool.lastRewardTime) {
            uint256 nftSupply = NFT.balanceOf(address(this));
            if (nftSupply > 0) {
                uint256 time = block.timestamp.sub(pool.lastRewardTime);
                uint256 reward = time.mul(rewardPerSecond);
                pool.accRewardPerShare = pool.accRewardPerShare.add(
                    reward.mul(ACC_WBNB_PRECISION).div(nftSupply)
                );
            }
            pool.lastRewardTime = block.timestamp;
            poolInfo = pool;
            emit LogUpdatePool(
                pool.lastRewardTime,
                nftSupply,
                pool.accRewardPerShare
            );
        }
    }

    /// @notice Deposit nft tokens to MCV2 for WBNB allocation.
    /// @param tokenIds NFT tokenIds to deposit.
    function deposit(uint256[] calldata tokenIds) public {
        PoolInfo memory pool = updatePool();
        UserInfo storage user = userInfo[msg.sender];

        // Effects
        user.amount = user.amount.add(tokenIds.length);
        user.rewardDebt = user.rewardDebt.add( int256(tokenIds.length.mul(pool.accRewardPerShare) / ACC_WBNB_PRECISION) );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(NFT.ownerOf(tokenIds[i]) == msg.sender, "This NTF does not belong to address");

            user.tokenIndices[tokenIds[i]] = user.tokenIds.length;
            user.tokenIds.push(tokenIds[i]);
            tokenOwner[tokenIds[i]] = msg.sender;

            NFT.transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        emit Deposit(msg.sender, tokenIds.length, msg.sender);
    }

    /// @notice Withdraw NFT tokens from MCV2.
    /// @param tokenIds NFT token ids to withdraw.
    function withdraw(uint256[] calldata tokenIds) public {
        PoolInfo memory pool = updatePool();
        UserInfo storage user = userInfo[msg.sender];

        // Effects
        user.rewardDebt = user.rewardDebt.sub(
            int256(
                tokenIds.length.mul(pool.accRewardPerShare) / ACC_WBNB_PRECISION
            )
        );
        user.amount = user.amount.sub(tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenOwner[tokenIds[i]] == msg.sender,
                "Nft Staking System: user must be the owner of the staked nft"
            );
            NFT.transferFrom(address(this), msg.sender, tokenIds[i]);
            uint256 lastTokenId = user.tokenIds[user.tokenIds.length - 1];
            user.tokenIds[user.tokenIndices[tokenIds[i]]] = lastTokenId;
            user.tokenIndices[lastTokenId] = user.tokenIndices[tokenIds[i]];
            user.tokenIds.pop();
            delete user.tokenIndices[tokenIds[i]];
            delete tokenOwner[tokenIds[i]];
        }

        emit Withdraw(msg.sender, tokenIds.length, msg.sender);
    }

    /// @notice Harvest proceeds for transaction sender.
    function harvest() public {
        PoolInfo memory pool = updatePool();
        UserInfo storage user = userInfo[msg.sender];
        int256 accumulatedReward = int256(
            user.amount.mul(pool.accRewardPerShare) / ACC_WBNB_PRECISION
        );
        uint256 _pendingReward = accumulatedReward
            .sub(user.rewardDebt)
            .toUInt256();

        // Effects
        user.rewardDebt = accumulatedReward;

        // Interactions
        if (_pendingReward != 0) {
            WBNB.safeTransfer(msg.sender, _pendingReward);
        }

        emit Harvest(msg.sender, _pendingReward);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}