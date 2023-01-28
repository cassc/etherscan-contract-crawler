// SPDX-License-Identifier: MIT

/// @title Interface for SweepersToken



pragma solidity ^0.8.6;

// import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IERC721Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import { ISweepersDescriptor } from './ISweepersDescriptor.sol';
import { ISweepersSeeder } from './ISweepersSeeder.sol';

interface ISweepersToken is IERC721Upgradeable{
    event SweeperCreated(uint256 indexed tokenId, ISweepersSeeder.Seed seed);

    event SweeperMigrated(uint256 indexed tokenId, ISweepersSeeder.Seed seed);

    event SweeperBurned(uint256 indexed tokenId);

    event SweeperStakedAndLocked(uint256 indexed tokenId, uint256 timestamp);

    event SweeperUnstakedAndUnlocked(uint256 indexed tokenId, uint256 timestamp);

    event SweepersTreasuryUpdated(address sweepersTreasury);

    event MinterUpdated(address minter);

    event MinterLocked();

    event GarageUpdated(address garage);

    event DescriptorUpdated(ISweepersDescriptor descriptor);

    event DescriptorLocked();

    event SeederUpdated(ISweepersSeeder seeder);

    event SeederLocked();

    event SweepersStaked(address indexed staker, uint16[] stakedIDs);
    event SweepersUnstaked(address indexed unstaker, uint16[] stakedIDs);
    event DustClaimed(address indexed claimer, uint256 amount);
    event SweeperRemoved(address indexed sweepOwner, uint16 stakedId, uint256 timestamp);
    event RewardEndSet(uint80 rewardEnd, uint256 timestamp);
    event PenaltyAmountSet(uint256 PenaltyAmount, address PenaltyReceiver, uint256 timestamp);

    struct stakedNFT {
        uint80 lastClaimTimestamp;
        uint256 earningsMultiplier;
    }

    struct unstakeEarnings {
        uint256 earnings;
        uint16 numUnstakedSweepers;
        uint256 penaltyOwed;
    }

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setSweepersTreasury(address sweepersTreasury) external;

    function setMinter(address minter) external;

    // function lockMinter() external;

    function setDescriptor(ISweepersDescriptor descriptor) external;

    // function lockDescriptor() external;

    function setSeeder(ISweepersSeeder seeder) external;

    // function lockSeeder() external;

    // function stakeAndLock(uint256 tokenId) external returns (uint8);

    // function unstakeAndUnlock(uint256 tokenId) external;

    // function isStakedAndLocked(uint256 _id) external view returns (bool);

    // function setGarage(address _garage, bool _flag) external;

    function seeds(uint256 sweeperId) external view returns (uint48, uint48, uint48, uint48, uint48, uint48);

    function setDailyDust(uint256 _dailyDust) external;

    function setDustContract(address _dust) external;

    function setRemover(address _remover, bool _flag) external;

    // function setSingleMultiplier(uint8 _index, uint16 _mult) external;

    function setMultipliers(uint8[] memory _index, uint16[] memory _mult) external;

    function setRewardEnd(uint80 _endTime) external;

    function setPenalty(uint256 _penalty, uint8 _adjuster, address payable _receiver, bool _useCalc) external;

    function setAllowedTimesRemoved(uint16 _limit) external;

    function unblockGarageAccess(address account) external;

    function penaltyCorrection(address account, uint256 _newPenalty) external;

    function stakeAndLock(uint16[] calldata _ids) external;

    function claimDust() external;

    function getUnclaimedDust(address account) external view returns (uint256 owed, uint256[] memory ownedSweepers, uint256[] memory dustPerNFTList, uint256[] memory multipliers, bool[] memory isStaked);

    function isNFTStaked(uint16 _id) external view returns (bool);

    function isNFTStakedBatch(uint16[] calldata _ids) external view returns (bool[] memory isStaked);

    function unstake(uint16[] calldata _ids) external;

    function removeStake(uint16 _id) external;

    function claimWithPenalty() external payable;
}