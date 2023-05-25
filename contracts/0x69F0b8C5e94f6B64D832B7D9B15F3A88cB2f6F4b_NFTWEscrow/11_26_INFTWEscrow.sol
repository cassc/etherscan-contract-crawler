// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INFTWEscrow is IERC165, IERC20, IERC721Receiver {
    event WeightUpdated(address indexed user, bool increase, uint weight, uint timestamp);
    event WorldStaked(uint256 indexed tokenId, address indexed user);
    event WorldUnstaked(uint256 indexed tokenId, address indexed user);

    event RewardsSet(uint32 start, uint32 end, uint256 rate);
    event RewardsUpdated(uint32 start, uint32 end, uint256 rate);
    event RewardsPerWeightUpdated(uint256 accumulated);
    event UserRewardsUpdated(address user, uint256 userRewards, uint256 paidRewardPerWeight);
    event RewardClaimed(address receiver, uint256 claimed);

    struct WorldInfo {
        uint16 weight;          // weight based on rarity
        address owner;          // staked to, otherwise owner == 0
        uint16 deposit;         // unit is ether, paid in WRLD. The deposit is deducted from the last payment(s) since the deposit is non-custodial
        uint16 rentalPerDay;    // unit is ether, paid in WRLD. Total is deposit + rentalPerDay * days
        uint16 minRentDays;     // must rent for at least min rent days, otherwise deposit is forfeited up to this amount
        uint32 rentableUntil;   // timestamp in unix epoch
    }

    struct RewardsPeriod {
        uint32 start;           // reward start time, in unix epoch
        uint32 end;             // reward end time, in unix epoch
    }

    struct RewardsPerWeight {
        uint32 totalWeight;
        uint96 accumulated;
        uint32 lastUpdated;
        uint96 rate;
    }

    struct UserRewards {
        uint32 stakedWeight;
        uint96 accumulated;
        uint96 checkpoint;
    }

    // view functions
    function getWorldInfo(uint tokenId) external view returns(WorldInfo memory);
    function checkUserRewards(address user) external view returns(uint);
    function onERC721Received(address, address, uint256, bytes calldata) external view override returns(bytes4);

    // public functions
    function initialStake(uint[] calldata tokenIds, uint[] calldata weights, address stakeTo, 
        uint16 _deposit, uint16 _rentalPerDay, uint16 _minRentDays, uint32 _rentableUntil, uint32 _maxTimestamp, bytes calldata _signature) 
        external;
    
    function stake(uint[] calldata tokenIds, address stakeTo, 
        uint16 _deposit, uint16 _rentalPerDay, uint16 _minRentDays, uint32 _rentableUntil) 
        external;

    function updateRent(uint[] calldata tokenIds, 
        uint16 _deposit, uint16 _rentalPerDay, uint16 _minRentDays, uint32 _rentableUntil) 
        external;

    function extendRentalPeriod(uint tokenId, uint32 _rentableUntil) external;

    function unstake(uint[] calldata tokenIds, address unstakeTo) external;

    function claim(address to) external;

    
}