// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./AbstractStakeable.sol";
import "../libs/math/FixedPoint.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract AbstractERC721Stakeable is
  ERC721Upgradeable,
  AbstractStakeable
{
  using FixedPoint for uint256;
  using SafeCast for uint256;
  using UpdateableLib for IUpdateable.Updateable;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function __ERC721Stakeable_init() internal onlyInitializing {
    __AbstractStakeable_init();
  }

  function hasStake(address _user) external view override returns (bool) {
    return _stakers[_user].lastClaim > 0;
  }

  // internal functions

  function _stake(
    address sender,
    address staker,
    uint256 tokenId
  ) internal override _notPaused {
    Staker memory _staker = _stakers[staker];
    _require(_staker.lastClaim == 0, Errors.INVALID_TOKEN_ID); // already staked
    _staker.staked = tokenId;
    _staker.lastClaim = uint256(block.number).toUint32();
    _stakers[staker] = _staker;
    _totalStaked = _totalStaked._updateByDelta(1e18);
    if (sender != address(this)) transferFrom(sender, address(this), tokenId);
    emit StakeEvent(sender, staker, tokenId);
  }

  function _unstake(
    address staker,
    uint256 tokenId
  ) internal override _notPaused {
    Staker memory _staker = _updateClaim(staker);
    _require(_staker.staked == tokenId, Errors.INVALID_TOKEN_ID);
    uint256 claimed = _staker.rewardsToClaim;
    delete _stakers[staker];
    _totalStaked = _totalStaked._updateByDelta(-1e18);
    ERC721Upgradeable(this).transferFrom(address(this), staker, tokenId);
    if (claimed > 0) _rewardToken.mint(staker, claimed);
    emit ClaimEvent(staker, claimed);
    emit UnstakeEvent(staker, tokenId);
  }

  function _claim(address staker) internal override _notPaused {
    Staker memory _staker = _updateClaim(staker);
    _require(_staker.lastClaim > 0, Errors.NO_STAKING_POSITION);
    uint256 claimed = _staker.rewardsToClaim;
    _staker.rewardsToClaim = 0;
    _stakers[staker] = _staker;
    if (claimed > 0) _rewardToken.mint(staker, claimed);
    emit ClaimEvent(staker, claimed);
  }

  function _updateClaim(
    address user
  ) internal view returns (Staker memory _staker) {
    uint32 currentBlock = uint256(block.number).toUint32();
    _staker = _stakers[user];
    if (_staker.lastClaim > 0) {
      uint256 accumulatedEmission = _emission._average(_staker.lastClaim) *
        (currentBlock - _staker.lastClaim);
      _staker.rewardsToClaim =
        _staker.rewardsToClaim +
        accumulatedEmission.divDown(_totalStaked._average(_staker.lastClaim));
      _staker.lastClaim = currentBlock;
    }
    return _staker;
  }
}