// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDust.sol";
import "./interfaces/ISweepersToken.sol";
import "./interfaces/IGarage.sol";

contract Garage is Ownable, ReentrancyGuard {

    IDust private DustInterface;
    ISweepersToken private SweepersInterface;
    IGarage private oldGarage;
    uint256 public dailyDust;
    uint80 private minimumStakeTime; // unix timestamp in seconds
    uint80 private rewardEnd;
    uint16 public sweepersInGarage;

    mapping(uint16 => bool) public StakedAndLocked; // whether or not NFT ID is staked
    mapping(uint16 => stakedNFT) public StakedNFTInfo; // tok ID to struct
    mapping(uint8 => uint16) public multiplier;

    mapping(address => bool) public remover; // address which will call to unstake if NFT is listed on OpenSea while staked
    address payable public PenaltyReceiver;
    mapping(address => unstakeEarnings) public penaltyEarnings;
    mapping(address => uint16) public timesRemoved;
    mapping(address => bool) public blockedFromGarage;
    uint256 public allowedTimesRemoved;
    uint256 public penalty;
    uint8 public penaltyAdjuster;
    bool public useCalculatedPenalty;

    struct stakedNFT {
        uint80 stakedTimestamp;
        uint80 lastClaimTimestamp;
        uint8 NFTMultiplier;
    }

    struct unstakeEarnings {
        uint256 earnings;
        uint16 numUnstakedSweepers;
        uint256 penaltyOwed;
    }

    modifier onlyRemover() {
        require(remover[msg.sender], "Not a Remover");
        _;
    }

     // @param minStakeTime is block timestamp in seconds
    constructor(uint80 _minStakeTime, address _dust, address _sweepers, address _oldGarage) {
        minimumStakeTime = _minStakeTime;
        dailyDust = 10*10**18;
        DustInterface = IDust(_dust);
        SweepersInterface = ISweepersToken(_sweepers);
        oldGarage = IGarage(_oldGarage);
        penaltyAdjuster = 110;
        useCalculatedPenalty = true;

        multiplier[0] = 15000;
        multiplier[1] = 10000;
        multiplier[2] = 10000;
        multiplier[3] = 35000;
        multiplier[4] = 20000;
        multiplier[5] = 10000;
        multiplier[6] = 10000;
        multiplier[7] = 10000;
        multiplier[8] = 10000;
        multiplier[9] = 10000;
        multiplier[10] = 10000;
        multiplier[11] = 25000;
        multiplier[12] = 10000;
        multiplier[13] = 10000;
        multiplier[14] = 20000;
        multiplier[15] = 10000;
        multiplier[16] = 20000;
        multiplier[17] = 10000;
        multiplier[21] = 15000;
        multiplier[22] = 20000;
        multiplier[23] = 20000;
    }

    event SweepersStaked(address indexed staker, uint16[] stakedIDs);
    event SweepersUnstaked(address indexed unstaker, uint16[] stakedIDs);
    event DustClaimed(address indexed claimer, uint256 amount);
    event SweeperRemoved(address indexed sweepOwner, uint16 stakedId, uint256 timestamp);
    event RewardEndSet(uint80 rewardEnd, uint256 timestamp);
    event PenaltyAmountSet(uint256 PenaltyAmount, address PenaltyReceiver, uint256 timestamp);

    function setDailyDust(uint256 _dailyDust) external onlyOwner {
        dailyDust = _dailyDust;
    }

    function setDustContract(address _dust) external onlyOwner {
        DustInterface = IDust(_dust);
    }

    function setSweepersContract(address _sweepers) external onlyOwner {
        SweepersInterface = ISweepersToken(_sweepers);
    }

    function setRemover(address _remover, bool _flag) external onlyOwner {
        remover[_remover] = _flag;
    }

    function setMinimumStakeTime(uint80 _minStakeTime) external onlyOwner {
        minimumStakeTime = _minStakeTime;
    }

    function setSingleMultiplier(uint8 _index, uint16 _mult) external onlyOwner {
        multiplier[_index] = _mult;
    }

    function setRewardEnd(uint80 _endTime) external onlyOwner {
        rewardEnd = _endTime;
        emit RewardEndSet(_endTime, block.timestamp);
    }

    function setPenalty(uint256 _penalty, uint8 _adjuster, address payable _receiver, bool _useCalc) external onlyOwner {
        penalty = _penalty;
        penaltyAdjuster = _adjuster;
        PenaltyReceiver = _receiver;
        useCalculatedPenalty = _useCalc;
        emit PenaltyAmountSet(_penalty, _receiver, block.timestamp);
    }

    function setAllowedTimesRemoved(uint16 _limit) external onlyOwner {
        allowedTimesRemoved = _limit;
    }

    function unblockGarageAccess(address account) external onlyOwner {
        blockedFromGarage[account] = false;
    }

    function penaltyCorrection(address account, uint256 _newPenalty) external onlyOwner {
        require(_newPenalty < penaltyEarnings[account].penaltyOwed, "Can not increase penalty");
        penaltyEarnings[account].penaltyOwed = _newPenalty;
    }

    function stakeAndLock(uint16[] calldata _ids) external nonReentrant {
        require(!blockedFromGarage[msg.sender], "Please claim penalty rewards first");
        uint16 length = uint16(_ids.length);
        for (uint16 i = 0; i < length; i++) {
            require(!StakedAndLocked[_ids[i]] || !SweepersInterface.isStakedAndLocked(_ids[i]), 
            "Already Staked");
            require(msg.sender == SweepersInterface.ownerOf(_ids[i]), "Not owner of Sweeper");
            StakedAndLocked[_ids[i]] = true;
            StakedNFTInfo[_ids[i]].stakedTimestamp = uint80(block.timestamp);
            StakedNFTInfo[_ids[i]].lastClaimTimestamp = uint80(block.timestamp);
            StakedNFTInfo[_ids[i]].NFTMultiplier = SweepersInterface.stakeAndLock(_ids[i]);
        }
        sweepersInGarage += length;
        emit SweepersStaked(msg.sender, _ids);
    }

    function claimDust(uint16[] calldata _ids) external nonReentrant {
        uint16 length = uint16(_ids.length);
        uint256 owed;
        for (uint16 i = 0; i < length; i++) {
            require((StakedAndLocked[_ids[i]] || SweepersInterface.isStakedAndLocked(_ids[i])) && StakedNFTInfo[_ids[i]].lastClaimTimestamp > 0, 
            "NFT is not staked");
            require(msg.sender == SweepersInterface.ownerOf(_ids[i]), "Not owner of Sweeper");
            if(rewardEnd > 0 && block.timestamp > rewardEnd) {
                owed += ((((rewardEnd - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[StakedNFTInfo[_ids[i]].NFTMultiplier]) / 10000;
                StakedNFTInfo[_ids[i]].lastClaimTimestamp = rewardEnd;
            } else {
                owed += ((((block.timestamp - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[StakedNFTInfo[_ids[i]].NFTMultiplier]) / 10000;
                StakedNFTInfo[_ids[i]].lastClaimTimestamp = uint80(block.timestamp);
            }
            if(!StakedAndLocked[_ids[i]]) {
                StakedAndLocked[_ids[i]] = true;
            }
        }
        DustInterface.mint(msg.sender, owed);
        emit DustClaimed(msg.sender, owed);
    }

    function getUnclaimedDust(uint16[] calldata _ids) external view returns (uint256 owed, uint256[] memory dustPerNFTList) {
        uint16 length = uint16(_ids.length);
        uint256 tokenDustValue; // amount owed for each individual token in the calldata array
        dustPerNFTList = new uint256[](length); 
        for (uint16 i = 0; i < length; i++) {
            if((StakedAndLocked[_ids[i]] || SweepersInterface.isStakedAndLocked(_ids[i])) && StakedNFTInfo[_ids[i]].lastClaimTimestamp > 0) {
                if(rewardEnd > 0 && block.timestamp > rewardEnd) {
                    tokenDustValue = ((((rewardEnd - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[StakedNFTInfo[_ids[i]].NFTMultiplier]) / 10000;
                } else {
                    tokenDustValue = ((((block.timestamp - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[StakedNFTInfo[_ids[i]].NFTMultiplier]) / 10000;
                }
            }

            owed += tokenDustValue;

            dustPerNFTList[i] = tokenDustValue;
        }
        return (owed, dustPerNFTList);
    }

    function isNFTStaked(uint16 _id) public view returns (bool) {
        if(StakedAndLocked[_id] || SweepersInterface.isStakedAndLocked(_id)) {
            return true;
        } else {
            return false;
        }
    }

    function isNFTStakedBatch(uint16[] calldata _ids) external view returns (bool[] memory isStaked) {
        uint length = _ids.length;
        isStaked = new bool[](length);
        for(uint i = 0; i < length; i++) {
            isStaked[i] = isNFTStaked(_ids[i]);
        }
    }

    function unstake(uint16[] calldata _ids) external nonReentrant {
        uint16 length = uint16(_ids.length);
        uint256 owed;
        for (uint16 i = 0; i < length; i++) {
            require((StakedAndLocked[_ids[i]] || SweepersInterface.isStakedAndLocked(_ids[i])) && StakedNFTInfo[_ids[i]].lastClaimTimestamp > 0, 
            "NFT is not staked");
            require(msg.sender == SweepersInterface.ownerOf(_ids[i]), "Not owner of Sweeper");
            require(block.timestamp - StakedNFTInfo[_ids[i]].stakedTimestamp >= minimumStakeTime, 
            "Must wait min stake time");

            if(rewardEnd > 0 && block.timestamp > rewardEnd) {
                owed += ((((rewardEnd - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[StakedNFTInfo[_ids[i]].NFTMultiplier]) / 10000;
            } else {
                owed += ((((block.timestamp - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[StakedNFTInfo[_ids[i]].NFTMultiplier]) / 10000;
            }

            SweepersInterface.unstakeAndUnlock(_ids[i]);
            delete StakedNFTInfo[_ids[i]];
            StakedAndLocked[_ids[i]] = false;
        }
        sweepersInGarage -= length;
        DustInterface.mint(msg.sender, owed);
        emit DustClaimed(msg.sender, owed);
        emit SweepersUnstaked(msg.sender, _ids);
    }

    function removeStake(uint16 _id) external onlyRemover {
        uint256 gasForTX = gasleft();
        require(StakedAndLocked[_id] || SweepersInterface.isStakedAndLocked(_id), "NFT is not staked");
        address sweepOwner = SweepersInterface.ownerOf(_id);
        if(rewardEnd > 0 && block.timestamp > rewardEnd) {
            penaltyEarnings[sweepOwner].earnings += ((((rewardEnd - StakedNFTInfo[_id].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[StakedNFTInfo[_id].NFTMultiplier]) / 10000;
        } else {
            penaltyEarnings[sweepOwner].earnings += ((((block.timestamp - StakedNFTInfo[_id].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[StakedNFTInfo[_id].NFTMultiplier]) / 10000;
        }
        penaltyEarnings[sweepOwner].numUnstakedSweepers++;
        SweepersInterface.unstakeAndUnlock(_id);
        delete StakedNFTInfo[_id];
        StakedAndLocked[_id] = false;
        timesRemoved[sweepOwner]++;
        if(penaltyEarnings[sweepOwner].numUnstakedSweepers > allowedTimesRemoved) {
            blockedFromGarage[sweepOwner] = true;
        }

        uint16[] memory _ids = new uint16[](1); 
        _ids[0] = _id;

        sweepersInGarage--;

        emit SweepersUnstaked(sweepOwner, _ids);
        emit SweeperRemoved(sweepOwner, _id, block.timestamp);

        penaltyEarnings[sweepOwner].penaltyOwed += ((gasForTX - gasleft()) * tx.gasprice * penaltyAdjuster) / 100 ;
    }

    function batchCheckStatus(uint16[] calldata _ids) external view returns (bool[] memory isStaked) {
        uint length = _ids.length;
        isStaked = new bool[](length);
        for(uint i = 0; i < length; i++) {
            isStaked[i] = (StakedAndLocked[_ids[i]] || SweepersInterface.isStakedAndLocked(_ids[i]));
        }
    }

    function claimWithPenalty() external payable {
        if(useCalculatedPenalty) {
            require(msg.value == penaltyEarnings[msg.sender].penaltyOwed, "Value must equal penalty amount");
        } else {
            require(msg.value == penaltyEarnings[msg.sender].numUnstakedSweepers * penalty, "Value must equal penalty amount");
        }
        uint256 owed = penaltyEarnings[msg.sender].earnings;
        DustInterface.mint(msg.sender, owed);
        (bool sent,) = PenaltyReceiver.call{value: msg.value}("");
        require(sent);
        blockedFromGarage[msg.sender] = false;
        delete penaltyEarnings[msg.sender];
        emit DustClaimed(msg.sender, owed);
    }

    function getUnclaimedDustPenalty(address account) external view returns (uint256 unclaimed, uint256 _penalty) {
        unclaimed = penaltyEarnings[account].earnings;
        if(useCalculatedPenalty) {
            _penalty = penaltyEarnings[account].penaltyOwed;
        } else {
            _penalty = penaltyEarnings[account].numUnstakedSweepers * penalty;
        }
    }

    function migrateGarage(uint256 start, uint256 end) external onlyOwner {
        uint80 _stakedTimestamp;
        uint80 _lastClaimTimestamp; 
        uint16 _staked = sweepersInGarage;
        for(uint i = start; i <= end;) {
            if(oldGarage.StakedAndLocked(uint16(i)) && StakedNFTInfo[uint16(i)].stakedTimestamp == 0) {
                (, _stakedTimestamp, _lastClaimTimestamp) = oldGarage.StakedNFTInfo(uint16(i));
                StakedNFTInfo[uint16(i)].stakedTimestamp = _stakedTimestamp;
                StakedNFTInfo[uint16(i)].lastClaimTimestamp = _lastClaimTimestamp;
                StakedNFTInfo[uint16(i)].NFTMultiplier = oldGarage.NFTMultiplier(uint16(i));
                _staked++;
                unchecked{i++;}
            } else {
                unchecked{i++;}
                continue;
            }
        }
        sweepersInGarage = _staked;
    }
}