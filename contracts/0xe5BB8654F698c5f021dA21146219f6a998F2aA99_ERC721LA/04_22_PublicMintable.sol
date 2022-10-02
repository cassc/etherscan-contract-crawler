// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "../libraries/CustomErrors.sol";
import "../libraries/BPS.sol";
import "./ERC721Mintable.sol";
import "../libraries/CustomErrors.sol";
import "../libraries/LANFTUtils.sol";
import "../tokens/ERC721State.sol";
import "./IPublicMintable.sol";
import "../platform/royalties/RoyaltiesState.sol";
import "./Pausable.sol";

abstract contract PublicMintable is IPublicMintable, ERC721Mintable, Pausable {
    function publicMint(uint256 editionId, uint24 quantity)
        public
        payable
        whenNotPaused
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        ERC721State.Edition memory edition = state._editions[editionId];

        if (edition.contractMintPriceInFinney == 0) {
            revert CustomErrors.NotAllowed();
        }

        // Finney to Wei
        uint256 mintPriceInWei = uint256(edition.contractMintPriceInFinney) *
            10e14;

        // Check if sufficiant
        if (msg.value < mintPriceInWei * quantity) {
            revert CustomErrors.InsufficientFunds();
        }

        uint256 firstTokenId = _safeMint(editionId, quantity, msg.sender);

        // Send primary royalties
        (
            address payable[] memory wallets,
            uint256[] memory primarySalePercentages
        ) = state._royaltyRegistry.primaryRoyaltyInfo(
                address(this),
                msg.sender,
                firstTokenId
            );

        uint256 nReceivers = wallets.length;

        for (uint256 i = 0; i < nReceivers; i++) {
            uint256 royalties = BPS._calculatePercentage(
                msg.value,
                primarySalePercentages[i]
            );
            (bool sent, ) = wallets[i].call{value: royalties}("");
        }
    }
}