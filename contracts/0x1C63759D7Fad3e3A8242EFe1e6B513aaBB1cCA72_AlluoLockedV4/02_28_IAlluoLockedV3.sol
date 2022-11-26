// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAlluoLockedV3 {
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function UPGRADER_ROLE() external view returns (bytes32);

    function _lockers(address)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardAllowed,
            uint256 rewardDebt,
            uint256 distributed,
            uint256 unlockAmount,
            uint256 depositUnlockTime,
            uint256 withdrawUnlockTime
        );

    function addReward(uint256 _amount) external;

    function alluoBalancerLp() external view returns (address);

    function alluoToken() external view returns (address);

    function balanceOf(address _address) external view returns (uint256 amount);

    function balancer() external view returns (address);

    function changeUpgradeStatus(bool _status) external;

    function claim() external;

    function convertAlluoToLp(uint256 _amount) external view returns (uint256);

    function convertLpToAlluo(uint256 _amount) external view returns (uint256);

    function decimals() external view returns (uint8);

    function depositLockDuration() external view returns (uint256);

    function distributionTime() external view returns (uint256);

    function exchange() external view returns (address);

    function getClaim(address _locker) external view returns (uint256 reward);

    function getInfoByAddress(address _address)
        external
        view
        returns (
            uint256 locked_,
            uint256 unlockAmount_,
            uint256 claim_,
            uint256 depositUnlockTime_,
            uint256 withdrawUnlockTime_
        );

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function initialize(address _multiSigWallet, uint256 _rewardPerDistribution)
        external;

    function lock(uint256 _amount) external;

    function lockWETH(uint256 _amount) external;

    function migrationLock(address[] memory _users, uint256[] memory _amounts)
        external;

    function name() external view returns (string memory);

    function pause() external;

    function paused() external view returns (bool);

    function poolId() external view returns (bytes32);

    function proxiableUUID() external view returns (bytes32);

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function rewardPerDistribution() external view returns (uint256);

    function setReward(uint256 _amount) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalDistributed() external view returns (uint256);

    function totalLocked() external view returns (uint256);

    function totalSupply() external view returns (uint256 amount);

    function unlock(uint256 _amount) external;

    function unlockAll() external;

    function unlockedBalanceOf(address _address)
        external
        view
        returns (uint256 amount);

    function unpause() external;

    function update() external;

    function updateDepositLockDuration(uint256 _depositLockDuration) external;

    function updateWithdrawLockDuration(uint256 _withdrawLockDuration) external;

    function upgradeStatus() external view returns (bool);

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data)
        external;

    function waitingForWithdrawal() external view returns (uint256);

    function weth() external view returns (address);

    function withdraw() external;

    function withdrawLockDuration() external view returns (uint256);

    function withdrawTokens(
        address withdrawToken,
        address to,
        uint256 amount
    ) external;
}