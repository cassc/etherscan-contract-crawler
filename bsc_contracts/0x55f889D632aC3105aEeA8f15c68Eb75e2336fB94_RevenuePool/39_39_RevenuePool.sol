// SPDX-License-Identifier: BUSL-1.1

import "./interfaces/AbstractPool.sol";
import "./interfaces/IDistributable.sol";
import "./libs/ERC20Fixed.sol";
import "./libs/math/FixedPoint.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

pragma solidity ^0.8.17;

contract RevenuePool is AbstractPool, IDistributable {
  using SafeCast for uint256;
  using FixedPoint for uint256;
  using ERC20Fixed for ERC20;
  using EnumerableMap for EnumerableMap.AddressToUintMap;

  EnumerableMap.AddressToUintMap internal _shares;
  mapping(address => uint256) internal _balances;

  event SetShareEvent(address claimer, uint256 share);
  event AddBalanceEvent(address claimer, uint256 amount);
  event RemoveBalanceEvent(address claimer, uint256 amount);

  function initialize(
    address _owner,
    ERC20 _baseToken,
    AbstractRegistry _registry
  ) external initializer {
    __AbstractPool_init(_owner, _baseToken, _registry);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  modifier onlyApprovedClaimer(address claimer) {
    _require(_shares.contains(claimer), Errors.APPROVED_ONLY);
    _;
  }

  function transferBase(
    address _to,
    uint256 _amount
  ) external override onlyOwner {
    baseToken.transferFixed(_to, _amount);
  }

  function transferFromPool(
    address _token,
    address _to,
    uint256 _amount
  ) external override onlyOwner {
    _require(_token == address(baseToken), Errors.TOKEN_MISMATCH);
    baseToken.transferFixed(_to, _amount);
  }

  function getBaseBalance() external view returns (uint256) {
    return baseToken.balanceOfFixed(address(this));
  }

  function getShare(address claimer) external view returns (uint256) {
    if (_shares.contains(claimer)) {
      return _shares.get(claimer);
    }
    return 0;
  }

  function setShare(address claimer, uint256 _share) external onlyOwner {
    _shares.set(claimer, _share);
    uint256 _length = _shares.length();
    uint256 _sum = 0;
    for (uint256 i = 0; i < _length; ++i) {
      (, uint256 __share) = _shares.at(i);
      _sum += __share;
    }
    _require(_sum <= 1e18, Errors.INVALID_SHARE);

    emit SetShareEvent(claimer, _share);
  }

  function transferIn(uint256 amount) external {
    baseToken.transferFromFixed(msg.sender, address(this), amount);
    uint256 _length = _shares.length();
    for (uint256 i = 0; i < _length; ++i) {
      (address claimer, uint256 share) = _shares.at(i);
      _balances[address(claimer)] += amount.mulDown(share);
    }
  }

  function balance() external view override returns (uint256) {
    return _balances[msg.sender];
  }

  function addBalance(
    uint256 amount
  ) external override onlyApprovedClaimer(msg.sender) {
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    emit AddBalanceEvent(msg.sender, amount);
  }

  function removeBalance(
    uint256 amount
  ) external override onlyApprovedClaimer(msg.sender) {
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    emit RemoveBalanceEvent(msg.sender, amount);
  }

  function balance(address claimer) external view returns (uint256) {
    return _balances[claimer];
  }

  function mint(
    address to,
    uint256 amount
  ) external override onlyApprovedClaimer(msg.sender) {
    uint256 _amount = amount.min(baseToken.balanceOfFixed(address(this)));
    baseToken.transferFixed(to, _amount);
  }
}