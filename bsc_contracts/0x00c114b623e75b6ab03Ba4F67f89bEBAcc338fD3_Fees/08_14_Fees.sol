// SPDX-License-Identifier: BUSL-1.1

import "./interfaces/IFee.sol";
import "./interfaces/IReferral.sol";
import "./interfaces/IStakeable.sol";
import "./libs/math/FixedPoint.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

pragma solidity ^0.8.17;

contract Fees is IFee, OwnableUpgradeable {
  using FixedPoint for uint256;
  using SafeCast for uint256;
  using EnumerableMap for EnumerableMap.AddressToUintMap;

  /// @custom:oz-renamed-from defaultFee
  uint256 public openFee;
  IReferral internal referral;

  // UGP related variables
  /// @custom:oz-renamed-from _ugpFee
  EnumerableMap.AddressToUintMap internal _ugpFeeDiscPct;

  uint256 public closeFee;

  event SetUGPFeeDiscPctEvent(address ugpAddress, uint256 ugpFeeDiscPct);
  event SetReferralEvent(address referralAddress);
  event SetOpenFeeEvent(uint256 openFee);
  event SetCloseFeeEvent(uint256 closeFee);

  function initialize(
    address _owner,
    uint256 _defaultFee,
    IReferral _referral
  ) external initializer {
    __Ownable_init();
    _transferOwnership(_owner);
    openFee = _defaultFee;
    closeFee = _defaultFee;
    referral = _referral;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  // governance functions

  function setUGPFeeDiscPct(
    address ugpAddress,
    uint256 ugpFeeDiscPct
  ) external onlyOwner {
    _require(ugpFeeDiscPct <= 1e18, Errors.INVALID_DISCOUNT);
    _ugpFeeDiscPct.set(ugpAddress, ugpFeeDiscPct);
    emit SetUGPFeeDiscPctEvent(ugpAddress, ugpFeeDiscPct);
  }

  function setReferral(IReferral _referral) external onlyOwner {
    referral = _referral;
    emit SetReferralEvent(address(referral));
  }

  function setOpenFee(uint256 _openFee) external onlyOwner {
    openFee = _openFee;
    emit SetOpenFeeEvent(_openFee);
  }

  function setCloseFee(uint256 _closeFee) external onlyOwner {
    closeFee = _closeFee;
    emit SetCloseFeeEvent(_closeFee);
  }

  // external functions

  function getReferral() external view returns (IReferral) {
    return referral;
  }

  function getOpenFee(
    address _user
  ) external view override returns (Fee memory) {
    return _getFee(_user, openFee);
  }

  function getCloseFee(
    address _user
  ) external view override returns (Fee memory) {
    return _getFee(_user, closeFee);
  }

  function getUGPFeeDiscPct(
    address ugpAddress
  ) external view returns (uint256) {
    return _ugpFeeDiscPct.get(ugpAddress);
  }

  // internal functions

  function _getFee(
    address _user,
    uint256 _fee
  ) internal view returns (Fee memory fee) {
    uint256 _length = _ugpFeeDiscPct.length();
    uint256 ugpNet = type(uint256).max;
    for (uint256 i = 0; i < _length; ++i) {
      (address ugpAddress, uint256 ugpFeeDiscPct) = _ugpFeeDiscPct.at(i);
      if (IStakeable(ugpAddress).hasStake(_user)) {
        ugpNet = _fee.sub(_fee.mulDown(ugpFeeDiscPct));
      }
    }

    IReferral.Referral memory _referral = referral.getReferral(_user);
    uint256 referredRebate = _fee.mulDown(_referral.rebatePct);
    uint256 referralRebate = _fee.mulDown(_referral.referralRebatePct);
    uint256 referredNet = _fee.sub(referredRebate);
    if (referredNet <= ugpNet) {
      fee = Fee(
        referredNet.toUint128(),
        referredRebate.toUint128(),
        referralRebate.toUint128(),
        _referral.referralCode,
        _referral.referrer
      );
    } else {
      fee = Fee(ugpNet.toUint128(), 0, 0, bytes32(0), address(0));
    }
  }
}