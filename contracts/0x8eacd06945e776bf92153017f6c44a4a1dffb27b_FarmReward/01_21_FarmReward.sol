// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/security/Pausable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import "../damoNft/IFactory.sol";

import "./interfaces/IAppConf.sol";
import "./interfaces/IFarmStaking.sol";
import "./interfaces/IFarmReward.sol";

import "../libs/Initializable.sol";
import "../libs/Permission.sol";

import "./Model.sol";

contract FarmReward is IFarmReward, Initializable, Pausable, ReentrancyGuard, Ownable {
     using EnumerableSet for EnumerableSet.UintSet;

    // useraddr -> stakingindex -> nftotken -> nfttype -> gen -> tokenids -> blocktime
    event Claim(address indexed, uint256, address, uint8, uint8, uint256[], uint256);

    event Initialized(address indexed);

    // useraddr -> stakingindex -> Checkpoint
    mapping(address => mapping(uint256 => Model.Checkpoint[])) private checkpointMap;

    // useraddr -> tokenid -> claimedamount
    mapping(address => mapping(uint256 => uint256)) claimedAmountMap;

    IAppConf appConf;

    modifier onlyFarm {
        require(appConf.validFarm(_msgSender()), "FarmReward: call forbidden, invalid farm");
        _;
    }

    function initialize(IAppConf _appConf) external onlyOwner {
        appConf = _appConf;

        initialized = true;
        emit Initialized(address(appConf));
    }

    function _claimAll(address userAddr) private {
        require(!appConf.validBlacklist(userAddr), "FarmReward: can not claim");

        IFarmStaking farmStaking = IFarmStaking(appConf.getFarmAddr().farmStakingAddr);

        Model.StakingRecord[] memory stakingRecords = farmStaking.getStakingRecords(userAddr);
        uint256[] memory stakingIndexs = farmStaking.getStakingIndexs(userAddr);

        for (uint256 index = 0; index < stakingIndexs.length; index++) {
            _claim(userAddr, stakingRecords[stakingIndexs[index]]);
        }
    }

    function claimAll() external needInit whenNotPaused nonReentrant {
        _claimAll(_msgSender());
    }

    function claim(uint256 stakingIndex) external needInit whenNotPaused nonReentrant {
        require(!appConf.validBlacklist(_msgSender()), "FarmReward: can not claim");

        // staking record
        IFarmStaking farmStaking = IFarmStaking(appConf.getFarmAddr().farmStakingAddr);
        Model.StakingRecord[] memory stakingRecords = farmStaking.getStakingRecords(_msgSender());
        require(stakingRecords.length > stakingIndex, "FarmReward: index out of range");

        _claim(_msgSender(), stakingRecords[stakingIndex]);
    }

    function proxyClaim(address userAddr, uint256 stakingIndex) external needInit onlyFarm whenNotPaused nonReentrant {
        require(appConf.getEnabledProxyClaim(), "FarmReward: can not proxy claim");

        // staking record
        IFarmStaking farmStaking = IFarmStaking(appConf.getFarmAddr().farmStakingAddr);
        Model.StakingRecord[] memory stakingRecords = farmStaking.getStakingRecords(userAddr);
        require(stakingRecords.length > stakingIndex, "FarmReward: index out of range");

        _claim(userAddr, stakingRecords[stakingIndex]);
    }

    function _claim(address userAddr, Model.StakingRecord memory stakingRecord) private {
        require(stakingRecord.status == Model.STAKING_STATUS_STAKED, "FarmReward: invalid staking status");
        require(stakingRecord.userAddr == userAddr, "FarmReward: invalid claim user addr");

        address rewardNftToken = appConf.getRewardNftToken();
        uint8 rewardNftTokenGen = appConf.getRewardNftTokenGen();

        // calc rewardAmount
        uint256 rewardAmount = _calcStakingRewardAmount(userAddr, stakingRecord);
        if (rewardAmount == 0) {
            return;
        }

        // save checkpoint
        checkpointMap[userAddr][stakingRecord.index].push(Model.Checkpoint({
            blockNumber: block.number,
            timestamp: block.timestamp
        }));

        // mint nft reward
        uint8 rewardNftType = appConf.getNftTokenType(rewardNftToken);
        uint256[] memory rewardTokenIds = IFactory(appConf.getNftFactoryAddr()).mintDamo(
            userAddr, 
            rewardNftType, 
            appConf.getRewardNftTokenGen(), 
            uint8(rewardAmount),
            Model.SourceTypeReward
        );

        // stat reward amount
        uint256 rewardAmountPerNft = rewardAmount / stakingRecord.tokenIds.length;
        for (uint256 index = 0; index < stakingRecord.tokenIds.length; index++) {
            claimedAmountMap[userAddr][stakingRecord.tokenIds[index]] += rewardAmountPerNft;
        }

        emit Claim(userAddr, stakingRecord.index, rewardNftToken, rewardNftType, rewardNftTokenGen, rewardTokenIds, block.timestamp);
    }

    function _calcStakingRewardAmount(address userAddr, Model.StakingRecord memory stakingRecord) private view returns(uint256) {
        if (stakingRecord.status == Model.STAKING_STATUS_UNSTAKED) {
            return 0;
        }

        uint256 startTime = stakingRecord.stakingTime;

        Model.Checkpoint[] storage checkpoints = checkpointMap[userAddr][stakingRecord.index];
        if (checkpoints.length > 0) {
            startTime = checkpoints[checkpoints.length - 1].timestamp;
        }

        // calc reward
        uint256 rewardAmount = 0;
        uint256 elapsedTime = block.timestamp - startTime;
        uint256 nftCount = stakingRecord.tokenIds.length;

        // reward type
        uint8 rewardType = appConf.getRewardType();
        if (rewardType == Model.REWARD_TYPE_FIXED) {
            if (elapsedTime > appConf.getRewardPeriod(stakingRecord.gen)) {
                rewardAmount = nftCount * appConf.getRewardAmount(stakingRecord.gen);
            }
        } else {
            uint256 multiple = elapsedTime / appConf.getRewardPeriod(stakingRecord.gen);
            rewardAmount = nftCount * (multiple * appConf.getRewardAmount(stakingRecord.gen));
        }

        return rewardAmount;
    }

    function calcRewardAmount(address userAddr) external view override needInit returns(uint256) {
        IFarmStaking farmStaking = IFarmStaking(appConf.getFarmAddr().farmStakingAddr);
        uint256[] memory stakingIndexs = farmStaking.getStakingIndexs(userAddr);

        uint256 totalRewardAmount = 0;

        for (uint256 index = 0; index < stakingIndexs.length; index++) {
            totalRewardAmount += _calcRewardAmount(userAddr, stakingIndexs[index]);
        }

        return totalRewardAmount;
    }

    function calcRewardAmount(address userAddr, uint256 stakingIndex) external view override needInit returns(uint256) {
        return _calcRewardAmount(userAddr, stakingIndex);
    }

    function _calcRewardAmount(address userAddr, uint256 stakingIndex) private view returns(uint256) {
        IFarmStaking farmStaking = IFarmStaking(appConf.getFarmAddr().farmStakingAddr);
        Model.StakingRecord[] memory stakingRecords = farmStaking.getStakingRecords(userAddr);
        require(stakingRecords.length > stakingIndex, "index out of range");

        uint256 rewardAmount = _calcStakingRewardAmount(userAddr, stakingRecords[stakingIndex]);
        return rewardAmount;
    }
    
    function getCheckpoints(address userAddr, uint256 stakingIndex) external view returns(Model.Checkpoint[] memory) {
        return checkpointMap[userAddr][stakingIndex];
    }

    function getClaimedAmount(address userAddr, uint256 tokenId) external view returns(uint256) {
        return claimedAmountMap[userAddr][tokenId];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}