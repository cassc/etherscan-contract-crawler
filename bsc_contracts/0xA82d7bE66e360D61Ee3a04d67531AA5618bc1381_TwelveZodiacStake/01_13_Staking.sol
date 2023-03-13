// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Strings.sol";
import "./IContractNFT.sol";
import "./IContractToken.sol";

contract TwelveZodiacStake is Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct NFTInfo {
        uint256 tokenid;
        uint256 fuel;
        bool exists;
    }

    struct Plans {
        uint8 planid;
        string title;
        uint256 addblock;
        uint8 reward;
        uint8 fee;
    }

    struct StakeInfo {
        uint8 planid;
        uint256 amount;
        uint256 startat;
        uint256 endat;
        uint256 blockclaimed;
        uint256 claimed;
        uint256 nextclaimat;
    }

    struct Halving {
        uint8 stage;
        uint256 lastblock; // 0 = unlimited
    }

    address tokenStake;
    uint256 constant PERCENT_PRECISION = 1e12;
    uint256 constant TOKEN_DECIMALS = 1e18;
    uint256 constant DAILY_BLOCKS = 28800;
    uint256 MINIMUM_STAKE = (1 * TOKEN_DECIMALS);
    address COLLECTOR;
    uint256 COST = 0;
    uint256 AVALIABLE_BALANCE = 0;
    uint256 REWARD_COLLECTED = 0;
    uint256 TOTAL_STAKE = 0;
    uint256 REWARD_RATE = 5;
    uint256 CLAIM_EVERY = 28800;

    Halving[] _halvings;
    mapping(uint256 => StakeInfo) _stakes;
    mapping(address => uint256[]) _holderstakes;
    mapping(uint8 => Plans) _plans;
    mapping(uint256 => NFTInfo) _nftinfo;

    IContractToken TOKEN;
    IContractNFT NFT;

    constructor(address token_address, address nft_address) {
        tokenStake = token_address;
        TOKEN = IContractToken(token_address);
        NFT = IContractNFT(nft_address);
        COLLECTOR = msg.sender;
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event TopupPoolStake(uint256 amount);
    event StakeToken(address owner, uint256 tokenid, uint256 planid, uint256 end, uint256 amount, uint256 fuel);
    event ClaimRewardStake(address owner, uint256 tokenid, uint256 reward, uint256 duration);
    event WithdrawStake(address owner, uint256 tokenid, uint256 amount);
 
    function currentBlock() public view returns (uint256) {
        return block.number;
    }

    function getPoolBalances() public view returns (uint256) {
        return AVALIABLE_BALANCE;
    }

    function getTotalStakes() public view returns (uint256) {
        return TOTAL_STAKE;
    }

    function getTotalCollected() public view returns (uint256) {
        return REWARD_COLLECTED;
    }

    function showHalvingPlans() public view returns (Halving[] memory) {
        return _halvings;
    }

    function showPlanConfig(uint8 _id) public view returns (Plans memory) {
        return _plans[_id];
    }

    function _checkNFTOwnership(address _holder, uint256 _tokenid) internal view returns (bool) {
        address owner_nft = NFT.ownerOf(_tokenid);
        if(address(owner_nft) == address(_holder)) return true; else return false;
    }

    function _checkStakingOwnership(address _holder, uint256 _tokenid) internal view returns (bool) {
        uint256[] memory lists = _holderstakes[_holder];
        for(uint i = 0; i < lists.length; i++) {
            if(lists[i] == _tokenid) return true;
        }
        return false;
    }

    function addNFTData(uint256 _tokenid) internal {
        // convert fuel (day) to block (1 day = 28800 block);
        IContractNFT.NFTProducts memory data = NFT.getTokenData(_tokenid);
        uint256 fuel = (data.fuel * DAILY_BLOCKS);
        _nftinfo[_tokenid] = NFTInfo(_tokenid, fuel, true);
    }

    function addStakeholder(address _holder, uint256 _amount, uint8 _planid, uint256 _tokenid) internal returns (uint256 endblock)  {
        endblock = block.number + _plans[_planid].addblock;
        _stakes[_tokenid] = StakeInfo({
                                planid: _planid,
                                amount: _amount,
                                startat: block.number,
                                endat: endblock,
                                blockclaimed: 0,
                                claimed: 0,
                                nextclaimat: (block.number + CLAIM_EVERY)
                            });
        _holderstakes[_holder].push(_tokenid);
        return (endblock);
    }

    function Stake(uint256 _amount, uint8 _planid, uint256 _tokenid) public whenNotPaused {
        require(_amount >= MINIMUM_STAKE, string.concat("Minimum Stake is ", Strings.toString((MINIMUM_STAKE / TOKEN_DECIMALS))));
        require(_checkNFTOwnership(msg.sender, _tokenid), "Not owner NFT.");
        require(_tokenid > 0, "Token value cannot be zero.");
        require(_planid > 0, "Plan value cannot be zero.");
        require(_plans[_planid].planid > 0, "Plan is unavailable.");
        if(!_nftinfo[_tokenid].exists) addNFTData(_tokenid); // if NFT not exists add into collection
        require(_stakes[_tokenid].amount == 0, "Token has been staked.");
        require(_nftinfo[_tokenid].fuel > 0, "Sorry, your NFT is run out of fuel.");
        require(TOKEN.transferFrom(msg.sender, address(this), _amount), "Can not paid this transaction");
        uint256 _end = addStakeholder(msg.sender, _amount, _planid, _tokenid); // create staking collection
        TOTAL_STAKE += _amount;

        emit StakeToken(msg.sender, _tokenid, _planid, _end, _amount, _nftinfo[_tokenid].fuel);
    }

    function showAddressStakes(address _holder) public view returns (uint256[] memory) {
        return _holderstakes[_holder];
    }

    struct StakeDataReturn {
        uint256 tokenid;
        string plan;
        uint256 amount;
        uint256 startat;
        uint256 endat;
        uint256 claimed;
        uint256 nextclaim;
        uint256 tokenfuel;
    }

    function showStakeData(uint256 _tokenid) public view returns (StakeDataReturn memory) {
        StakeInfo memory data = _stakes[_tokenid];
        return StakeDataReturn({
            tokenid: _tokenid,
            plan: _plans[data.planid].title, 
            amount: data.amount, 
            startat: data.startat, 
            endat: data.endat, 
            claimed: data.claimed, 
            nextclaim: data.nextclaimat,
            tokenfuel: _nftinfo[_tokenid].fuel
        });
    }

    function showTokenData(uint256 _tokenid) public view returns (uint256 tokenid, uint256 fuel) {
        return ( _nftinfo[_tokenid].tokenid, _nftinfo[_tokenid].fuel );
    }

    function unClaimedBlock(uint256 _tokenid) public view returns (uint256 block_unclaim) {
        StakeInfo memory stakedata = _stakes[_tokenid];
        uint256 lastblock = block.number;
        // if not flexible and lastblock greater than endtime then make lastblock to endtime
        if(stakedata.endat > stakedata.startat && lastblock > stakedata.endat) lastblock = stakedata.endat;
        // unclaimed = lastblock - claimedblock
        block_unclaim = (lastblock - (stakedata.startat + stakedata.blockclaimed));
        // check if unclaimed greater than fuel
        if(block_unclaim > _nftinfo[_tokenid].fuel) block_unclaim = _nftinfo[_tokenid].fuel;
        return block_unclaim;
    }

    function getPendingRewardByStake(uint256 _tokenid) public view returns(uint256) {
        uint256 pendingReward = 0;
        StakeInfo storage stakedata = _stakes[_tokenid];
        if(stakedata.amount > 0) {
            uint duration = unClaimedBlock(_tokenid);
            uint256 lastClaimBlock = (stakedata.startat + stakedata.blockclaimed);
            for(uint i = 0; i < _halvings.length; i++) {
                Halving storage halv = _halvings[i];
                uint claimed = 0;
                if(duration > 0) {
                    if(halv.lastblock == 0) {
                        claimed = duration;
                    } else if(halv.lastblock > lastClaimBlock) {
                        claimed = (halv.lastblock - lastClaimBlock);
                        if(claimed > duration) claimed = duration;
                    }
                    uint256 rewardatblock = ((stakedata.amount * ((REWARD_RATE * PERCENT_PRECISION) / (2 ** halv.stage))) / (7 * 100 * PERCENT_PRECISION)) / DAILY_BLOCKS;
                    pendingReward += rewardatblock * claimed;
                    duration = duration - claimed;
                } else {
                    i = _halvings.length;
                }
            }
        }
        return pendingReward;
    }
    
    function ClaimReward(uint256 _tokenid) public payable whenNotPaused {
        require(msg.value >= COST);
        require(_checkStakingOwnership(msg.sender, _tokenid), "Only holder can do this request.");
        require(AVALIABLE_BALANCE > 0, "Pool finished");
        require(_nftinfo[_tokenid].fuel > 0, "Your NFT is run out of fuel.");
        uint256 nextclaim = _stakes[_tokenid].nextclaimat;
        require(block.number > nextclaim, string.concat("Next claim reward after block ", Strings.toString(nextclaim)));
        uint256 pendingReward = getPendingRewardByStake(_tokenid);
        require(pendingReward > 0, "No reward distributed.");
        uint256 diff = (uint256((block.number - _stakes[_tokenid].startat) / CLAIM_EVERY) * CLAIM_EVERY) + CLAIM_EVERY;
        _stakes[_tokenid].nextclaimat += diff;
        _claimreward(_tokenid);
    }

    function _claimreward(uint256 _tokenid) internal {
        uint256 pendingReward = getPendingRewardByStake(_tokenid);
        uint256 pendingBlock = unClaimedBlock(_tokenid);
        if(pendingReward > 0) {
            StakeInfo storage staking = _stakes[_tokenid];
            if(pendingReward > AVALIABLE_BALANCE) pendingReward = AVALIABLE_BALANCE;

            staking.blockclaimed += pendingBlock;
            staking.claimed += pendingReward;
            _nftinfo[_tokenid].fuel -= pendingBlock;

            uint256 sendtoholder = ((pendingReward * _plans[staking.planid].reward) / 100);
            uint256 stakefee = ((pendingReward * _plans[staking.planid].fee) / 100);
            
            emit ClaimRewardStake(msg.sender, _tokenid, pendingReward, pendingBlock);

            if(sendtoholder > 0) SendReward(msg.sender, sendtoholder);
            if(stakefee > 0) SendReward(COLLECTOR, stakefee);
        }
    }

    function SendReward(address _receiver, uint256 _amount) internal {
        AVALIABLE_BALANCE -= _amount;
        REWARD_COLLECTED += _amount;
        TOKEN.transfer(_receiver, _amount);
    }

    function Withdraw(uint256 _tokenid) public {
        require(_checkStakingOwnership(msg.sender, _tokenid), "Only holder can do this request.");
        require(_stakes[_tokenid].amount > 0, "Staking not found.");
        require(_stakes[_tokenid].endat < block.number, "Staking not finished yet.");

        // if pending reward > 0 then claim the reward before withdrawal
        uint256 pendingReward = getPendingRewardByStake(_tokenid);
        if(pendingReward > 0) {
            _claimreward(_tokenid);
        }

        uint256 amount = _stakes[_tokenid].amount;
        // delete records from holder map
        uint[] storage holder = _holderstakes[msg.sender];
        for(uint i = 0; i < holder.length; i++) {
            if(holder[i] == _tokenid) {
                holder[i] = holder[holder.length - 1];
            }
        }
        holder.pop();
        // delete staking record
        delete _stakes[_tokenid];
        TOTAL_STAKE -= amount;
        TOKEN.transfer(msg.sender, amount);
        emit WithdrawStake(msg.sender, _tokenid, amount);
    }

    /**
    * Rescue Token
    */
    function recoveryToken(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(tokenStake), "Cannot recover staked token");
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    function withdrawPayable() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * _stage: halving level (first level must be 0)
     * _lastblock: block number of end stage
     * this function to setup halving schedule
     */
    function setHalving(uint8 _stage, uint256 _lastblock) public onlyOwner {
        uint index = 0; bool bfound = false;
        for(uint i = 0; i < _halvings.length; i++) {
            if(_halvings[i].stage == _stage) {
                bfound = true; index = i;
            }
        }
        if(bfound) {
            _halvings[index].lastblock = _lastblock;
        } else {
            _halvings.push(Halving(_stage, _lastblock));
        }
    }

    /**
     * this function setup claim reward cost (default 0)
     */
    function setCost(uint256 _cost) public onlyOwner() {
        COST = _cost;
    }

    /**
     * this function replace old collector address to new address (default owner)
     */
    function setCollectorAddr(address _address) public onlyOwner {
        COLLECTOR = _address;
    }

    /**
     *  this function will add new balance into staking pool (add not replace)
     */
    function topupPool(uint256 _amount) external onlyOwner {
        require(TOKEN.transferFrom(msg.sender, address(this), _amount), "Can not paid this transaction");
        AVALIABLE_BALANCE += _amount;
        emit TopupPoolStake(_amount);
    }

    /**
     *  this function will replace add block (next claim) when holder do claim reward
     */
    function setClaimSchedule(uint256 _block) public onlyOwner {
        require(_block > 0, "_block can not zero value");
        CLAIM_EVERY = _block;
    }

    /**
     * this function to set reward (no decimal, default 5)
     */
    function setRewardRate(uint8 _percent) public onlyOwner {
        REWARD_RATE = _percent;
    }

    /**
     * this function to set reward (no decimal, default 5)
     */
    function setMinimumStake(uint256 _minimum) public onlyOwner {
        MINIMUM_STAKE = _minimum;
    }

    /**
     * _id: PlanID
     * _title: Plan title
     * _addblock: block add to withdraw stake (1 day = 28800 block)
     * _reward: percent reward block distributed to holder (no decimal)
     * _fee: percent reward block distributed to collector (no decimal)
     * this function will replace plan configuration (if exists) or create new plan (if not exists)
     */
    function setPlan(uint8 _id, string memory _title, uint256 _addblock, uint8 _reward, uint8 _fee) public onlyOwner {
        _plans[_id] = Plans(_id, _title, _addblock, _reward, _fee);
    }

    /**
     * this function will delete existing plan
     */
    function deletePlan(uint8 _id) public onlyOwner {
        delete _plans[_id];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}