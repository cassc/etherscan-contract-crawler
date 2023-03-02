// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

/**
 * @dev Interface of the MasterWombat
 */
interface IMasterWombat {
    function getAssetPid(address asset) external view returns (uint256 pid);

    function poolLength() external view returns (uint256);

    function pendingTokens(
        uint256 _pid,
        address _user
    )
        external
        view
        returns (
            uint256 pendingRewards,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function rewarderBonusTokenInfo(
        uint256 _pid
    ) external view returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function multiClaim(
        uint256[] memory _pids
    ) external returns (uint256 transfered, uint256[] memory rewards, uint256[] memory additionalRewards);

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(uint256 _pid, uint256 _amount, address _user) external;

    function updateFactor(address _user, uint256 _newVeWomBalance) external;
}