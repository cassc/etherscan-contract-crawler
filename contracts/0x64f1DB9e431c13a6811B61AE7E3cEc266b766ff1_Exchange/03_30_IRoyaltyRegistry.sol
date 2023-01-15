// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IRoyaltyRegistry is IERC2981Upgradeable {
  /**
   * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
   * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
   */
  function royaltyInfo(
    address _token,
    uint256 _tokenId,
    uint256 _salePrice,
    uint8 _isSecondarySale
  )
    external
    returns (
      address[] memory receivers,
      uint256[] memory royaltyFees,
      uint8 royaltyType
    );

  /**
   * @dev Returns the division factor for calculating precentage
   */
  function feeDenominator() external returns (uint16);
}