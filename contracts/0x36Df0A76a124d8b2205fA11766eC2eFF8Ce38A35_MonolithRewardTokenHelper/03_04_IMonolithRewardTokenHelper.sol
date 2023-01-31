pragma solidity >=0.5.0;

interface IMonolithRewardTokenHelper {

    function rewardTokenListLength() external view returns (uint256);

    function rewardTokenListItem(uint256 index) external view returns (address);

    function isRewardTokenEnabled(address rewardToken) external view returns (bool);

    function addRewardToken(address rewardToken) external;

    function removeRewardToken(address rewardToken) external;
}