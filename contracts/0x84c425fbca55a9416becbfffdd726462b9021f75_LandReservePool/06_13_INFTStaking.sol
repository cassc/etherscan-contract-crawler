// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INFTStaking is IERC165, IERC721Receiver {
    event Staked(uint256 indexed tokenId, address indexed user);
    event Unstaked(uint256 indexed tokenId, address indexed user);

    struct StakeInformation {
        address owner; // staked to, otherwise owner == 0
        uint256 deposit; // unit is ether, paid in NRGY. The deposit is deducted from the last payment(s) since the deposit is non-custodial
        uint256 rentalPerDay; // unit is ether, paid in NRGY. Total is deposit + rentalPerDay * days
        uint16 minRentDays; // must rent for at least min rent days, otherwise deposit is forfeited up to this amount
        uint32 rentableUntil; // timestamp in unix epoch
        uint32 stakedFrom; // staked from timestamp
        uint32 lockUntil; // lock staking
        bool enableRenting; // enable/disable renting
    }

    function getOriginalOwner(uint256 _tokenId) external view returns (address);

    // view functions

    function getNFTAddress() external view returns (address);

    function getRentalContractAddress() external view returns (address);

    function getStakeInformation(uint256 _tokenId)
        external
        view
        returns (StakeInformation memory);

    function getStakingDuration(uint256 _tokenId)
        external
        view
        returns (uint256);

    function isStakeActive(uint256 _tokenId) external view returns (bool);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view override returns (bytes4);

    function stake(
        uint256[] calldata _tokenIds,
        address _stakeTo,
        uint256 _deposit,
        uint256 _rentalPerDay,
        uint16 _minRentDays,
        uint32 _rentableUntil,
        bool _enableRent
    ) external;

    function updateRent(
        uint256[] calldata _tokenIds,
        uint256 _deposit,
        uint256 _rentalPerDay,
        uint16 _minRentDays,
        uint32 _rentableUntil,
        bool _enableRent
    ) external;

    function extendRentalPeriod(uint256 _tokenId, uint32 _rentableUntil)
        external;

    function unstake(uint256[] calldata _tokenIds, address _unstakeTo) external;
}