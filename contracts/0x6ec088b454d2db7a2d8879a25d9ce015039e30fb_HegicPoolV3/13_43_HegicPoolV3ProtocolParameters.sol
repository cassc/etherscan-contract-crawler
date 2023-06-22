// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '@openzeppelin/contracts/math/SafeMath.sol';

import '../../../interfaces/HegicPool/V3/IHegicPoolV3ProtocolParameters.sol';
import '../../../interfaces/LotManager/V2/ILotManagerV2.sol';
import '../../../interfaces/IZHegic.sol';

abstract
contract HegicPoolV3ProtocolParameters is IHegicPoolV3ProtocolParameters {
  using SafeMath for uint256;

  uint256 public override constant NAV_PREMIUM_PRECISION = 10000;
  uint256 public override constant MAX_NAV_PREMIUM = 5 * NAV_PREMIUM_PRECISION / 10; // 0.5%

  uint256 public override minTokenReserves = 0;
  uint256 public override NAVPremium = 0; // 1 * NAV_PREMIUM_PRECISION / 10 = 0.1%
  uint256 public override poolShareOfNAVPremium = 90 * NAV_PREMIUM_PRECISION; // 90% of nav fee = 0.09%
  uint256 public override protocolShareOfNAVPremium = 10 * NAV_PREMIUM_PRECISION; // 10% = 0.01%
  address public override protocolNAVPremiumRecipient;

  IERC20 public override token;
  IZHegic public override zToken;
  ILotManagerV2 public override lotManager;

  constructor (
    address _token,
    address _zToken,
    address _lotManager,
    uint256 _minTokenReserves,
    uint256 _NAVPremium,
    uint256[2] memory _NAVShares,
    address _protocolNAVPremiumRecipient
  ) public {
    _setToken(_token);
    _setZToken(_zToken);
    if (_lotManager != address(0)) {
      _setLotManager(_lotManager);
    }
    _setMinTokenReserves(_minTokenReserves);
    _setNAVPremium(_NAVPremium);
    _setNAVPremiumShares(_NAVShares[0], _NAVShares[1]);
    _setProtocolNAVPremiumRecipient(_protocolNAVPremiumRecipient);
  }

  // Interfaces to addresess - For later deprecation
  function getToken() external view override returns (address) {
    return address(token);
  }

  function getZToken() external view override returns (address) {
    return address(zToken);
  }

  function getLotManager() external view override returns (address) {
    return address(lotManager);
  }

  // Calculated variables
  function unusedUnderlyingBalance() public override view returns (uint256) {
    return token.balanceOf(address(this));
  }

  function totalUnderlying() public override view returns (uint256) {
    if (address(lotManager) == address(0)) return unusedUnderlyingBalance();
    return unusedUnderlyingBalance().add(lotManager.balanceOfUnderlying());
  }

  function getPricePerFullShare() public override view returns (uint256) {
    return totalUnderlying().mul(1e18).div(zToken.totalSupply());
  }

  // Setters
  function _setMinTokenReserves(uint256 _minTokenReserves) internal {
    minTokenReserves = _minTokenReserves;
    emit MinTokenReservesSet(_minTokenReserves);
  }

  function _setNAVPremium(uint256 _NAVPremium) internal {
    require(_NAVPremium <= MAX_NAV_PREMIUM, 'HegicPoolV3::_setNAVPremium::max-nav-premium');
    NAVPremium = _NAVPremium;
    emit NAVPremiumSet(_NAVPremium);
  }

  function _setNAVPremiumShares(uint256 _poolShareOfNAVPremium, uint256 _protocolShareOfNAVPremium) internal {
    require(_poolShareOfNAVPremium.add(_protocolShareOfNAVPremium) == NAV_PREMIUM_PRECISION.mul(100), 'HegicPoolV3::_setNAVPremiumShares::shares-dont-add-up');
    poolShareOfNAVPremium = _poolShareOfNAVPremium;
    protocolShareOfNAVPremium = _protocolShareOfNAVPremium;
    emit PremiumSharesSet(_poolShareOfNAVPremium, _protocolShareOfNAVPremium);
  }

  function _setProtocolNAVPremiumRecipient(address _protocolNAVPremiumRecipient) internal {
    require(_protocolNAVPremiumRecipient != address(0), 'HegicPoolV3::_setProtocolNAVPremiumRecipient::not-zero-address');
    protocolNAVPremiumRecipient = _protocolNAVPremiumRecipient;
    emit ProtocolNAVPremiumRecipientSet(_protocolNAVPremiumRecipient);
  }

  function _setToken(address _token) internal {
    require(_token != address(0), 'HegicPoolV3::_setToken::not-zero-address');
    token = IERC20(_token);
    emit TokenSet(_token);
  }

  function _setZToken(address _zToken) internal {
    require(_zToken != address(0), 'HegicPoolV3::_setZToken::not-zero-address');
    zToken = IZHegic(_zToken);
    emit ZTokenSet(_zToken);
  }

  function _setLotManager(address _lotManager) internal {
    require(_lotManager != address(0), 'HegicPoolV3::_setLotManager::not-zero-address');
    require(ILotManagerV2(_lotManager).isLotManager(), 'HegicPoolV3::_setLotManager::not-lot-manager');
    lotManager = ILotManagerV2(_lotManager);
    emit LotManagerSet(_lotManager);
  }
}