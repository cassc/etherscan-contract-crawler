// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/ConfigurableRoyaltyStandard.sol";
import "../protocol/core/HasAdmin.sol";
import "../interfaces/IERC2981.sol";

contract TestConfigurableRoyaltyStandard is HasAdmin, IERC2981 {
  using ConfigurableRoyaltyStandard for ConfigurableRoyaltyStandard.RoyaltyParams;

  ConfigurableRoyaltyStandard.RoyaltyParams public royaltyParams;

  // The library event must be copied to the base contract so that decoding clients
  // don't get confused. See https://medium.com/aragondec/library-driven-development-in-solidity-2bebcaf88736#7ed4
  event RoyaltyParamsSet(address indexed sender, address newReceiver, uint256 newRoyaltyPercent);

  constructor(address owner) public {
    __AccessControl_init_unchained();
    _setupRole(OWNER_ROLE, owner);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  /// @notice Called with the sale price to determine how much royalty
  //    is owed and to whom.
  /// @param _tokenId The NFT asset queried for royalty information
  /// @param _salePrice The sale price of the NFT asset specified by _tokenId
  /// @return receiver Address that should receive royalties
  /// @return royaltyAmount The royalty payment amount for _salePrice
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view override returns (address, uint256) {
    return royaltyParams.royaltyInfo(_tokenId, _salePrice);
  }

  /// @notice Set royalty params used in `royaltyInfo`. This function is only callable by
  ///   an address with `OWNER_ROLE`.
  /// @param newReceiver The new address which should receive royalties. See `receiver`.
  /// @param newRoyaltyPercent The new percent of `salePrice` that should be taken for royalties.
  ///   See `royaltyPercent`.
  function setRoyaltyParams(address newReceiver, uint256 newRoyaltyPercent) external onlyAdmin {
    royaltyParams.setRoyaltyParams(newReceiver, newRoyaltyPercent);
  }

  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return interfaceId == ConfigurableRoyaltyStandard._INTERFACE_ID_ERC2981;
  }
}