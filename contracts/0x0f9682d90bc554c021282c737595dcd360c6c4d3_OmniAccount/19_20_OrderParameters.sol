// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import {TokenIdentifierLibrary, TokenIdentifier} from "./TokenIdentifier.sol";

// duration, startMultiplier, endMultiplier, maxPrice, and minPrice are all assumed to be wad numbers (ie 1e18 == 1.0)
struct OrderParameters {
  address collection;
  uint256 id;
  address payable owner;
  bytes32 reservoirId;
  uint256 duration;
  uint256 startMultiplier;
  uint256 endMultiplier;
  uint256 maxPrice;
  uint256 minPrice;
  bool paused;
}

library OrderParametersLibrary {
  using TokenIdentifierLibrary for TokenIdentifier;

  /// Errors
  error ZeroOrNegativeDuration();
  error Unauthorized();
  error MultiplierLessThanOne();
  error NegativeAbsoluteMinPrices();
  error AbsoluteMaxLessThanAbsoluteMin();

  error CollectionChanged();
  error TokenIdChanged();


  // Compute the hash of an auction state object.
  function hash(OrderParameters calldata parameters)
      public
      pure
      returns (bytes32)
  {
      return keccak256(abi.encode(parameters));
  }

  /// @notice Given a OrderParameters struct, return a OrderParameters struct containing default values
  /// @param params the parameters to sanitize
  /// @return isValid whether the parameters are valid or not
  function validate(OrderParameters calldata params) public view returns (bool) {
    if (params.startMultiplier != params.endMultiplier && params.duration <= 0) {
      revert ZeroOrNegativeDuration();
    }

    if (params.owner != msg.sender) {
      revert Unauthorized();
    }

    if (params.startMultiplier < 1 || params.endMultiplier < 1) {
      revert MultiplierLessThanOne();
    }

    if (params.minPrice < 0) {
      revert NegativeAbsoluteMinPrices();
    }


    if (params.maxPrice < params.minPrice) {
      revert AbsoluteMaxLessThanAbsoluteMin();
    }

    return true;
  }

  function idHash(OrderParameters calldata params) public pure returns (bytes32) {
    return TokenIdentifier({collection: params.collection, id: params.id}).hash();
  }

  function validateUpdate(OrderParameters calldata oldParams, OrderParameters calldata newParams) public pure returns (bool) {
    if (oldParams.owner != newParams.owner) {
      revert Unauthorized();
    }

    if (oldParams.collection != newParams.collection) {
      revert CollectionChanged();
    }

    if (oldParams.id != newParams.id) {
      revert TokenIdChanged();
    }

    return true;
  }
}