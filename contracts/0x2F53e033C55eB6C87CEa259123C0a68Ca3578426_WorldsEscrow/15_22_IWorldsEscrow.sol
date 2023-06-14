// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IWorldsEscrow is IERC165, IERC721Receiver {
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
    function getWorldInfo(uint _tokenId) external view returns(WorldInfo memory);
    function checkUserRewards(address _user) external view returns(uint);
    function rewardsPeriod() external view returns (IWorldsEscrow.RewardsPeriod memory);
    function rewardsPerWeight() external view returns(RewardsPerWeight memory);
    function rewards(address _user) external view returns (UserRewards memory);
    function userStakedWorlds(address _user) external view returns (uint256[] memory);
    function onERC721Received(address, address, uint256, bytes calldata) external view override returns(bytes4);

    // public functions
    function initialStake(
      uint[] calldata _tokenIds,
      uint[] calldata _weights,
      address _stakeTo,
      uint16 _deposit,
      uint16 _rentalPerDay,
      uint16 _minRentDays,
      uint32 _rentableUntil,
      uint32 _maxTimestamp,
      bytes calldata _signature
    ) external;

    function stake(
      uint[] calldata _tokenIds,
      address _stakeTo,
      uint16 _deposit,
      uint16 _rentalPerDay,
      uint16 _minRentDays,
      uint32 _rentableUntil
    ) external;

    function updateRent(
      uint[] calldata _tokenIds,
      uint16 _deposit,
      uint16 _rentalPerDay,
      uint16 _minRentDays,
      uint32 _rentableUntil
    ) external;

    function extendRentalPeriod(uint _tokenId, uint32 _rentableUntil) external;
    function unstake(uint[] calldata _tokenIds, address unstakeTo) external;
    function claim(address _to) external;
}