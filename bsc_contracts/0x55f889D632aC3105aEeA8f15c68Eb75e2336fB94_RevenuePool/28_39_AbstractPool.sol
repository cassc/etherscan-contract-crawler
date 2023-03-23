// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IPool.sol";
import "./AbstractRegistry.sol";
import "../libs/Errors.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract AbstractPool is IPool, OwnableUpgradeable {
  ERC20 baseToken;
  AbstractRegistry registry;
  uint256 baseDecimals;

  function __AbstractPool_init(
    address _owner,
    ERC20 _baseToken,
    AbstractRegistry _registry
  ) internal onlyInitializing {
    __Ownable_init();
    _require(_baseToken.decimals() <= 18, Errors.INVALID_TOKEN_DECIMALS);
    _transferOwnership(_owner);
    baseToken = _baseToken;
    registry = _registry;
    baseDecimals = _baseToken.decimals();
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  modifier onlyApproved() {
    _require(
      registry.hasRole(registry.APPROVED_ROLE(), msg.sender),
      Errors.APPROVED_ONLY
    );
    _;
  }

  function transferBase(address _to, uint256 _amount) external virtual override;

  function transferFromPool(
    address _token,
    address _to,
    uint256 _amount
  ) external virtual override;
}