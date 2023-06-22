// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import '../../../interfaces/HegicPool/V3/IHegicPoolV3Depositable.sol';

import './HegicPoolV3ProtocolParameters.sol';

abstract
contract HegicPoolV3Depositable is HegicPoolV3ProtocolParameters, IHegicPoolV3Depositable {

  using SafeERC20 for IERC20;
  
  function _deposit(uint256 _amount) internal returns (uint256 _depositorShares) {
    uint256 _totalUnderlying = totalUnderlying();
    uint256 _before = unusedUnderlyingBalance();
    token.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _after = unusedUnderlyingBalance();
    _amount = _after.sub(_before);
    uint256 _totalShares = zToken.totalSupply() == 0 ? _amount : (_amount.mul(zToken.totalSupply())).div(_totalUnderlying);
    uint256 _totalNAVPremium = _totalShares.mul(NAVPremium).div(NAV_PREMIUM_PRECISION).div(100);
    uint256 _protocolShares = _totalNAVPremium.mul(protocolShareOfNAVPremium).div(NAV_PREMIUM_PRECISION).div(100);
    _depositorShares = _totalShares.sub(_totalNAVPremium);
    zToken.mint(protocolNAVPremiumRecipient, _protocolShares);
    zToken.mint(msg.sender, _depositorShares);
    emit Deposited(
      msg.sender,
      _amount, 
      _depositorShares,
      _totalShares.sub(_depositorShares).sub(_protocolShares),
      _protocolShares
    );
  }

  function _depositAll() internal returns (uint256 _shares) {
    return _deposit(token.balanceOf(msg.sender));
  }
}