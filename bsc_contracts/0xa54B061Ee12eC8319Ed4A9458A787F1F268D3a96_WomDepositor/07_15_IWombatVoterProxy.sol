// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWombatVoterProxy {
    function getLpToken(uint256) external view returns (address);

    function getBonusTokens(uint256) external view returns (address[] memory);

    function deposit(uint256, uint256) external;

    function withdraw(uint256, uint256) external;

    function withdrawAll(uint256) external;

    function claimRewards(uint256) external;

    function balanceOfPool(uint256) external view returns (uint256);

    function lockWom(uint256) external;

    // --- Events ---
    event BoosterUpdated(address _booster);
    event DepositorUpdated(address _depositor);

    event Deposited(uint256 _pid, uint256 _amount);

    event Withdrawn(uint256 _pid, uint256 _amount);

    event RewardsClaimed(uint256 _pid, uint256 _amount);

    event BonusRewardsClaimed(
        uint256 _pid,
        address _bonusTokenAddress,
        uint256 _bonusTokenAmount
    );

    event WomLocked(uint256 _amount, uint256 _lockDays);
    event WomUnlocked(uint256 _slot);
}