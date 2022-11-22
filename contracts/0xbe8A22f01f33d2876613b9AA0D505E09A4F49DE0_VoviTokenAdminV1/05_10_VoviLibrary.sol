// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./LibVoviStorage.sol";

library VoviLibrary {
  using LibVoviStorage for *;


  function arrayContains(address[] memory array, address target) internal pure returns (bool) {
    for (uint256 i; i < array.length; i++) {
      if (array[i] == target) return true;
    }
    return false;
  }

  function isValidReward(LibVoviStorage.Reward memory reward, address adminSigner) internal pure returns (bool) {
    bytes32 digest = keccak256(
      abi.encode(reward.tokenId, reward.tokens)
    );
    return _isVerifiedCoupon(digest, reward.coupon, adminSigner);
  }
  
  /// @dev check that the coupon sent was signed by the admin signer
  function _isVerifiedCoupon(bytes32 digest, LibVoviStorage.Coupon memory coupon, address _adminSigner)
    internal
    pure
    returns (bool)
  {
    address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
    require(signer != address(0), 'ECDSA: invalid signature');
    return signer == _adminSigner;
  }

  function inRange(uint256 target, uint256 lower, uint256 upper) internal pure returns (bool) {
    return target >= lower && target <= upper;
  }

  event Staked(address indexed account, LibVoviStorage.StakeRequest[] requests);
  event Unstaked(address indexed account, LibVoviStorage.ClaimRequest[] requests, uint256[] avatars);
  event RewardsClaimed(address indexed account, uint256 amount);
}