// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "../libraries/CustomErrors.sol";
import "../libraries/BPS.sol";
import "../tokens/ERC721LACore.sol";
import "../libraries/LANFTUtils.sol";
import "../tokens/ERC721State.sol";

abstract contract Burnable is ERC721LACore {

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               BURNABLE
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId) public {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        
        address owner = ownerOf(tokenId);

        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert CustomErrors.TransferError();
        }
        _transferCore(owner, ERC721LACore.burnAddress, tokenId);

        // Looksrare and other marketplace require the owner to be null address
        emit Transfer(owner, address(0), tokenId);
        (uint256 editionId, ) = parseEditionFromTokenId(tokenId);

        // Update the number of tokens burned for this edition
        state._editions[editionId].burnedSupply += 1;
    }


    function burnRedeemEditionTokens(
        uint256 _editionId,
        uint24 _quantity,
        uint256[] calldata tokenIdsToBurn
    ) public whenPublicMintOpened(_editionId) whenNotPaused {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        ERC721State.Edition memory edition = getEdition(_editionId);

        if (edition.burnableEditionId == 0 || tokenIdsToBurn.length == 0) {
            revert CustomErrors.BurnRedeemNotAvailable();
        }

        uint256 mintableAmount = tokenIdsToBurn.length / edition.amountToBurn; 

        if (mintableAmount < _quantity) {
            revert CustomErrors.BurnRedeemNotAvailable();
        } 

        // Check max mint per wallet restrictions (if maxMintPerWallet is 0, no restriction apply)
        uint256 mintedCountKey = uint256(
            keccak256(abi.encodePacked(_editionId, msg.sender))
        );

        if (edition.maxMintPerWallet != 0 ) {
            if (
                state._mintedPerWallet[mintedCountKey] + _quantity >
                edition.maxMintPerWallet
            ) {
                revert CustomErrors.MaximumMintAmountReached();
            }
        }
        state._mintedPerWallet[mintedCountKey] += _quantity;


        // We iterate and burn only the required amount of tokens (preventing burning more than necessary)
        // burn will revert if the sender is not the owner of a given token
        for(uint256 i; i<edition.amountToBurn * _quantity;i++) {
            burn(tokenIdsToBurn[i]);
        }

        _safeMint(_editionId, _quantity, msg.sender);
    }

}