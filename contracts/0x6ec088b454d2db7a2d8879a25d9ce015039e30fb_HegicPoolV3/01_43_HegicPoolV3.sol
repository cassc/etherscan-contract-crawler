// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '../../Governable.sol';
import '../../Manageable.sol';
import '../../CollectableDust.sol';

import './HegicPoolV3Depositable.sol';
import './HegicPoolV3LotManager.sol';
import './HegicPoolV3Metadata.sol';
import './HegicPoolV3Migratable.sol';
import './HegicPoolV3ProtocolParameters.sol';
import './HegicPoolV3Withdrawable.sol';

contract HegicPoolV3 is 
  Governable,
  Manageable,
  CollectableDust,
  HegicPoolV3Metadata,
  HegicPoolV3ProtocolParameters,
  HegicPoolV3Migratable,
  HegicPoolV3Depositable,
  HegicPoolV3Withdrawable,
  HegicPoolV3LotManager {
  
  constructor(
    address[2] memory _governorAndManager,
    address _token,
    address _zToken,
    address _lotManager,
    uint256 _minTokenReserves,
    uint256 _NAVPremium,
    uint256[2] memory _NAVShares,
    address _protocolNAVPremiumRecipient
  ) public
    Governable(_governorAndManager[0])
    Manageable(_governorAndManager[1])
    CollectableDust()
    HegicPoolV3Metadata()
    HegicPoolV3ProtocolParameters(
      _token,
      _zToken,
      _lotManager,
      _minTokenReserves,
      _NAVPremium,
      _NAVShares,
      _protocolNAVPremiumRecipient)
    HegicPoolV3Migratable()
    HegicPoolV3Depositable()
    HegicPoolV3Withdrawable()
    HegicPoolV3LotManager() {
      _addProtocolToken(_token);
      _addProtocolToken(_zToken);
  }

  // Depositable
  function deposit(uint256 _amount) external override returns (uint256 _depositorShares) {
    return _deposit(_amount);
  }

  function depositAll() external override returns (uint256 _shares) {
    return _depositAll();
  }

  // Withdrawable
  function withdraw(uint256 _shares) external override returns (uint256 _underlyingToWithdraw) {
    return _withdraw(_shares);
  }

  function withdrawAll() external override returns (uint256 _underlyingToWithdraw) {
    return _withdrawAll();
  }

  // Migrable
  function migrate(address _newPool) external override onlyGovernor {
    _migrate(_newPool);
  }

  // LotManager
  function claimRewards() external override onlyManager returns (uint _rewards) {
    return _claimRewards();
  }

  function buyLots(uint256 _eth, uint256 _wbtc) external override onlyManager returns (bool) {
    return _buyLots(_eth, _wbtc);
  }

  // Protocol Parameters
  function setToken(address _token) public override onlyGovernor {
    _setToken(_token);
  }
  
  function setZToken(address _zToken) public override onlyGovernor {
    _setZToken(_zToken);
  }
  
  function setLotManager(address _lotManager) public override onlyGovernor {
    _setLotManager(_lotManager);
  }

  function setMinTokenReserves(uint256 _minTokenReserves) public override onlyGovernor {
    _setMinTokenReserves(_minTokenReserves);
  }

  function setNAVPremium(uint256 _NAVPremium) public override onlyGovernor {
    _setNAVPremium(_NAVPremium);
  }

  function setNAVPremiumShares(uint256 _poolShareOfPremium, uint256 _protocolShareOfPremium) public override onlyGovernor {
    _setNAVPremiumShares(_poolShareOfPremium, _protocolShareOfPremium);
  }

  function setProtocolNAVPremiumRecipient(address _protocolNAVPremiumRecipient) public override onlyGovernor {
    _setProtocolNAVPremiumRecipient(_protocolNAVPremiumRecipient);
  }

  // Governable
  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  function acceptGovernor() external override onlyPendingGovernor {
    _acceptGovernor();
  }

  // Manageable
  function setPendingManager(address _pendingManager) external override onlyManager {
    _setPendingManager(_pendingManager);
  }

  function acceptManager() external override onlyPendingManager {
    _acceptManager();
  }

  // Collectable Dust
  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external override onlyGovernor {
    _sendDust(_to, _token, _amount);
  }
}