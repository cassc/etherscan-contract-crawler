// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import "../market/BlockMelonMarketConfig.sol";
import "../market/BlockMelonTreasury.sol";
import "./BlockMelonPullPayment.sol";
import "./PaymentInfo.sol";

abstract contract BlockMelonNFTPaymentManager is
    BlockMelonMarketConfig,
    BlockMelonTreasury,
    BlockMelonPullPayment,
    PaymentInfo
{
    uint256 private constant BASIS_POINTS = 10000;
    /// @dev Indicates whether the given NFT has been sold in this market previously
    mapping(address => mapping(uint256 => bool))
        private _isPrimaryAuctionFinished;

    struct Revenues {
        uint256 marketRevenue;
        uint256 creatorRevenue;
        uint256 sellerRevenue;
        uint256 firstOwnerRevenue;
    }

    function __BlockMelonNFTPaymentManager_init_unchained()
        internal
        onlyInitializing
    {}

    /**
     * @notice Returns true if the given token has not been sold in this market previously and is being sold by the creator.
     */
    function isPrimaryAuction(
        address tokenContract,
        uint256 tokenId,
        address payable seller
    ) public view returns (bool) {
        (, bool isCreator) = _getCreatorPaymentInfo(
            tokenContract,
            tokenId,
            seller
        );
        return isCreator && !_isPrimaryAuctionFinished[tokenContract][tokenId];
    }

    function _payRecipients(
        address tokenContract,
        address payable seller,
        address payable firstOwnerAddress,
        uint256 tokenId,
        uint256 price
    ) internal returns (Revenues memory revs) {
        (
            address payable creatorAddress,
            bool isCreator
        ) = _getCreatorPaymentInfo(tokenContract, tokenId, seller);

        bool isNotFirstOwner = address(0) != firstOwnerAddress &&
            seller != firstOwnerAddress;
        revs = _getRevenues(
            price,
            isCreator,
            _isPrimaryAuctionFinished[tokenContract][tokenId],
            isNotFirstOwner
        );

        // Setting the sale count must come after _getRevenues, as it is used in that function
        _isPrimaryAuctionFinished[tokenContract][tokenId] = true;

        _sendValueToRecipient(getBlockMelonTreasury(), revs.marketRevenue);
        // creatorRevenue is zero if it is a primary sale and/or if the creator is the seller
        // In both cases the sellerRevenue is sent to the creatoraddress
        _sendValueToRecipient(creatorAddress, revs.creatorRevenue);
        // firstOwnerRevenue is zero if the first owner is invalid or it is the seller
        // In the latter case the sellerRevenue is sent to the firstOwnerAddress
        _sendValueToRecipient(firstOwnerAddress, revs.firstOwnerRevenue);
        _sendValueToRecipient(seller, revs.sellerRevenue);
    }

    function _getRevenues(
        uint256 price,
        bool isCreator,
        bool isPrimaryAuctionFinished,
        bool isNotFirstOwner
    ) internal view returns (Revenues memory revs) {
        (
            uint256 primaryBlockMelonFeeInBps,
            uint256 secondaryBlockMelonFeeInBps,
            uint256 secondaryCreatorFeeInBps,
            uint256 secondaryFirstOwnerFeeInBps
        ) = getFeeConfig();

        uint256 blockMelonFeeFeeInBps;
        if (isCreator && !isPrimaryAuctionFinished) {
            blockMelonFeeFeeInBps = primaryBlockMelonFeeInBps;
        } else {
            blockMelonFeeFeeInBps = secondaryBlockMelonFeeInBps;
            if (!isCreator) {
                revs.creatorRevenue =
                    (price * secondaryCreatorFeeInBps) /
                    BASIS_POINTS;
            }
        }
        // Always calculate the revenue of the first owner, if it is a valid address and not the seller
        if (isNotFirstOwner) {
            revs.firstOwnerRevenue =
                (price * secondaryFirstOwnerFeeInBps) /
                BASIS_POINTS;
        }

        revs.marketRevenue = (price * blockMelonFeeFeeInBps) / BASIS_POINTS;
        revs.sellerRevenue =
            price -
            revs.marketRevenue -
            revs.creatorRevenue -
            revs.firstOwnerRevenue;
    }

    uint256[50] private __gap;
}