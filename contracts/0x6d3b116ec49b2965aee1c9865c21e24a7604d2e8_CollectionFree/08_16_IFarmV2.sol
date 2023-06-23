pragma solidity ^0.8.7;

interface IFarmV2 {
    function giveAway(address _address, uint256 stones) external;

    function sell(
        uint256 stones,
        address from,
        address to
    ) external;

    function rewardedStones(address staker) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function farmed(address sender) external view returns (uint256);

    function payment(address buyer, uint256 amount) external returns (bool);
}