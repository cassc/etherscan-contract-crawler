pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/tranche/ITranche.sol)

import "../../../external/frax/IFraxGauge.sol";

interface ITranche {
    enum TrancheType {
        DIRECT,
        CONVEX_VAULT
    }

    event RegistrySet(address indexed registry);
    event SetDisabled(bool isDisabled);
    event RewardClaimed(address indexed trancheAddress, uint256[] rewardData);
    event AdditionalLocked(address indexed staker, bytes32 kekId, uint256 liquidity);
    event VeFXSProxySet(address indexed proxy);
    event MigratorToggled(address indexed migrator);

    error InactiveTranche(address tranche);
    error AlreadyInitialized();
    
    function disabled() external view returns (bool);
    function willAcceptLock(uint256 liquidity) external view returns (bool);
    function lockedStakes() external view returns (IFraxGauge.LockedStake[] memory);

    function initialize(address _registry, uint256 _fromImplId, address _newOwner) external returns (address, address);
    function setRegistry(address _registry) external;
    function setDisabled(bool isDisabled) external;
    function setVeFXSProxy(address _proxy) external;
    function toggleMigrator(address migrator_address) external;

    function stake(uint256 liquidity, uint256 secs) external returns (bytes32 kek_id);
    function withdraw(bytes32 kek_id, address destination_address) external returns (uint256 withdrawnAmount);
    function getRewards(address[] calldata rewardTokens) external returns (uint256[] memory rewardAmounts);
}