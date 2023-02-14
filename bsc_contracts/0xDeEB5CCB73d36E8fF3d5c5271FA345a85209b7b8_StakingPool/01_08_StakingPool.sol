// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Upgradable.sol";

contract StakingPool is Upgradable {
    using SafeERC20 for IERC20;

    constructor() {
        _transferController(msg.sender);
    }

    /*================================ MAIN FUNCTIONS ================================*/

    function _updateReward(string memory poolId, address account) internal {
        PoolInfo storage pool = poolInfo[poolId];
        StakingData storage data = tokenStakingData[poolId][account];
        // Update reward
        if(pool.pool == 0) {
            pool.rewardPerTokenStored = rewardPerToken(poolId);
        }
        pool.lastUpdateTime = block.timestamp;
        data.reward = earned(poolId,account);
        if(pool.pool == 0) {
            data.rewardPerTokenPaid = pool.rewardPerTokenStored;
        }
    }

    /**
     * @dev Stake token to a pool
     * @param strs: poolId(0), internalTxID(1)
     * @param amount: amount of token user want to stake to the pool
    */
    function stakeToken(
        string[] memory strs,
        uint256 amount
    ) external poolExist(strs[0]) notBlocked {
        string memory poolId = strs[0];
        PoolInfo storage pool = poolInfo[poolId];
        StakingData storage data = tokenStakingData[poolId][msg.sender];
        uint256 rewardPerTokenPaidBefore = data.rewardPerTokenPaid;
        uint256 rewardPerTokenStoredBefore = pool.rewardPerTokenStored;
        uint256 lastUpdateTimeBefore = pool.lastUpdateTime;
        require(block.timestamp >= pool.configs[0] && block.timestamp <= pool.configs[3], "Staking time is invalid");
        require(amount >= (minimumStake[poolId] < 10**10 ? 10**10 : minimumStake[poolId]),amountInvalid);
        if (pool.configs.length >= 6) {
            require(pool.configs[5] == 0,"This pool has been Stopped");
        } 
        if(pool.configs.length >= 5){
            require(amount + pool.stakedBalance  <= pool.configs[4], "amount exceeds staking limit");
        }

        // Update reward
        _updateReward(poolId, msg.sender);
        uint256 rewardPerTokenStoredAfter = pool.rewardPerTokenStored;

        // Update staked balance
        data.balance += amount;
        
        // Update staking time
        data.stakedTime = block.timestamp;

        if (totalStakedBalancePerUser[msg.sender] == 0) {
            totalUserStaked += 1;
        }
        
        // Update user's total staked balance 
        totalStakedBalancePerUser[msg.sender] += amount;
        
        if (stakedBalancePerUser[poolId][msg.sender] == 0) {
            pool.totalUserStaked += 1;
        }
        
        // Update user's staked balance to the pool
        stakedBalancePerUser[poolId][msg.sender] += amount;
        
        // Update pool staked balance 
        pool.stakedBalance += amount;
        
        // Update total staked balance to pools
        totalAmountStaked += amount;
        
        // Transfer user's token to the contract
        IERC20(pool.stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        uint256[] memory infoBeforeAndAfter = new uint256[](4);
        infoBeforeAndAfter[0] = rewardPerTokenPaidBefore;
        infoBeforeAndAfter[1] = rewardPerTokenStoredBefore;
        infoBeforeAndAfter[2] = rewardPerTokenStoredAfter;
        infoBeforeAndAfter[3] = lastUpdateTimeBefore;
        emit StakingEvent(
            amount, 
            msg.sender, 
            poolId,
            strs[1],
            infoBeforeAndAfter
        );
    }
    
    /**
     * @dev Unstake token of a pool
     * @param strs: poolId(0), internalTxID(1)
     * @param amount: amount of token user want to unstake
   */
    function unstakeToken(string[] memory strs, uint256 amount)
        external
        poolExist(strs[0]) notBlocked
    {
        string memory poolId = strs[0];
        PoolInfo storage pool = poolInfo[poolId];
        StakingData storage data = tokenStakingData[poolId][msg.sender];
        uint256 rewardPerTokenPaidBefore = data.rewardPerTokenPaid;
        uint256 rewardPerTokenStoredBefore = pool.rewardPerTokenStored;
        uint256 lastUpdateTimeBefore = pool.lastUpdateTime;

        require(0 < amount && amount <= data.balance, amountInvalid);
        require(canGetReward(poolId),"Not enough staking time");
        // Update reward
        _updateReward(poolId, msg.sender);
        uint256 rewardPerTokenStoredAfter = pool.rewardPerTokenStored;

        // Update user staked balance
        totalStakedBalancePerUser[msg.sender] -= amount;
        if (totalStakedBalancePerUser[msg.sender] == 0) {
            totalUserStaked -= 1;
        }
        
        // Update user staked balance by pool
        stakedBalancePerUser[poolId][msg.sender] -= amount;
        if (stakedBalancePerUser[poolId][msg.sender] == 0) {
            pool.totalUserStaked -= 1;
        }

        data.unstakedTime = block.timestamp < pool.configs[1] ? block.timestamp : pool.configs[1];
        
        // Update staking amount
        data.balance -= amount;
        
        // Update pool staked balance
        pool.stakedBalance -= amount;
        
        // Update total staked balance user staked to pools
        totalAmountStaked -= amount;
        
        uint256 reward = 0;
        
        // If user unstake all token and has reward
        if (canGetReward(poolId) && data.reward > 0 && data.balance == 0) {
            reward = data.reward; 
            
            // Update pool reward claimed
            pool.totalRewardClaimed += reward;
            
            // Update pool reward fund
            pool.rewardFund -= reward;
            
            // Update total reward claimed
            totalRewardClaimed += reward;
            
            // Update reward user claimed by the pool
            rewardClaimedPerUser[poolId][msg.sender] += reward;
            
            // Update reward user claimed by pools
            totalRewardClaimedPerUser[msg.sender] += reward;
            
            // Reset reward
            data.reward = 0;
            
            // Transfer reward to user
            IERC20(pool.rewardToken).safeTransfer(msg.sender, reward);
        } 
        
        // Transfer token back to user
        IERC20(pool.stakingToken).safeTransfer(msg.sender, amount);
        uint256[] memory infoBeforeAndAfter = new uint256[](4);
        infoBeforeAndAfter[0] = rewardPerTokenPaidBefore;
        infoBeforeAndAfter[1] = rewardPerTokenStoredBefore;
        infoBeforeAndAfter[2] = rewardPerTokenStoredAfter;
        infoBeforeAndAfter[3] = lastUpdateTimeBefore;
        emit UnStakingEvent(
            amount, 
            msg.sender, 
            poolId,
            strs[1],
            infoBeforeAndAfter
        );
    } 
    
    /**
     * @dev Claim reward when user has staked to the pool for a period of time 
     * @param strs: poolId(0), internalTxID(1)
    */
    function claimReward(string[] memory strs)
        external
        poolExist(strs[0]) notBlocked
    { 
        string memory poolId = strs[0];
        PoolInfo storage pool = poolInfo[poolId];
        StakingData storage item = tokenStakingData[poolId][msg.sender];
        uint256 rewardPerTokenPaidBefore = item.rewardPerTokenPaid;
        uint256 rewardPerTokenStoredBefore = pool.rewardPerTokenStored;
        uint256 lastUpdateTimeBefore = pool.lastUpdateTime;

        // Update reward
        _updateReward(poolId, msg.sender);
        uint256 rewardPerTokenStoredAfter = pool.rewardPerTokenStored;

        uint256 reward = item.reward;
        require(reward > 0, "Reward is 0");
        require(IERC20(pool.rewardToken).balanceOf(address(this)) >= reward, "Pool balance is not enough");
        require(canGetReward(poolId), "Not enough staking time"); 

        item.unstakedTime = block.timestamp < pool.configs[1] ? block.timestamp : pool.configs[1];

        // Reset reward
        item.reward = 0;
        
        // Update reward claimed by the pool
        pool.totalRewardClaimed += reward;
        
        // Update pool reward fund
        pool.rewardFund -= reward; 
        
        // Update total reward claimed
        totalRewardClaimed += reward;
        
        // Update reward user claimed by the pool
        rewardClaimedPerUser[poolId][msg.sender] += reward;
        
        // Update total reward user claimed by pools
        totalRewardClaimedPerUser[msg.sender] += reward;
        
        // Transfer reward token to user
        IERC20(pool.rewardToken).safeTransfer(msg.sender, reward);
        uint256[] memory infoBeforeAndAfter = new uint256[](4);
        infoBeforeAndAfter[0] = rewardPerTokenPaidBefore;
        infoBeforeAndAfter[1] = rewardPerTokenStoredBefore;
        infoBeforeAndAfter[2] = rewardPerTokenStoredAfter;
        infoBeforeAndAfter[3] = lastUpdateTimeBefore;
        emit ClaimTokenEvent(
            reward, 
            msg.sender, 
            poolId,
            strs[1],
            infoBeforeAndAfter
        );
    }

    /**
     * @dev Claim reward when user has staked to the pool for a period of time and random get NFT 721
     * @param _signer: signer
     * @param _to: account claim reward
     * @param _tokenAddress: contract address of NFT
     * @param _tokenId: token ID
     * @param strs: poolId(0), internalTxID(1)
    */
    
    function claimReward721NFT (
        address _signer,
        address _to,
        address _tokenAddress,
        uint256 _tokenId,
        bytes memory signature,
        string[] memory strs
    )
        external
        poolExist(strs[0])
    {
        require(msg.sender == _to);
        require(canGetReward(strs[0]),"Cant get Reward");
        require(rewardNFT721pPerPool[strs[0]][_tokenAddress][_tokenId] != 0,"Pool not has this tokenId");
        require(!invalidSignature[signature], "This signature has been used");
        require(verify(_signer, _to, _tokenAddress, _tokenId, 1, strs[0], signature), "Dont have NFT reward");
        invalidSignature[signature] = true;
        rewardNFT721pPerPool[strs[0]][_tokenAddress][_tokenId] -= 1;
        IERC721(_tokenAddress).safeTransferFrom(address(this), _to, _tokenId);
        emit ClaimRewardNFT(_to, address(this), _signer, _tokenId, 1, strs[0], strs[1]);
    }

    /**
     * @dev Claim reward when user has staked to the pool for a period of time and random get NFT 721
     * @param _signer: signer
     * @param _to: account claim reward
     * @param _tokenAddress: contract address of NFT
     * @param _tokenId: token ID
     * @param strs: poolId(0), internalTxID(1)
    */
    function claimReward1155NFT (
        address _signer,
        address _to,
        address _tokenAddress,
        uint256 _tokenId,
        bytes memory signature,
        string[] memory strs
    )
        external
        poolExist(strs[0])
    {
        require(msg.sender == _to);
        require(canGetReward(strs[0]),"Cant get Reward");
        require(rewardNFT1155pPerPool[strs[0]][_tokenAddress][_tokenId] >= 1, "Pool not has enough balance of this tokenId");
        require(!invalidSignature[signature], "This signature has been used");
        require(verify(_signer, _to, _tokenAddress, _tokenId, 1, strs[0], signature), "Dont have NFT reward");
        invalidSignature[signature] = true;
        rewardNFT1155pPerPool[strs[0]][_tokenAddress][_tokenId] -= 1;
        IERC1155(_tokenAddress).safeTransferFrom(address(this),_to,  _tokenId, 1, "");
        emit ClaimRewardNFT(_to, address(this), _signer, _tokenId, 1, strs[0], strs[1]);
    }
    
    /**
     * @dev Check if enough time to claim reward
     * @param poolId: Pool id
    */
    function canGetReward(string memory poolId) public view returns (bool) {
        PoolInfo memory pool = poolInfo[poolId];
        
        // If flexible pool
        if (pool.configs[2] == 0) return true;
        if(pool.configs.length >= 6) {
            if(pool.configs[5] == 1) return true;
        }
        StakingData memory data = tokenStakingData[poolId][msg.sender];
        
        // Pool with staking period
        return data.stakedTime + pool.configs[2]  <= block.timestamp;
    }

    /**
     * @dev Check amount of reward a user can receive
     * @param poolId: Pool id
     * @param account: wallet address of user
    */
    function earned(string memory poolId, address account) 
        public
        view
        returns (uint256)
    {
        StakingData storage item = tokenStakingData[poolId][account]; 
        PoolInfo memory pool = poolInfo[poolId];
        // If staked amount = 0
        if (item.balance == 0) return 0;
        // If pool time now < pool start date
        if (block.timestamp < pool.configs[0]) return 0;
        uint256 amount = 0;
        if(pool.pool == 0) {
            amount = item.balance * (rewardPerToken(poolId) - item.rewardPerTokenPaid) / 1e20 + item.reward;
        } else {
            uint256 currentTimestamp = block.timestamp < pool.configs[1] ? block.timestamp : pool.configs[1];
            uint256 lastUpdateTime = item.stakedTime < item.unstakedTime ? item.unstakedTime : item.stakedTime;
            amount = (currentTimestamp - lastUpdateTime) * item.balance * pool.apr * pool.configs[6] / ONE_YEAR_IN_SECONDS / 1e4 + item.reward;
        }
         
        return pool.rewardFund > amount ? amount : pool.rewardFund;
    }
    
    /**
     * @dev Return amount of reward token distibuted per second
     * @param poolId: Pool id
    */
    function rewardPerToken(string memory poolId) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[poolId];
        require(pool.pool == 0,"Only Pool Allocation");
        // poolDuration = poolEndDatfe - poolStartDate
        uint256 poolDuration = pool.configs[1] - pool.configs[0]; 
        
        // Get current timestamp, if currentTimestamp > poolEndDate then poolEndDate will be currentTimestamp
        uint256 currentTimestamp = block.timestamp < pool.configs[1] ? block.timestamp : pool.configs[1];
        
        // If block timestamp < pool start date
        if (block.timestamp < pool.configs[0]) return 0;

        // If stakeBalance = 0 or poolDuration = 0
        if (pool.stakedBalance == 0 || poolDuration == 0) return 0;
        
        // If the pool has ended then stop calculate reward per token
        if (currentTimestamp <= pool.lastUpdateTime) return pool.rewardPerTokenStored;
        if (pool.configs.length >= 6) {
            if (pool.configs[5] == 1) return pool.rewardPerTokenStored;
        }
        // result = result * 1e8 for zero prevention
        uint256 rewardPool = pool.initialFund * (currentTimestamp - pool.lastUpdateTime) * 1e20;
        
        // newRewardPerToken = rewardPerToken(newPeriod) + lastRewardPertoken    
        return rewardPool / (poolDuration * pool.stakedBalance) + pool.rewardPerTokenStored;
    }
    
    /**
     * @dev Return annual percentage rate of a pool
     * @param poolId: Pool id
    */
    function apr(string memory poolId) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[poolId];
        
        // poolDuration = poolEndDate - poolStartDate
        uint256 poolDuration = pool.configs[1] - pool.configs[0];
        if (pool.stakedBalance == 0 || poolDuration == 0) return 0;
        
        return (ONE_YEAR_IN_SECONDS * pool.rewardFund / poolDuration - pool.totalRewardClaimed) * 100 / pool.stakedBalance; 
    }

    /**
     * @dev Return MaxTVL of PoolInfo
     * @param poolId: Pool id
    */
    function showMaxTVL(string memory poolId) 
        external 
        poolExist(poolId) view returns(uint256) 
    {
        PoolInfo memory pool = poolInfo[poolId];
        require(pool.configs.length > 4 ,"Pool doesn't have MaxTVL");
        return pool.configs[4];
    }

    /**
     * @dev set signer
     * @param _signer: signer
    */
    function setSigner(address _signer) external onlyController{
        signer = _signer;
    }

    /**
     * @dev Return Message Hash
     * @param _to: address of user claim reward
     * @param _tokenAddress: address of token
     * @param _tokenId: id of token
     * @param _amount: amount of token
     * @param poolId: id of Pool
    */
    function getMessageHash(
        address _to,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        string memory poolId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _tokenAddress, _tokenId, _amount, poolId));
    }

    /**
     * @dev Return ETH Signed Message Hash
     * @param _messageHash: Message Hash
    */
    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }
    /**
     * @dev Return True/False
     * @param _signer: address of signer
     * @param _to: address of user claim reward
     * @param _tokenAddress: address of token
     * @param _tokenId: id of token
     * @param _amount: equal 1 with NFT721
     * @param poolId: id of Pool
     * @param signature: sign the message hash offchain
    */
    function verify(
        address _signer,
        address _to,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        string memory poolId,
        bytes memory signature
    ) internal view returns (bool) {
        require(_signer == signer, "This signer is invalid");
        bytes32 messageHash = getMessageHash(_to, _tokenAddress, _tokenId, _amount, poolId);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    /**
     * @dev Return address of signer
     * @param _ethSignedMessageHash: ETH Signed Message Hash
     * @param _signature: sign the message hash offchain
    */
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev Return split Signature
     * @param sig: sign the message hash offchain
    */
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /*================================ ADMINISTRATOR FUNCTIONS ================================*/
    
    /**
     * @dev Create pool
     * @param strs: poolId(0), internalTxID(1)
     * @param addr: stakingToken(0), rewardToken(1)
     * @param data: rewardFund(0), typePool(1), apr(2), minimumStake(3)
     * @param configs: startDate(0), endDate(1), duration(2), endStakedTime(3), stakingLimit_for_Linear(4),stopPool(5),exchangeRateRewardToStaking(6)
   */
    function createPool(string[] memory strs, address[] memory addr, uint256[] memory data, uint256[] memory configs) external onlyAdmins {
        require(poolInfo[strs[0]].initialFund == 0, "Pool already exists");
        // require(data[0] > 0, "Reward fund must be greater than 0");
        require(configs[0] < configs[1], "End date must be greater than start date");
        require(configs[0] < configs[3], "End staking date must be greater than start date");
        uint256 poolDuration = configs[1] - configs[0];
        uint256 MaxTVL = (data[0]*1e20)/poolDuration;
        require(data[0] * 1e20 / poolDuration > 1, "Can't create pool");
        
        if(configs[4] == 0 ) {
            PoolInfo memory pool = PoolInfo(addr[0], addr[1], 0, 0, data[0], data[0], 0, 0, 0, 1, configs, data[1],0, data[2]);
            poolInfo[strs[0]] = pool;
            poolInfo[strs[0]].configs[4] = MaxTVL;
        } else {
            uint256 rewardFund = poolDuration * configs[4] * data[2] * configs[6] / ONE_YEAR_IN_SECONDS / 1e4;
            PoolInfo memory pool = PoolInfo(addr[0], addr[1], 0, 0, rewardFund, rewardFund, 0, 0, 0, 1, configs, data[1],1, data[2]);
            poolInfo[strs[0]] = pool;
        }

        minimumStake[strs[0]] = data[3];
        
        totalPoolCreated += 1;
        totalRewardFund += poolInfo[strs[0]].rewardFund;
        
        emit PoolUpdated(poolInfo[strs[0]].rewardFund, msg.sender, strs[0], strs[1]); 
    }

    /**
     * @dev Update pool
     * @param strs: poolId(0), internalTxID(1)
     * @param newConfigs: minimumStake(0)
   */
    function updatePool(string[] memory strs, uint256[] memory newConfigs)
        external
        onlyAdmins
        poolExist(strs[0])
    {
        // string memory poolId = strs[0];
        // PoolInfo storage pool = poolInfo[poolId];
        
        // if (newConfigs[0] != 0) {
        //     require(pool.configs[0] > block.timestamp, "Pool is already published");
        //     pool.configs[0] = newConfigs[0];
        // }
        // if (newConfigs[1] != 0) {
        //     require(newConfigs[1] > pool.configs[0], "End date must be greater than start date");
        //     require(newConfigs[1] >= block.timestamp, "End date must not be the past");
        //     pool.configs[1] = newConfigs[1];
        // }
        // if (newConfigs[2] != 0) {
            // require(
            //     newConfigs[2] >= pool.initialFund,
            //     "New reward fund must be greater than or equals to existing reward fund"
            // );
            
            // totalRewardFund = totalRewardFund - pool.initialFund + newConfigs[2];
            // pool.rewardFund = newConfigs[2];
            // pool.initialFund = newConfigs[2];
        // }
        // if (newConfigs[3] != 0) {
        //     require(newConfigs[3] > pool.configs[0] && newConfigs[3] <= pool.configs[1], "End stake date is invalid");
        //     pool.configs[3] = newConfigs[3];
        // }

        // if (pool.configs.length >= 5) {
        //     uint256 poolDuration = pool.configs[1]- pool.configs[0];
        //     pool.configs[4] = (pool.initialFund*1e20)/poolDuration;
        // }
        require(newConfigs[0] != minimumStake[strs[0]],"Invalid");
        minimumStake[strs[0]] = newConfigs[0];

        emit PoolUpdated(minimumStake[strs[0]], msg.sender, strs[0], strs[1]);
    }

    function showConfigs(string memory poolId) external view poolExist(poolId) returns(uint256[] memory) {
        PoolInfo storage pool = poolInfo[poolId];
        return pool.configs;
    }


    /**
     * @dev set stop pool
     * @param poolId: poolId
    */
    function setStopPool(string memory poolId) external onlyAdmins poolExist(poolId) {
        PoolInfo storage pool = poolInfo[poolId];
        if(pool.pool == 0) {
            pool.rewardPerTokenStored = rewardPerToken(poolId);
        } else {
            pool.configs[1] = block.timestamp;
        }
        require(block.timestamp < pool.configs[1] || block.timestamp > pool.configs[0], "time invalid");
        if (pool.configs.length >= 6) {
            require(pool.configs[5] == 0,"This Pool is already stop");
            pool.configs[5] = 1;
        } else {
            pool.configs.push(1);
        }
        emit StopPool(poolId);
    }
 
    /**
     * @dev Emercency withdraw staking token, all staked data will be deleted, onlyProxyOwner can execute this function
     * @param _poolId: the poolId
     * @param _account: the user wallet address want to withdraw token
    */
    function emercencyWithdrawToken(string memory _poolId, address _account) external onlyController {
        PoolInfo memory pool = poolInfo[_poolId];
        StakingData memory data = tokenStakingData[_poolId][_account];
        require(data.balance > 0, "Staked balance is 0");

        // Transfer staking token back to user
        IERC20(pool.stakingToken).safeTransfer(_account, data.balance);
        uint256 amount = data.balance;

        // Update user staked balance
        totalStakedBalancePerUser[msg.sender] -= amount;
        if (totalStakedBalancePerUser[msg.sender] == 0) {
            totalUserStaked -= 1;
        }

        // Update user staked balance by pool
        stakedBalancePerUser[_poolId][msg.sender] -= amount;
        if (stakedBalancePerUser[_poolId][msg.sender] == 0) {
            pool.totalUserStaked -= 1;
        }

        // Update pool staked balance
        pool.stakedBalance -= amount;

        // Update total staked balance user staked to pools
        totalAmountStaked -= amount;

        // Delete data
        delete tokenStakingData[_poolId][_account];
    }
    
    /**
     * @dev Withdraw fund admin has sent to the pool
     * @param _tokenAddress: the token contract owner want to withdraw fund
     * @param _account: the account which is used to receive fund
     * @param _amount: the amount contract owner want to withdraw
    */
    function withdrawFund(address _tokenAddress, address _account, uint256 _amount) external onlyController {
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "Pool not has enough balance");
        // Transfer fund back to account
        IERC20(_tokenAddress).safeTransfer(_account, _amount);
    }

    /**
     * @dev Withdraw NFT721 with tokenId admin has sent to contract 
     * @param _tokenAddress: address of token
     * @param _account: to account
     * @param tokenId: token ID
     * @param strs: poolId(0), internalTxID(1)
    */
    function withDrawNFT721(address _tokenAddress, address _account, uint256 tokenId, string[] memory strs)
        external
        onlyAdmins
        poolExist(strs[0])
    {
        string memory poolId = strs[0];
        require(rewardNFT721pPerPool[poolId][_tokenAddress][tokenId] != 0,"error");
        
        rewardNFT721pPerPool[poolId][_tokenAddress][tokenId] -= 1;
        // Transfer token back to account
        IERC721(_tokenAddress).safeTransferFrom(address(this), _account, tokenId);
        emit WithdrawNFT( _tokenAddress, address(this), _account, tokenId, 1, poolId, strs[0]);
    }
    
    /**
     * @dev Withdraw NFT1155 with tokenId and amount admin has sent to contract 
     * @param _tokenAddress: address of token
     * @param _account: to account
     * @param tokenId: token ID
     * @param amount: amount of tokenID
     * @param strs: poolId(0), internalTxID(1)
    */
    function withDrawNFT1155(address _tokenAddress, address _account, uint256 tokenId, uint256 amount, string[] memory strs)
        external
        onlyAdmins
        poolExist(strs[0])
    {
        string memory poolId = strs[0];
        require(rewardNFT1155pPerPool[poolId][_tokenAddress][tokenId] >= amount, "error");
        
        rewardNFT1155pPerPool[poolId][_tokenAddress][tokenId] -= amount;
        // Transfer token back to account
        IERC1155(_tokenAddress).safeTransferFrom(address(this), _account, tokenId, amount, "");
        emit WithdrawNFT( _tokenAddress, address(this), _account, tokenId, amount, poolId, strs[1]);
    }

    /**
     * @dev Deposit NFT721 with tokenId
     * @param _tokenAddress: address of token
     * @param strs: poolId(0), internalTxID(1)
     * @param tokenId: token ID
    */
    function depositNFT721(address _tokenAddress, uint256 tokenId, string[] memory strs)
        external
        onlyAdmins
    {
        string memory poolId = strs[0];
        IERC721(_tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        rewardNFT721pPerPool[poolId][_tokenAddress][tokenId] = 1;
        emit DepositNFT( _tokenAddress, msg.sender, address(this), tokenId, 1, poolId, strs[1]);
    }

    /**
     * @dev Deposit NFT1155 with tokenId
     * @param _tokenAddress: address of token
     * @param strs: poolId(0), internalTxID(1)
     * @param tokenId: token ID
     * @param amount: amount
    */
    function depositNFT1155(address _tokenAddress, uint256 tokenId, uint256 amount, string[] memory strs)
        external
        onlyAdmins
    {
        string memory poolId = strs[0];
        IERC1155(_tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        rewardNFT1155pPerPool[poolId][_tokenAddress][tokenId] += amount;
        emit DepositNFT( _tokenAddress, msg.sender, address(this), tokenId, amount, poolId, strs[1]);
    }
    
    /**
     * @dev Contract owner set admin for execute administrator functions
     * @param _address: wallet address of admin
     * @param _value: true/false
    */
    function setAdmin(address _address, bool _value) external onlyController { 
        adminList[_address] = _value;

        emit AdminSet(_address, _value);
    } 

    /**
     * @dev Check if a wallet address is admin or not
     * @param _address: wallet address of the user
    */
    function isAdmin(address _address) external view returns (bool) {
        return adminList[_address];
    }

    /**
     * @dev Block users
     * @param _address: wallet address of user
     * @param _value: true/false
    */
    function setBlacklist(address _address, bool _value) external onlyAdmins {
        blackList[_address] = _value;
        // emit BlacklistSet(_address, _value);
    }
    
    /**
     * @dev Check if a user has been blocked
     * @param _address: user wallet 
    */
    function isBlackList(address _address) external view returns (bool) {
        return blackList[_address];
    }
    
    /**
     * @dev Set pool active/deactive
     * @param _poolId: the pool id
     * @param _value: true/false
    */
    function setPoolActive(string memory _poolId, uint256 _value) external onlyAdmins {
        poolInfo[_poolId].active = _value;

        emit PoolActivationSet(msg.sender, _poolId, _value);
    }

    /**
     * @dev Transfers controller of the contract to a new account (`newController`).
     * Can only be called by the current controller.
    */
    function transferController(address _newController) external {
        // Check if controller has been initialized in proxy contract
        // Caution: If set controller != proxyOwnerAddress then all functions require controller permission cannot be called from proxy contract
        if (controller != address(0)) {
            require(msg.sender == controller, "Only controller");
        }
        require(_newController != address(0), "New controller is the zero address");
        _transferController(_newController);
    }

    /**
     * @dev Transfers controller of the contract to a new account (`newController`).
     * Internal function without access restriction.
    */
    function _transferController(address _newController) internal {
        address oldController = controller;
        controller = _newController;
        emit ControllerTransferred(oldController, controller);
    }

     /**
     * @dev this function for the contract can receive ERC1155.
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}