// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/******************* Imports **********************/
import "./stakingGlobals.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./IOracle.sol";
import "./MerkleProof.sol";


/// @title A Staking Contract
/// @author NoBorderz
/// @notice This smart contract serves as a staking pool where users can stake and earn rewards from loot boxes 
contract StakingLandTest is  OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, GlobalsAndUtils {
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;

    receive() external payable {}

    // constructor(address _rewardingToken, address _oracle) {
    //     rewardsToken = IERC721(_rewardingToken);
    //     oracle = _oracle;
    // }

    function initialize() public virtual initializer {
		__Pausable_init();
		__Ownable_init();
        __ReentrancyGuard_init();
        
         MIN_STAKE_DAYS = 10 minutes;
         EARLY_UNSTAKE_PENALTY = 18;
         STAKING_TOKEN_DECIMALS = 1e18;
         CLAIM_X_TICKET_DURATION = 1 minutes;
        MIN_STAKE_TOKENS = 100 * STAKING_TOKEN_DECIMALS;
        LAND_ADDRESS = address(0x932F97A8Fd6536d868f209B14E66d0d984fE1606);
        GENESIS_ADDRESS = address(0x5b5cf41d9EC08D101ffEEeeBdA411677582c9448);
		
	}

    function setClaimXTicketDuration() onlyOwner public {
        CLAIM_X_TICKET_DURATION = 5 minutes;
    }

    /**********************************************************/
    /******************* Public Methods ***********************/
    /**********************************************************/

    /**
     * @dev PUBLIC FACING: Open a stake.
     */
    function stakeLand(uint256 tokenId, uint256 size, string calldata rarity, uint256[] memory genesisTokenIds, bytes32[] calldata proof) whenNotPaused external payable nonReentrant CampaignOnGoing {
       require(size.mul(size) == genesisTokenIds.length, "invalid genesis tokens");
        // require(isWhitelisted(rarity,size, tokenId, proof), "invalid land tokenId");
        require(msg.sender == tx.origin, "invalid sender");
        require(msg.sender == IERC721(LAND_ADDRESS).ownerOf(tokenId), "land is not in your ownership");
        _addStake(tokenId, size,rarity,genesisTokenIds);
        totalStakedAmount++;
        userStakedAmount[msg.sender]++;
        IERC721(LAND_ADDRESS).transferFrom(msg.sender,address(this), tokenId);
        escrowGenesisTokenIds(genesisTokenIds, false);
        emit StakeStart(msg.sender, latestStakeId, tokenId, genesisTokenIds);
    }

    /**
     * @dev PUBLIC FACING: Closes a stake.
     * @param _stakeId ID of the stake to close
     */
    function claimUnstake(uint256 _stakeId) whenNotPaused nonReentrant public {
        UnStake memory usrStake = unStakes[msg.sender][_stakeId];
        require(usrStake.tokenId > 0, "stake doesn't exist");
        require(usrStake.isAppliedFor, "already claim");

        _removeAppliedFor(_stakeId);

        bool isClaimable = _calcPayoutAndPenalty(usrStake);

           // Transfer payout amount to stake owner
        require(isClaimable, "can not claim");
        
        IERC721(usrStake.landCollection).transferFrom(address(this), msg.sender, usrStake.tokenId);
        escrowGenesisTokenIds(usrStake.genesisTokenIds, true);
        
        emit StakeEnd(msg.sender, _stakeId, usrStake.tokenId, usrStake.genesisTokenIds);
    }
    /**
     * @dev EXTERNAL METHOD: Method for emergency unstake
     * and updating state accordingly
     */
     function appplyForUnstake(uint256 _stakeId)  whenNotPaused external {
         Stake memory usrStake = stakes[msg.sender][_stakeId];
        require(usrStake.tokenId > 0, "stake doesn't exist");
        _unStake(_stakeId);
        emit AppliedUnstake(msg.sender, _stakeId, usrStake.tokenId, unStakes[msg.sender][_stakeId].genesisTokenIds);
    }

   

    /**
     * @dev PUBLIC FACING: Returns an array of ids of user's active stakes
     * @param stakeOwner Address of the user to get the stake ids
     * @return Stake Ids
     */
    function getUserStakesIds(address stakeOwner) external view returns (uint256[] memory) {
        return userStakeIds[stakeOwner];
    }

    


    /**
     * @dev PUBLIC FACING: Returns an array of ids of user's active stakes
     * @param stakeOwner Address of the user to get the stake ids
     * @return unStake Ids
     */
    function getUserUnStakesIds(address stakeOwner) external view returns (uint256[] memory) {
        return userUnStakeIds[stakeOwner];
    }

    /**
     * @dev PUBLIC FACING: Returns information about a specific stake
     * @param stakeOwner Address of the stake owner
     * @param stakeId ID of the stake
     * @return User stake
     */
    function getUnStake(address stakeOwner, uint256 stakeId) external view returns(UnStake memory) {
         
        return unStakes[stakeOwner][stakeId];
    }

    

    /**
     * @dev PUBLIC FACING: Returns information about a specific stake
     * @param stakeOwner Address of the stake owner
     * @param stakeId ID of the stake
     * @return User stake
     */
    function getStake(address stakeOwner, uint256 stakeId) external view returns(Stake memory) {
        return stakes[stakeOwner][stakeId];
    }
/**
     * @dev PUBLIC FACING: is emergency or claim
     * @param stakeOwner Address of the stake owner
     * @param stakeId ID of the stake
     * @return User stake
     */
    function getIsClaimable(address stakeOwner, uint256 stakeId) external view returns(bool) {
        UnStake memory usrStake = unStakes[stakeOwner][stakeId];
        return _calcPayoutAndPenalty(usrStake);
    }
    
    
    /**
     * @dev PUBLIC FACING: Returns information about a specific stake
     * @param stakeOwner Address of the stake owner
     * @param stakeId ID of the stake
     * @return User stake
     * this function is public now to check but it should be internal 
     */
    function userClaimable(address stakeOwner, uint256 stakeId) public view returns(uint256) {
        Stake memory usrStake = stakes[stakeOwner][stakeId];
        uint256 stakedDays;
        if (
            campaigns[latestCampaignId].endTime == 0 ||
            // campaigns[latestCampaignId].endTime < block.timestamp ||
            campaigns[latestCampaignId].startTime > block.timestamp
        ) stakedDays = 0;
        else (, stakedDays) = _getUserStakedDays(usrStake);
       
        uint256 usrStakedAmount = usrStake.xTickets;
        uint256 claimableTickets = stakedDays.mul(usrStakedAmount);

        uint256 newTickets = totalUserXTickets[stakeOwner][latestCampaignId] == 0 ? claimableTickets : 0;
        return newTickets;
    }

    /**
     * @dev PUBLIC FACING: Users can claim their
     * xtickets after staking for more than 24 hours
     * pausing contract
     */
    function pause() public onlyOwner {
        _pause();
    }
 /**
     * @dev PUBLIC FACING: Users can claim their
     * unpausing contract
     * 
     */
    function unpaused() public onlyOwner {
        _unpause();
    }

    /**
     * @dev PUBLIC FACING: Users can claim their
     * xtickets after staking for more than 24 hours
     * @return newClaimedTickets
     */
    function joinRuffle() whenNotPaused external ClaimXTicketAllowed returns (uint256 newClaimedTickets) {
        require(campaigns[latestCampaignId].endTime < block.timestamp && campaigns[latestCampaignId].endTime != 0, "can't claim");
        require( totalUserXTickets[msg.sender][latestCampaignId] == 0, "already claimed");
         userXTicketRange[msg.sender][latestCampaignId].start = totalClaimableTickets + 1;
         XTicketRange storage tempRange = userXTicketRange[msg.sender][latestCampaignId];
        newClaimedTickets = 0;
        for (uint256 x=0; x < userStakeIds[msg.sender].length; x++) {
            newClaimedTickets += _getClaimableXTickets(msg.sender, userStakeIds[msg.sender][x]);
        }
         userXTicketRange[msg.sender][latestCampaignId].end = totalClaimableTickets;
         require(tempRange.start <= totalClaimableTickets, "no tickets earned");
         emit RuffleJoined(msg.sender, latestCampaignId, tempRange.start, totalClaimableTickets);

    }

     /**
     * @dev INTERNAL METHOD: Update number of
     * claimable tickets a user currently has
     * and add it to the total claimable tickets
     * @param _stakeOwner Address of owner of the stake
     * @param _stakeId Id of the stake
     * @return Number of tickets claimed against stake
     */
    function _getClaimableXTicketsView(address _stakeOwner, uint256 _stakeId) private view returns(uint256) {
        Stake memory usrStake = stakes[_stakeOwner][_stakeId];
        uint256 usrStakedAmount = usrStake.xTickets;
        return usrStakedAmount;
    }

      /**
     * @dev PUBLIC FACING: Users can claim their
     * xtickets after staking for more than 24 hours
     * @return newClaimedTickets
     */
    function perDayXTicketsUserClaimable() public view  returns (uint256 newClaimedTickets) {
        newClaimedTickets = 0;
        for (uint256 x=0; x < userStakeIds[msg.sender].length; x++) {
            newClaimedTickets += _getClaimableXTicketsView(msg.sender, userStakeIds[msg.sender][x]);
        }
        
    }

    /**
     * @dev PUBLIC FACING: Users can claim their rewards (if any)
     */
    function claimStakingReward(uint256 campaignId, uint256 limit, bytes32[] calldata proof) whenNotPaused  external {
        require(rewardsReceived[msg.sender][campaignId] == 0, "already claimed");
        require(isRewardOpen[campaignId], "reward not open");
        require(limit > 0, "no reward");
        require(isUserWinner(limit, campaignId, proof),"not authorize");
        _rewardWinner(msg.sender,campaignId, limit);
    }

    /**
     * @dev PUBLIC FACING: Array of users that have active stakes
     * @return activeStakeOwners
     */
    function getActiveStakers() external view returns(address[] memory) {
        return activeStakeOwners;
    }

    /**
     * @dev PUBLIC FACING: Get details of the current campaign
     * @return campaignId
     * @return rewardCount
     * @return startTime
     * @return endTime
     */
    function getCurrentCampaignDetails() external view returns(uint256 campaignId, uint256 rewardCount, uint256 startTime, uint256 endTime,  uint256 ruffleTime) {
        campaignId = latestCampaignId;
        rewardCount = campaigns[latestCampaignId].rewardCount;
        startTime = campaigns[latestCampaignId].startTime;
        endTime = campaigns[latestCampaignId].endTime;
        ruffleTime = CLAIM_X_TICKET_DURATION;
    }

    function getCampaignDetails(uint256 _campaignId) external view returns(uint256 rewardCount, uint256 startTime, uint256 endTime, address collection) {
        rewardCount = campaigns[_campaignId].rewardCount;
        startTime = campaigns[_campaignId].startTime;
        endTime = campaigns[_campaignId].endTime;
        collection = campaigns[_campaignId].collection;
    }

    /**
     * @dev PUBLIC FACING: Get number of claimed tickets by a user
     * @return newClaimedTickets
     */
    function getClaimableTickets() external view returns(uint256 newClaimedTickets) {
          newClaimedTickets = 0;
        if( totalUserXTickets[msg.sender][latestCampaignId] > 0){
            newClaimedTickets =  0;
        }else {
            uint256 length = userStakeIds[msg.sender].length;
            uint256[] memory idsArray = userStakeIds[msg.sender];
            for (uint256 x=0; x < length; x++) {
            newClaimedTickets += userClaimable(msg.sender, idsArray[x]);
        }
        }
        
    }

    function getGlobals() public view returns(uint256, uint256){
           return (MIN_STAKE_DAYS, CLAIM_X_TICKET_DURATION);
    }

    
    /**
     * @dev PUBLIC METHOD: Method to get a nftID
     * from a collection
     */
    function getRewardClaimable(uint256 campaignId) public view  returns(uint256[] memory, uint256, uint256, uint256, uint256, uint256) {
        return (getXTicektedIDs(campaignId), campaigns[campaignId].rewardCount, campaigns[campaignId].startTime, campaigns[campaignId].endTime, rewardsReceived[msg.sender][campaignId], totalUserXTickets[msg.sender][campaignId]);
    }

    /**
     * @dev INTERNAL METHOD: Method to get a nftID
     * from a collection
     * @return stakerPenaltyBonus
     */
    function getWinningTickIds(uint256 campaignId) public view returns(uint256[] memory) {
        return winningTicketIds[campaignId];
    }

    function isWhitelisted(string memory rarity,  uint256 size, uint256 tokenId,bytes32[] calldata proof) public view returns (bool) {
        return _verify(_leaf(tokenId, rarity, size), proof, landRootHash);
    }
    function _leaf(uint256 tokenId, string memory rarity, uint256 size) public pure returns (bytes32) {
        return keccak256(abi.encode(tokenId, rarity, size));
    }
    function _verify(bytes32 leaf,bytes32[] memory proof,bytes32 root) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /**********************************************************/
    /******************* Admin Methods ************************/
    /**********************************************************/

    /**
     * @dev ADMIN METHOD: Start a campaign.
     * @param startTime Time at which the campaign will start
     * @param endTime Time at which the campaign will end
     * @param rewardCount Total number of rewards in the campaign
     */
    function startLootBox(uint256 startTime, uint256 endTime, uint256 rewardCount, address _awardCollection) external onlyOwner campaignEnded {
        require(startTime >= block.timestamp, "start cannot be in past");
        require(startTime < endTime, "cannot end before start");

        rewardsToken = IERC721(_awardCollection);

        // end cooldown period
        totalClaimableTickets = 0;

        // start a new campaign
        latestCampaignId += 1;
        campaigns[latestCampaignId] = Campaign(rewardCount, startTime, endTime, _awardCollection);

        emit CampaignStarted(rewardCount, startTime, endTime);
    }

    /**
     * @dev ADMIN METHOD: Start a campaign.
     * @param startTime Time at which the campaign will start
     * @param endTime Time at which the campaign will end
     */
    function editLootBox(uint256 startTime, uint256 endTime) external onlyOwner {        
        campaigns[latestCampaignId].startTime = startTime;
        campaigns[latestCampaignId].endTime = endTime;

        emit CampaignEdited(startTime, endTime);
    }

    function setRewardCanBeClaim(uint256 campaignId, bool status) onlyOwner public {
        require(campaignRewardsRoot[campaignId] != bytes32(0x0), "reward not distributed");
        isRewardOpen[campaignId] = status;
    }

    function setCampaignWinners(uint256 campaignId, bytes32 _root) onlyOwner public {
        campaignRewardsRoot[campaignId] = _root;
    }

    /**
     * @dev ADMIN METHOD: Pick winners from who have xtickets
     */
    function rewardLootBox(uint256 end, uint256 campaignId) external onlyOwner  {
        require(winningTicketIds[campaignId].length + end <= campaigns[campaignId].rewardCount, "exceeded reward limit");
        string memory api = campaignId.toString();
        string memory params = end.toString();
        IOracle(oracle).createRequest(api, params, address(this), "callback(uint256[],uint256)");
        
    }

    function callback(uint256[] memory ids, uint256 campaignId)onlyOracle public {
        require(winningTicketIds[campaignId].length + ids.length <= campaigns[campaignId].rewardCount, "exceeded reward limit");

        for(uint256 i = 0; i<ids.length; i++){
             winningTicketIds[campaignId].push(ids[i]);
            winningTixketIdExist[campaignId][ids[i]] = true;
        }
    }

    function setOracleAddress(address _add) onlyOwner public {
        oracle = _add;
    }

    function setLandRoot(bytes32 _root) onlyOwner external {
        landRootHash = _root;
    }

     function setTickEraned(string calldata rarity, uint256 size, uint256 amount) onlyOwner external {
       XticketEarnPerDay[rarity][size] = amount;
    }



    /**
     * @dev ADMIN METHOD: Add collections to a campaign
     * @param _collection Array of collections to add to the campaign
     */
    function updateRewardCollection(address _collection, uint256 campaignId) external onlyOwner {
        require(_collection != address(0), "invalid collection address");
        campaigns[campaignId].collection = _collection;
        rewardsToken = IERC721(campaigns[campaignId].collection);
    }


    /**
     * @dev ADMIN METHOD: Withdraw total tokens in contract
     * @param receiver Address of the user to transfer the nft to
     */
    function emergencyWithdraw(address receiver) external onlyOwner {
        require(receiver != address(0), "invalid address");

        (bool success, ) = receiver.call{value: address(this).balance}("");
        require(success, "couldn't transfer tokens");
    }

    /**
     * @dev ADMIN METHOD: Start a campaign.
     * @param rewardCount Total number of rewards in the campaign
     */
    function startLootBox(uint256 rewardCount) external onlyOwner campaignEnded {
       
        Campaign storage temp = campaigns[latestCampaignId + 1];
        // require(temp.startTime >= block.timestamp, "start cannot be in past");
        require(temp.startTime < temp.endTime, "cannot end before start");

        rewardsToken = IERC721(temp.collection);
        // start a new campaign
        latestCampaignId += 1;
        
        // end cooldown period


        totalClaimableTickets = 0;

        
        campaigns[latestCampaignId].rewardCount = rewardCount;

        emit CampaignStarted(rewardCount, temp.startTime, temp.endTime);
    }

    function setCampaignDetails(uint256 campaignId, uint256 rewardCount, uint256 startTime, uint256 endTime, address collection) external onlyOwner {
        require(startTime < endTime, "cannot end before start");
        campaigns[campaignId] = Campaign(rewardCount, startTime, endTime, collection);
    }

    
    /**********************************************************/
    /******************* Private Methods **********************/
    /**********************************************************/

   

    /**
     * @dev INTERNAL METHOD: Method for starting stake
     * and updating state accordingly
     * @param tokenId Amount of tokens staked
     */
    function _addStake(uint256 tokenId, uint256 size, string calldata rarity, uint256[] memory genesisTokenIds) private {
        latestStakeId += 1;
        stakes[msg.sender][latestStakeId] = Stake(block.timestamp, tokenId, LAND_ADDRESS, genesisTokenIds, size, rarity, XticketEarnPerDay[rarity][size]);
        userStakeIds[msg.sender].push(latestStakeId);

        // update index of user address in activeStakeOwners to stakeOwnerIndex
        if (activeStakeOwners.length == 0) {
            activeStakeOwners.push(msg.sender);
            stakeOwnerIndex[msg.sender] = 0;
        } else if (activeStakeOwners.length > 0 && activeStakeOwners[stakeOwnerIndex[msg.sender]] != msg.sender) {
            activeStakeOwners.push(msg.sender);
            stakeOwnerIndex[msg.sender] = activeStakeOwners.length - 1;
        }
    }

    /**
     * @dev INTERNAL METHOD: Method for starting stake
     * and updating state accordingly
     * @param genesisTokenIds Amount of tokens staked
     */
    function escrowGenesisTokenIds(uint256[] memory genesisTokenIds, bool fromContract) private {
        bool valid = true;
        address tempOwner;
        uint256 tokenId;
        for (uint256 index = 0; index < genesisTokenIds.length; index++) {
            tokenId = genesisTokenIds[index];
            if(fromContract){
                
                IERC721(GENESIS_ADDRESS).transferFrom(address(this), msg.sender, tokenId);
            }else {
                tempOwner = IERC721(GENESIS_ADDRESS).ownerOf(tokenId);
            if(tempOwner != msg.sender){
                valid = false;
                break;
            }
            IERC721(GENESIS_ADDRESS).transferFrom(msg.sender, address(this), tokenId);
            }
            
        }
        if(!valid){
         revert("genesis is not in your owned");
        }
    }

    /**
     * @dev INTERNAL METHOD: Method for ending stake
     * and updating state accordingly
     * @param _stakeId ID of the stake to unstake
     */
    function _unStake(uint256 _stakeId) private {
        // Remove stake id from users' stakIdArray
        if (userStakeIds[msg.sender].length > 1) {
            for (uint256 x = 0; x < userStakeIds[msg.sender].length; x++) {
                // find the index of stake id in userStakes
                if (userStakeIds[msg.sender][x] == _stakeId) {
                    if (userStakeIds[msg.sender].length > 1) {
                        userStakeIds[msg.sender][x] = userStakeIds[msg.sender][userStakeIds[msg.sender].length.sub(1)];
                        userStakeIds[msg.sender].pop();
                    } else {
                        userStakeIds[msg.sender].pop();
                    }
                }
            }
        } else {
            userStakeIds[msg.sender].pop();
        }

        // Remove address from current stake owner's array number if stakes are zero
        if (userStakeIds[msg.sender].length == 0) {
            if (activeStakeOwners.length > 1) {
                // replace address to be removed by last address to decrease array size
                activeStakeOwners[stakeOwnerIndex[msg.sender]] = activeStakeOwners[activeStakeOwners.length.sub(1)];

                // set the index of replaced address in the stakeOwnerIndex mapping to the removed index
                stakeOwnerIndex[activeStakeOwners[activeStakeOwners.length.sub(1)]] = stakeOwnerIndex[msg.sender];

                // remove address from last index
                activeStakeOwners.pop();
            } else {
                // set the index of replaced address in the stakeOwnerIndex mapping to the removed index
                stakeOwnerIndex[activeStakeOwners[activeStakeOwners.length.sub(1)]] = stakeOwnerIndex[msg.sender];

                // remove address from last index
                activeStakeOwners.pop();
            }

            // set the index of removed address to zero
            stakeOwnerIndex[msg.sender] = 0;
        }

        // remove staked amount from total staked amount
        totalStakedAmount--;

        userUnStakeIds[msg.sender].push(_stakeId);

        userStakedAmount[msg.sender]--; 

        unStakes[msg.sender][_stakeId] = UnStake(stakes[msg.sender][_stakeId].stakedAt, block.timestamp,0,stakes[msg.sender][_stakeId].tokenId,LAND_ADDRESS,stakes[msg.sender][_stakeId].genesisTokenIds,stakes[msg.sender][_stakeId].size,stakes[msg.sender][_stakeId].rarity,stakes[msg.sender][_stakeId].xTickets, true);

        // Remove user's stake values
        delete stakes[msg.sender][_stakeId];
    }

     /**
     * @dev INTERNAL METHOD: Method for ending stake
     * and updating state accordingly
     * @param _stakeId ID of the stake to unstake
     */
    function _removeAppliedFor(uint256 _stakeId) private {
        // Remove stake id from users' stakIdArray
       

        unStakes[msg.sender][_stakeId].isAppliedFor = false;
        unStakes[msg.sender][_stakeId].unStakedAt = block.timestamp;

        // Remove user's stake values
        // delete stakes[msg.sender][_stakeId];
    }

    /**
     * @dev INTERNAL METHOD: Return staked time of
     * a user in unix timestamp and days
     * @param usrStake Instance of stake to get time of
     */
    function _getUserStakedTime(UnStake memory usrStake) private view returns (uint256 unixStakedTime) {
        unixStakedTime =  block.timestamp.sub(usrStake.appliedAt);
    }

     /**
     * @dev INTERNAL METHOD: Return staked time of
     * a user in unix timestamp and days
     * @param usrStake Instance of stake to get time of
     */
    function _getUserStakedDays(Stake memory usrStake) private view returns (uint256 unixStakedTime, uint256 stakedDays) {
        uint256 stakedTime = usrStake.stakedAt;
        uint256 nowTime = block.timestamp;
        Campaign storage tempCampaign = campaigns[latestCampaignId];
        if( nowTime > tempCampaign.startTime && tempCampaign.startTime > usrStake.stakedAt)
        {
            stakedTime = tempCampaign.startTime;
        }
        if(stakedTime < tempCampaign.endTime && block.timestamp > tempCampaign.endTime &&  tempCampaign.endTime != 0){
            nowTime  = tempCampaign.endTime;
        }
        unixStakedTime = nowTime.sub(stakedTime);
        stakedDays = unixStakedTime.div(1 minutes);
    }

    /**
     * @dev INTERNAL METHOD: Update number of
     * claimable tickets a user currently has
     * and add it to the total claimable tickets
     * @param _stakeOwner Address of owner of the stake
     * @param _stakeId Id of the stake
     * @return Number of tickets claimed against stake
     */
    function _getClaimableXTickets(address _stakeOwner, uint256 _stakeId) private returns(uint256) {
        Stake memory usrStake = stakes[_stakeOwner][_stakeId];
        uint256 stakedDays;
        if (
            campaigns[latestCampaignId].endTime == 0 ||
            // campaigns[latestCampaignId].endTime < block.timestamp ||
            campaigns[latestCampaignId].startTime > block.timestamp
        ) stakedDays = 0;
        else (, stakedDays) = _getUserStakedDays(usrStake);
        
        uint256 usrStakedAmount = usrStake.xTickets;
        uint256 claimableTickets = stakedDays.mul(usrStakedAmount);

        // update total number of claimable tickets
        totalClaimableTickets += claimableTickets;

        totalUserXTickets[msg.sender][latestCampaignId] = totalUserXTickets[msg.sender][latestCampaignId] + claimableTickets;

        return claimableTickets;
    }

    /**
     * @dev INTERNAL METHOD: Calculate payout and penalty
     * @param usrStake Instance of stake to calculate payout and penalty of
     * @return isClaimAble
     */
    function _calcPayoutAndPenalty(UnStake memory usrStake) private view returns(bool isClaimAble) {
        (uint256 unixStakedTime) = _getUserStakedTime(usrStake);

        if (unixStakedTime >= MIN_STAKE_DAYS) {
            isClaimAble = true;
        } else {
            isClaimAble = false;
        }
    }  

    /**
     * @dev INTERNAL METHOD: Calculate penalty if
     * user unstakes before min stake period
     * @param _totalAmount total staked amount
     * @return payout
     */
    function _calcPenalty(uint256 _totalAmount) private view returns(uint256 payout) {
        return _totalAmount.mul(EARLY_UNSTAKE_PENALTY).div(100);
    }

    /**
     * @dev INTERNAL METHOD: Method to reward winner nfts
     * @param _winnerAddress address of the winner to transfer nfts to
     */
    function _rewardWinner(address _winnerAddress, uint256 campaignId, uint256 limit) private {
        
        rewardsReceived[_winnerAddress][campaignId] += limit;
        rewardsToken = IERC721(campaigns[campaignId].collection);
        (uint256 from, uint256 to) = rewardsToken.mint(msg.sender,  rewardsReceived[_winnerAddress][campaignId]);
        if (from == 0 || to == 0) revert("couldn't mint");
        emit CampaignReward(campaignId, address(rewardsToken), from, to, msg.sender);
    }    

    function isUserWinner(uint256 limit,uint256 campaignId, bytes32[] calldata proof) public view returns (bool) {
        return _verify(_leafWinner(limit, msg.sender), proof, campaignRewardsRoot[campaignId]);
    }
    function _leafWinner(uint256 limit, address user) public pure returns (bytes32) {
        return keccak256(abi.encode(user, limit));
    }
    /**
     * @dev INTERNAL METHOD: Method to get a nftID
     * from a collection
     * @return userXticketsIds
     */
    function getXTicektedIDs(uint256 campaignId) private view  returns(uint256[] memory) {
        if(rewardsReceived[msg.sender][campaignId] > 0){
            uint256[] memory tempArray;
            return tempArray;
        }
         uint256 rangeStart = userXTicketRange[msg.sender][campaignId].start;
       uint256 rangeEnd =  userXTicketRange[msg.sender][campaignId].end;
       uint256[] memory _winningTicketIds = winningTicketIds[campaignId];
       uint256 count;
        for (uint256 j; j < _winningTicketIds.length; j++) {
            uint256 winningTicketId = _winningTicketIds[j];
           if(winningTicketId >= rangeStart && winningTicketId <= rangeEnd){
                count++;
           }
        }
        uint256 i;
        uint256[] memory _userXticketsIds = new uint256[](count);
        for (uint256 j; j < _winningTicketIds.length; j++) {
            uint256 winningTicketId = _winningTicketIds[j];
           if(winningTicketId >= rangeStart && winningTicketId <= rangeEnd){
                _userXticketsIds[i] = winningTicketId;
                i++;
           }
        }
        return _userXticketsIds;
    }

    

   

    
}