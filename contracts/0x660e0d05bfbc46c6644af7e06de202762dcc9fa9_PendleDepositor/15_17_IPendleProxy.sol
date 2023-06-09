// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPendleProxy {
    function isValidMarket(address _market) external view returns (bool);

    function withdraw(address _market, address _to, uint256 _amount) external;

    function claimRewards(
        address _market
    ) external returns (address[] memory, uint256[] memory);

    function claimRewardsManually(
        address _market,
        uint256[] memory _amounts
    ) external returns (address[] memory rewardTokens);

    // --- Events ---
    event BoosterUpdated(address _booster);

    event Withdrawn(address _market, address _to, uint256 _amount);

    event RewardsClaimed(
        address _market,
        address[] _rewardTokens,
        uint256[] _rewardAmounts
    );
}