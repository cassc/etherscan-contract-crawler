// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../piglet/IPigletz.sol";

interface IStakingManager {

    struct StakedPigletInfo {
        address tokenOwner;
        uint256 periodInSeconds;
        uint256 stakedOnDate;
        uint256 stakedUntilDate;
    }

    event Staked(address indexed owner, uint256 tokenId, uint256 periodInSeconds, uint256 stakedOnDate, uint256 stakedUntilDate);
    event Unstaked(address indexed owner, uint256 tokenId, uint256 periodInSeconds, uint256 stakedOnDate, uint256 unstakedDate);

    function setPeriods(uint256[] calldata periodsInSeconds) external;

    function getPeriods() external returns(uint256[] calldata);

    function stake(uint256 tokenId, uint8 period) external returns (StakedPigletInfo memory info);

    function stakeBatch(uint256[] calldata tokenId, uint8 period) external returns (StakedPigletInfo[] memory info);

    function unstake(uint256 tokenId) external;

    function unstakeBatch(uint256[] memory tokenIds) external;

    function isStakable(uint256 tokenId) external view returns(bool);

    function areStakable(uint256[] calldata tokenIds) external view returns(bool[] memory);

    function isStaked(uint256 tokenId) external view returns (bool);

    function areStaked(uint256[] calldata tokenIds) external view returns (bool[] memory);

    function countPigletzByOwner(address account) external view returns (uint256);

    function listTokenIdsByOwner(address account) external view returns (uint256[] memory tokenIds);

    function listPigletzByOwner(address account) external view returns (StakedPigletInfo[] memory info);

    function getStakeData(uint256 tokenId) external view returns (StakedPigletInfo memory);

    function pigletzByOwner(
        address tokenOwner,
        uint256 start,
        uint256 limit
    ) external view returns (IPigletz.PigletData[] memory);
}