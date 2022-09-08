// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.7.6;

/// @dev Taken from https://github.com/f8n/fnd-protocol/tree/v2.0.3

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

/**
 * @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFTMarketCore is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    /// @notice Emitted when owner has updated the minIncrementPermille
    event MinIncrementPermilleUpdated(uint16 prevValue, uint16 newValue);

    /// @dev The minimum required when making an offer or placing a bid. Ej: 100 => 0.1 => 10%
    uint16 public minIncrementPermille;

    /**
     * @param _minIncrementPermille The increment to outbid. Ej: 100 => 0.1 => 10%
     */
    function _initializeNFTMarketCore(uint16 _minIncrementPermille) internal {
        minIncrementPermille = _minIncrementPermille;
    }

    function setMinIncrementPermille(uint16 _minIncrementPermille) external onlyOwner {
        emit MinIncrementPermilleUpdated(minIncrementPermille, _minIncrementPermille);
        minIncrementPermille = _minIncrementPermille;
    }

    /**
     * @notice Transfers the NFT from escrow and clears any state tracking this escrowed NFT.
     */
    function _transferFromEscrow(
        address nftContract,
        uint256 tokenId,
        address recipient
    ) internal virtual;

    /**
     * @notice Transfers an NFT into escrow
     */
    function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual;

    /**
     * @notice Applies fees and distributes funds for a finalized market operation.
     * For all creator, platforma and seller.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param amount Reserve price, plus buyerFee.
     * @param seller The address of the seller.
     * @return platformFee Platform share total from the sale, both taken from the buyer and seller
     * @return royaltyFee Rayalty fee distributed to owner/s
     * @return assetFee Total received bu the saller
     */
    function _distFunds(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        address payable seller
    )
        internal
        virtual
        returns (
            uint256 platformFee,
            uint256 royaltyFee,
            uint256 assetFee
        );

    /**
     * @notice For a given price and fee, it returns the total amount a buyer must provide to cover for both
     * @param _price the target price
     * @param _buyerFeePermille the fee taken from the buyer, expressed in *1000 (ej: 10% = 0.1 => 100)
     * @return amount the buyer must sent to comply to this price and fees
     */
    function applyBuyerFee(uint256 _price, uint8 _buyerFeePermille) internal pure returns (uint256 amount) {
        if (_buyerFeePermille == 0) {
            amount = _price;
        } else {
            amount = _price.add(_price.mul(_buyerFeePermille).div(1000));
        }
    }

    /**
     * @dev Determines the minimum amount when increasing an existing offer or bid.
     */
    function _getMinIncrement(uint256 currentAmount) internal view returns (uint256) {
        uint256 minIncrement = currentAmount.mul(minIncrementPermille).div(1000);
        if (minIncrement == 0) {
            // Since minIncrement reduces from the currentAmount, this cannot overflow.
            // The next amount must be at least 1 wei greater than the current.
            return currentAmount + 1;
        }

        return minIncrement + currentAmount;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}