// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Upgradable.sol";
import "../nft-token/ERC20Token.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../nft-token/INFTToken.sol";
import "./ISignatureUtils.sol";

contract NFTFractional is Upgradable {
    using SafeERC20 for IERC20;

    /**
     * @dev Contract owner set admin for execute administrator functions
     * @param _address wallet address of admin
     * @param _value 1: admin, 2: user, 3:controller
    */
    function setAdmin(address _address, uint256 _value) external onlyController {
        require(_address != address(0), "NFTFractional: Admin is not the zero address");
        adminList[_address] = _value;
        emit AdminSet(_address, _value);
    }

    /**
     * @dev check wallet if wallet address is admin or not
     * @param _address wallet address of the user
     * @return result rule --> 1: admin, 2: user, 3: controller 
    */
    function isAdmin(address _address) external view returns (uint256) {
        return adminList[_address];
    }

    /**
    * @dev Transfers controller of the contract to a new account (`newController`).
    * @param _newController Adress to set new controller
    * Can only be called by the current controller.
    */
    function transferController(address _newController) external {
        // Check if controller has been initialized in proxy contract
        // Caution If set controller != proxyOwnerAddress then all functions require controller permission cannot be called from proxy contract
        if (controller != address(0)) {
            require(msg.sender == controller, "NFTFractional: Only controller");
        }
        require(_newController != address(0), "NFTFractional: New controller is the zero address");
        _transferController(_newController);
    }

    /**
    * @dev Transfers controller of the contract to a new account (`newController`).
    * Internal function without access restriction.
    * @param _newController address for new controller
    */
    function _transferController(address _newController) internal {
        controller = _newController;
    }

    /**
    * @dev set collection of nft token
    */
    function initial(
        address _signatureUtils,
        address _nftToken) 
            external onlyController {
        nftToken = _nftToken;
        signatureUtils = _signatureUtils;
    }

    /**
     * @dev mint NFT
     * @param _tokenId token id of NFT
    */
    function mintNFT(uint256 _tokenId) external onlyAdmins {
        INFTToken(nftToken).mintNFT(address(this), _tokenId);
        emit MintNFT(nftToken, address(this), _tokenId);
    }

    /**
    * @dev fractionalize nft to bep20 token
    * @param _token token of NFT
    * @param _totalSupply total supply of bep20 token
    * @param _tokenId token id of NFT
    * @param _name name of bep20 token
    * @param _symbol symbol of bep20 token
    */
    function fractionalizeNFT(
        address _token,
        uint256 _totalSupply,
        uint256 _tokenId,
        string memory _name,
        string memory _symbol) external onlyAdmins notEmpty(_name) notEmpty(_symbol) {
            require(_totalSupply > 0, "NFTFractional: Total supply not greater than zero");
            require(fnftInfos[_tokenId].tokenNFT == address(0), "NFTFractional: NFT fractionalized");
            ERC20Token tokenERC20 = new ERC20Token(_name, _symbol);
            ERC20Token(tokenERC20).mintERC20(address(this), _totalSupply);
            FNFTInfo memory fNFTInfo = FNFTInfo(_tokenId,_totalSupply, _totalSupply, address(this), _token, address(tokenERC20));
            fnftInfos[_tokenId] = fNFTInfo;
            emit FractionalizeNFT(_token, address(tokenERC20), address(this), _totalSupply, _tokenId ,_symbol, _name);
    }

    /**
    * @dev create functional F-NFT Pool to user buy token F-NFT by USDT token or other tokens
    * @param _addrs acceptToken(0), receiveAddress(1)
    * @param _datas poolId(0), fnftId(1), poolBalance(2), active(3), poolType(4)
    * @param _configs registrationStartTime(0), registrationEndTime(1), purchaseStartTime(2), purchaseEndTime(3)
    */
    function createFNFTPool(address[] memory _addrs, uint256[] memory _datas, uint256[] memory _configs) external onlyAdmins {
        require(_addrs[0] != address(0) || _addrs[1] != address(0), "NFTFractional: Address is not the zero address");
        // pool balance > 0
        require(_datas[2] > 0, "NFTFractional: Pool balance must greater then zero");
        
        // require(block.timestamp <= _configs[0], "NFTFractional: Current Time is less then Registration Start Time");
        require(_configs[0] <= _configs[1], "NFTFractional: Registration Start Time is less then Registration End Time");
        require(_configs[1] <= _configs[2], "NFTFractional: Registration End Time is less then Purchasing Start Time");
        require(_configs[2] <= _configs[3], "NFTFractional: Purchasing Start Time is less then Purchasing End Time");

        FNFTInfo storage fnft = fnftInfos[_datas[1]];
        // check fnt exists
        require(fnft.tokenNFT != address(0), "NFTFractional: FNFT is not exist");
        require(fnftPools[_datas[0]].acceptToken == address(0), "NFTFractional: the FNFT exists");
        // pool balance < available supply fnft
        require(_datas[2] <=  fnft.availableSupply, "NFTFractional: Pool balance must less then available supply");
        fnft.availableSupply -= _datas[2];
        FNFTPool memory pool;
        if(_datas[4] == 2) {
            pool = FNFTPool(_addrs[0], _addrs[1], _datas[0], _datas[1], _datas[2], _datas[2],_datas[3], _datas[4], _configs);
        } else {
            pool = FNFTPool(_addrs[0], _addrs[1], _datas[0], _datas[1], _datas[2], _datas[2],_datas[3], 1, _configs);
        }
        fnftPools[_datas[0]] = pool;
        emit CreateFNFTPool(_addrs[0], _addrs[1], _datas[0], _datas[1], _datas[2], _datas[3]);
    }

    function configsOfFNFTPool(uint256 poolId) external view returns (uint256[] memory){
        FNFTPool memory pool = fnftPools[poolId];
        return pool.configs;
    }

    /**
    * @dev create tier pool for user stake token to level up tier
    * @param _addr staking token address
    * @param _datas poolID(0), lockDuration(1), withdrawDelayDuration(2), active(3)
    */
    function createTieringPool(address _addr, uint256[] memory _datas) external onlyAdmins {
        require(_addr != address(0), "NFTFractional: Address is not the zero address");
        TierPool storage pool = tierPools[_datas[0]];
        if (pool.stakingToken == address(0)) {
            tierPools[_datas[0]] = TierPool(_addr, 0, 0, _datas[1], _datas[2], _datas[3]);
        } else {
            pool.stakingToken = _addr;
            pool.lockDuration = _datas[1];
            pool.withdrawDelayDuration = _datas[2];
            pool.active = _datas[3];
        }
        emit CreateTierPool(_addr, _datas[0], _datas[1], _datas[2]);
    }

    /**
    * @dev create reward pool for user swap f-nft token to usdt token
    * @param _addr reward token address
    * @param _datas poolID(0), fnftPoolId(1), totalRewardAmount(2), poolOpenTime(3), active(4)
    */
    function createRewardPool(address _addr, uint256[] memory _datas) external onlyAdmins {
        require(_addr != address(0), "NFTFractional: Address is not the zero address");  
        FNFTPool storage fnftPool = fnftPools[_datas[1]];
        // check f-nft pool exist
        require(fnftPool.acceptToken != address(0), "NFTFractional: FNFT Pool does not exist");
        // totalRewardAmount > 0
        require(_datas[2] > 0, "NFTFractional: Total Reward Amount must greater than zero");
        // poolOpenTime >= purchase end time
        require(_datas[3] >= fnftPool.configs[3], "NFTFractional: Pool Open Time must greater than purchase end time");
        RewardPool storage pool = rewardPools[_datas[0]];
        if (pool.rewardToken == address(0)) {
            rewardPools[_datas[0]] = RewardPool(_addr, _datas[1], _datas[2], _datas[3], _datas[4]);
        } else {
            pool.rewardToken = _addr;
            pool.totalRewardAmount = _datas[2];
            pool.active = _datas[4];
        }
        emit CreateRewardPool(_addr, _datas[0], _datas[1], _datas[2], _datas[3], _datas[4]);
    }

    /**
     * @dev Withdraw fund admin has sent to the pool
     * @param _tokenAddress: the token contract owner want to withdraw fund
     * @param _account: the account which is used to receive fund
     * @param _poolId: poolId of FNFT Pool
    */
    function withdrawFund(address _tokenAddress, address _account, uint256 _poolId) external onlyAdmins {
        FNFTPool storage pool = fnftPools[_poolId];
        FNFTInfo storage fnftInfos = fnftInfos[pool.fnftId];
        require(tierPools[_poolId].stakingToken == address(0), "NFTFractional: Tier pool is not allowed to withdraw fund");
        require(pool.acceptToken != address(0), "NFTFractional: Pool does not exist");
        require(pool.configs[3] < block.timestamp, "NFTFractional: Pool does not finish");
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(_account, balance);
        pool.availableBalance = 0 ;
        fnftInfos.availableSupply = 0;
        emit WithdrawFun(_poolId, balance, _tokenAddress, _account);
    }

    function withdrawFundToken(address _tokenAddress, address _account) external onlyController {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(_account, balance);
    }

    function setAddressSigner(address _signer) external onlyAdmins {
        signer = _signer;
    }

    /**
    * @dev function to user can purchase f-nft
    * @param _datas poolId(0), amount(1), alloction(2), purchaseFNFT(3), nonce(4)
    * @param _purchaseId purchase id of transaction
    * @param _signature signature of user
    * @param _addressUser address of user
    */
    function purchaseFNFT(uint256[] memory _datas, string memory _purchaseId,bytes memory _signature, address _addressUser) external {
        require(
            ISignatureUtils(signatureUtils).verify(
                _datas[0],
                _datas[1],
                _datas[4],
                1,
                msg.sender,
                signer,
                _signature
            ),
            "NFTFractional: Invalid Address Signer"
        );
        require(nonceSignatures[_signature] == 0, "NFTFractional: The signature has been used");
        nonceSignatures[_signature] = _datas[4];
        FNFTPool storage pool = fnftPools[_datas[0]];
        FNFTInfo storage fnftInfo = fnftInfos[pool.fnftId];
        UserInfo storage userInfo = userInfos[_datas[0]][_addressUser];
        // check FNFTPool exists
        if(pool.acceptToken == address(0)) {
            revert();
        }
        // check FNFTInfo exists
        if (fnftInfo.totalSupply == 0) {
            revert();
        }
        // current time >= purchase start time
        require(block.timestamp >= pool.configs[2], "NFTFractional: Current time must greater than purchase start time");
        // current time <= purchase end time
        require(pool.configs[3] >= block.timestamp, "NFTFractional: Purchase end time must greater than current time");
     
        if (userInfo.alloction == 0) {
            userInfo.alloction = _datas[2];
        }
        require(_datas[1] + userInfo.purchased <= userInfo.alloction, "NFTFractional: Limit allocation");
        require(_datas[3] <= pool.availableBalance, "NFTFractional: Amount must less then available balance pool");

        IERC20(pool.acceptToken).transferFrom(_addressUser, pool.receiveAddress, _datas[1]);
        IERC20(fnftInfo.tokenFNFT).transfer(_addressUser, _datas[3]);

        pool.availableBalance -= _datas[3];
        userInfo.purchased += _datas[1];
        emit PurchaseFNFT(_datas[0], userInfo.purchased, userInfo.alloction - userInfo.purchased, _datas[3], _addressUser, _purchaseId);
    }

    /**
    * @dev function to user stake to tier pool
    * @param _datas tierPoolId(0), amount(1)
    */
    function stakeTierPool(uint256[] memory _datas) external {
        TierPool storage pool = tierPools[_datas[0]];
        // check pool exist
        require(pool.stakingToken != address(0), "NFTFractional: Pool is not exist");
        // check amount > 0
        require(_datas[1] > 0, "NFTFractional: Amount is greater than zero");
        // pool must active
        require(pool.active == 1, "NFTFractional: Tiring Pool must active");
        // check balanceOf >= amount
        require(IERC20(pool.stakingToken).balanceOf(msg.sender) >= _datas[1], "NFTFractional: Not enought balance");
        IERC20(pool.stakingToken).transferFrom(msg.sender, address(this), _datas[1]);
        pool.stakedBalance += _datas[1];
        UserInfo storage userInfo = userInfos[_datas[0]][msg.sender];
        userInfo.stakeLastTime = block.timestamp;
        userInfo.stakeBalance += _datas[1];
        stakingBalances[pool.stakingToken] += _datas[1];
        emit StakeTierPool(msg.sender, _datas[0], _datas[1]);
    }

    /**
    * @dev function to user stake to tier pool
    * @param _datas tierPoolId(0), amount(1)
    */
    function unStakeTierPool(uint256[] memory _datas) external {
        TierPool storage pool = tierPools[_datas[0]];
        // check pool exists
        require(pool.stakingToken != address(0), "NFTFractional: Pool is not exist");
        // check amount > 0
        require(_datas[1] > 0, "NFTFractional: Amount is greater than zero");
        // pool must active
        require(pool.active == 1, "NFTFractional: Tiring Pool must active");
        // check balanceOf >= amount
        require(IERC20(pool.stakingToken).balanceOf(address(this)) >= _datas[1], "NFTFractional: Not enought balance");
        UserInfo storage userInfo = userInfos[_datas[0]][msg.sender];
        require(userInfo.stakeLastTime + pool.lockDuration * ONE_DAY_IN_SECONDS < block.timestamp, "NFTFractional: User is in lock duration");
        if (pool.withdrawDelayDuration > 0) {
            userInfo.pendingWithdraw += _datas[1];
        } else {
            stakingBalances[pool.stakingToken] -= _datas[1];
            IERC20(pool.stakingToken).transfer(msg.sender, _datas[1]);
        }
        userInfo.unStakeLastTime = block.timestamp;
        pool.stakedBalance -= _datas[1];
        userInfo.stakeBalance -= _datas[1];
        emit UnStakeTierPool(msg.sender, _datas[0], _datas[1]);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /**
    * @dev function withdraw delay token for user
    * @param poolId id of tier pool
    */
    function withdrawDelayToken(uint256 poolId) external {
        TierPool storage tierPool = tierPools[poolId];
        require(tierPool.stakingToken != address(0), "Tier Pool is not exist");
        // pool must active
        require(tierPool.active == 1, "NFTFractional: Tiring Pool must active");
        // require(tierPool.withdrawDelayDuration > 0, "Tier Pool must have withdrawDelayDuration > 0");
        UserInfo storage userInfo = userInfos[poolId][msg.sender];
        require(block.timestamp - userInfo.unStakeLastTime >= tierPool.withdrawDelayDuration * ONE_DAY_IN_SECONDS, "Pool doesnt finish withraw delay duration");
        stakingBalances[tierPool.stakingToken] -= userInfo.pendingWithdraw;
        IERC20(tierPool.stakingToken).transfer(msg.sender, userInfo.pendingWithdraw);
        userInfo.pendingWithdraw = 0;
    }

    /**
    * @dev function to user can claim reward
    * @param _datas poolId(0), amountFNFT(1), alloction(2), rewardUSDT(3), nonce(4)
    * @param _claimId claim id of transaction
    * @param _signature signature of user
    * @param _addressUser address of user
    */
    function claimReward(uint256[] memory _datas, string memory _claimId,bytes memory _signature, address _addressUser) external {
        require(
            ISignatureUtils(signatureUtils).verify(
                _datas[0],
                _datas[1],
                _datas[4],
                2,
                msg.sender,
                signer,
                _signature
            ),
            "NFTFractional: Invalid Address Signer"
        );
        require(nonceSignatures[_signature] == 0, "NFTFractional: The signature has been used");
        nonceSignatures[_signature] = _datas[4];
        RewardPool storage rewardPool = rewardPools[_datas[0]];
        FNFTPool storage fnftPool = fnftPools[rewardPool.fnftPoolId];
        FNFTInfo storage fnftInfo = fnftInfos[fnftPool.fnftId];
        uint256 balanceSender = IERC20(fnftInfo.tokenFNFT).balanceOf(_addressUser);
        require(rewardPool.rewardToken != address(0) && fnftPool.acceptToken != address(0), "NFTFractional: The reward pool is not exist");
        require(rewardPool.poolOpenTime <= block.timestamp, "NFTFractional: The pool does not open");
        require(balanceSender >= _datas[1], "NFTFractional: insuffcient balance");
        uint256 amountTransfer = rewardPool.totalRewardAmount >= _datas[3] ? _datas[3] : rewardPool.totalRewardAmount;
        IERC20(fnftInfo.tokenFNFT).transferFrom(_addressUser, address(this), _datas[1]);
        IERC20(rewardPool.rewardToken).transfer(_addressUser, amountTransfer);
        ERC20Token(fnftInfo.tokenFNFT).burnFrom(address(this), _datas[1]);
        rewardPool.totalRewardAmount -= amountTransfer;
        emit ClaimReward(_datas[0], _datas[1], balanceSender - _datas[1] , amountTransfer, _addressUser, _claimId);
    }
}