// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../MFCTradingLicense.sol";
import "../token/MFCToken.sol";
import "../Registrar.sol";

contract ExchangeCheck {
  MFCTradingLicense private _mfcMembership;
  MFCToken private _mfcToken;

  function _updateExchangeCheck(Registrar registrar) internal {
    _mfcMembership = MFCTradingLicense(registrar.getMFCMembership());
    _mfcToken = MFCToken(registrar.getMFCToken());
  }

  modifier onlyValidMember(address account) {
    require(_mfcMembership.isMemberActive(account) || _mfcToken.isWhitelistedAgent(account), "Account must have active status");
    _;
  }
}