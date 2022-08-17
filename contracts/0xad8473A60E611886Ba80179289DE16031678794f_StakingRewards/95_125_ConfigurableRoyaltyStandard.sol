// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/// @notice Library to house logic around the ERC2981 royalty standard. Contracts
///   using this library should define a ConfigurableRoyaltyStandard.RoyaltyParams
///   state var and public functions that proxy to the logic here. Contracts should
///   take care to ensure that a public `setRoyaltyParams` method is only callable
///   by an admin.
library ConfigurableRoyaltyStandard {
  using SafeMath for uint256;

  /// @dev bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  uint256 internal constant _PERCENTAGE_DECIMALS = 1e18;

  struct RoyaltyParams {
    /// @dev The address that should receive royalties
    address receiver;
    /// @dev The percent of `salePrice` that should be taken for royalties.
    ///   Represented with `_PERCENTAGE_DECIMALS` where `_PERCENTAGE_DECIMALS` is 100%.
    uint256 royaltyPercent;
  }

  event RoyaltyParamsSet(address indexed sender, address newReceiver, uint256 newRoyaltyPercent);

  /// @notice Called with the sale price to determine how much royalty
  //    is owed and to whom.
  /// @param _tokenId The NFT asset queried for royalty information
  /// @param _salePrice The sale price of the NFT asset specified by _tokenId
  /// @return receiver Address that should receive royalties
  /// @return royaltyAmount The royalty payment amount for _salePrice
  function royaltyInfo(
    RoyaltyParams storage params,
    uint256 _tokenId,
    uint256 _salePrice
  ) internal view returns (address, uint256) {
    uint256 royaltyAmount = _salePrice.mul(params.royaltyPercent).div(_PERCENTAGE_DECIMALS);
    return (params.receiver, royaltyAmount);
  }

  /// @notice Set royalty params used in `royaltyInfo`. The calling contract should limit
  ///   public use of this function to owner or using some other access control scheme.
  /// @param newReceiver The new address which should receive royalties. See `receiver`.
  /// @param newRoyaltyPercent The new percent of `salePrice` that should be taken for royalties.
  ///   See `royaltyPercent`.
  /// @dev The receiver cannot be the null address
  function setRoyaltyParams(
    RoyaltyParams storage params,
    address newReceiver,
    uint256 newRoyaltyPercent
  ) internal {
    require(newReceiver != address(0), "Null receiver");
    params.receiver = newReceiver;
    params.royaltyPercent = newRoyaltyPercent;
    emit RoyaltyParamsSet(msg.sender, newReceiver, newRoyaltyPercent);
  }
}