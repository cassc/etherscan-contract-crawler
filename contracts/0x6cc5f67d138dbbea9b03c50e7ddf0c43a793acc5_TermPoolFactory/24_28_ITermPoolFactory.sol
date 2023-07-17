// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITermPoolFactory {
  struct PoolInfo {
    address pool;
    address currency;
    bool isListed;
  }

  event TermPoolCreated(address indexed _pool, address indexed _baseToken);
  event TermPoolBeaconSet(address indexed _poolBeacon);
  event TpTokenBeaconSet(address indexed _tpTokenBeacon);
  event PermissionlessFactoryChanged(address indexed newAddress);

  error NotOwnerOrManager(address sender);
  error WrongCpToken(address cpTokenProvided);
  error PoolAlreadyExist(address termPool);
  error PoolNotExist(address cpToken);
  error SameListingStatus(address termPool);

  function createTermPool(address _cpToken) external returns (address pool);

  /// @notice Get term pool beacon address
  function tpTokenBeacon() external view returns (address);

  /// @notice Get permissionless factory address
  function permissionlessFactory() external view returns (address);

  /// @notice Get all pools addresses
  function getPools() external view returns (PoolInfo[] memory pools);

  /// @notice cpToken address to it's corresponding pool address
  function poolsByCpToken(
    address
  ) external view returns (address pool, address currency, bool isListed);
}