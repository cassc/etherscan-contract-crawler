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

    mapping(uint16 => bool) public StakedAndLocked; // whether or not NFT ID is staked
    mapping(uint16 => stakedNFT) public StakedNFTInfo; // tok ID to struct
    mapping(uint16 => uint8) public NFTMultiplier;
    mapping(uint8 => uint16) public multiplier;

    mapping(address => bool) public remover; // address which will call to unstake if NFT is listed on OpenSea while staked
    address payable public PenaltyReceiver;
    mapping(address => unstakeEarnings) public penaltyEarnings;
    mapping(address => uint16) public timesRemoved;
    mapping(address => bool) public blockedFromGarage;
    uint256 public allowedTimesRemoved;
    uint256 public penalty;

    struct stakedNFT {
        uint16 id;
        uint80 stakedTimestamp;
        uint80 lastClaimTimestamp;
    }

    struct unstakeEarnings {
        uint256 earnings;
        uint16 numUnstakedSweepers;
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

    function setPenalty(uint256 _penalty, address payable _receiver) external onlyOwner {
        penalty = _penalty;
        PenaltyReceiver = _receiver;
        emit PenaltyAmountSet(_penalty, _receiver, block.timestamp);
    }

    function setAllowedTimesRemoved(uint16 _limit) external onlyOwner {
        allowedTimesRemoved = _limit;
    }

    function unblockGarageAccess(address account) external onlyOwner {
        blockedFromGarage[account] = false;
    }

    function stakeAndLock(uint16[] calldata _ids) external nonReentrant {
        require(!blockedFromGarage[msg.sender], "Please claim penalty rewards first");
        uint16 length = uint16(_ids.length);
        for (uint16 i = 0; i < length; i++) {
            require(!StakedAndLocked[_ids[i]], 
            "Already Staked");
            require(msg.sender == SweepersInterface.ownerOf(_ids[i]), "Not owner of Sweeper");
            StakedAndLocked[_ids[i]] = true;
            StakedNFTInfo[_ids[i]].id = _ids[i];
            StakedNFTInfo[_ids[i]].stakedTimestamp = uint80(block.timestamp);
            StakedNFTInfo[_ids[i]].lastClaimTimestamp = uint80(block.timestamp);
            NFTMultiplier[_ids[i]] = SweepersInterface.stakeAndLock(_ids[i]);
        }
        emit SweepersStaked(msg.sender, _ids);
    }

    function claimDust(uint16[] calldata _ids) external nonReentrant {
        uint16 length = uint16(_ids.length);
        uint256 owed;
        for (uint16 i = 0; i < length; i++) {
            require(StakedAndLocked[_ids[i]], 
            "NFT is not staked");
            require(msg.sender == SweepersInterface.ownerOf(_ids[i]), "Not owner of Sweeper");
            if(rewardEnd > 0 && block.timestamp > rewardEnd) {
                owed += ((((rewardEnd - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[NFTMultiplier[_ids[i]]]) / 10000;
                StakedNFTInfo[_ids[i]].lastClaimTimestamp = rewardEnd;
            } else {
                owed += ((((block.timestamp - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[NFTMultiplier[_ids[i]]]) / 10000;
                StakedNFTInfo[_ids[i]].lastClaimTimestamp = uint80(block.timestamp);
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
            require(StakedAndLocked[_ids[i]], 
            "NFT is not staked");

            if(rewardEnd > 0 && block.timestamp > rewardEnd) {
                tokenDustValue = ((((rewardEnd - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[NFTMultiplier[_ids[i]]]) / 10000;
            } else {
                tokenDustValue = ((((block.timestamp - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[NFTMultiplier[_ids[i]]]) / 10000;
            }

            owed += tokenDustValue;

            dustPerNFTList[i] = tokenDustValue;
        }
        return (owed, dustPerNFTList);
    }

    function isNFTStaked(uint16 _id) external view returns (bool) {
        return StakedAndLocked[_id];
    }

    function unstake(uint16[] calldata _ids) external nonReentrant {
        uint16 length = uint16(_ids.length);
        uint256 owed;
        for (uint16 i = 0; i < length; i++) {
            require(StakedAndLocked[_ids[i]], 
            "NFT is not staked");
            require(msg.sender == SweepersInterface.ownerOf(_ids[i]), "Not owner of Sweeper");
            require(block.timestamp - StakedNFTInfo[_ids[i]].stakedTimestamp >= minimumStakeTime, 
            "Must wait min stake time");
            owed += ((((block.timestamp - StakedNFTInfo[_ids[i]].lastClaimTimestamp) * dailyDust) 
            / 86400) * multiplier[NFTMultiplier[_ids[i]]]) / 10000;
            SweepersInterface.unstakeAndUnlock(_ids[i]);
            delete StakedNFTInfo[_ids[i]];
            StakedAndLocked[_ids[i]] = false;
        }
        DustInterface.mint(msg.sender, owed);
        emit DustClaimed(msg.sender, owed);
        emit SweepersUnstaked(msg.sender, _ids);
    }

    // function removeStake(uint16 _id) external onlyRemover {
    //     require(StakedAndLocked[_id], "NFT is not staked");
    //     address sweepOwner = SweepersInterface.ownerOf(_id);
    //     uint256 owed = ((((block.timestamp - StakedNFTInfo[_id].lastClaimTimestamp) * dailyDust) 
    //     / 86400) * multiplier[NFTMultiplier[_id]]) / 10000;
    //     SweepersInterface.unstakeAndUnlock(_id);
    //     delete StakedNFTInfo[_id];
    //     StakedAndLocked[_id] = false;
    //     DustInterface.mint(sweepOwner, owed);
    //     uint16[] memory _ids = new uint16[](1); 
    //     _ids[0] = _id;
    //     emit DustClaimed(sweepOwner, owed);
    //     emit SweepersUnstaked(sweepOwner, _ids);
    //     emit SweeperRemoved(sweepOwner, _id, block.timestamp);
    // }

    function removeStake(uint16 _id) external onlyRemover {
        require(StakedAndLocked[_id], "NFT is not staked");
        address sweepOwner = SweepersInterface.ownerOf(_id);
        if(rewardEnd > 0 && block.timestamp > rewardEnd) {
            penaltyEarnings[msg.sender].earnings += ((((rewardEnd - StakedNFTInfo[_id].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[NFTMultiplier[_id]]) / 10000;
        } else {
            penaltyEarnings[msg.sender].earnings += ((((block.timestamp - StakedNFTInfo[_id].lastClaimTimestamp) * dailyDust) / 86400) * multiplier[NFTMultiplier[_id]]) / 10000;
        }
        penaltyEarnings[msg.sender].numUnstakedSweepers++;
        SweepersInterface.unstakeAndUnlock(_id);
        delete StakedNFTInfo[_id];
        StakedAndLocked[_id] = false;
        timesRemoved[sweepOwner]++;
        if(timesRemoved[sweepOwner] >= allowedTimesRemoved) {
            blockedFromGarage[sweepOwner] = true;
        }

        uint16[] memory _ids = new uint16[](1); 
        _ids[0] = _id;

        emit SweepersUnstaked(sweepOwner, _ids);
        emit SweeperRemoved(sweepOwner, _id, block.timestamp);
    }

    function claimWithPenalty() external payable {
        require(msg.value == penaltyEarnings[msg.sender].numUnstakedSweepers * penalty, "Value must equal penalty amount");
        uint256 owed = penaltyEarnings[msg.sender].earnings;
        DustInterface.mint(msg.sender, owed);
        (bool sent,) = PenaltyReceiver.call{value: msg.value}("");
        require(sent);
        blockedFromGarage[msg.sender] = false;
        emit DustClaimed(msg.sender, owed);
    }

    function getUnclaimedDustPenalty(address account) external view returns (uint256 unclaimed, uint16 penaltyMultiplier) {
        unclaimed = penaltyEarnings[account].earnings;
        penaltyMultiplier = penaltyEarnings[account].numUnstakedSweepers;
    } 

    function migrateGarage(uint16 start, uint16 end) external onlyOwner {
        uint16 _id;
        uint80 _stakedTimestamp;
        uint80 _lastClaimTimestamp; 
        for(uint16 i = start; i <= end; i++) {
            if(oldGarage.StakedAndLocked(i)) {
                (_id, _stakedTimestamp, _lastClaimTimestamp) = oldGarage.StakedNFTInfo(i);
                stakedNFT memory s = stakedNFT({
                    id : _id,
                    stakedTimestamp : _stakedTimestamp,
                    lastClaimTimestamp : _lastClaimTimestamp
                });
                StakedNFTInfo[i] = s;
            } else {
                continue;
            }
        }
    }
}