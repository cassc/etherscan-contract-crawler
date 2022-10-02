// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "../tokens/IERC721LA.sol";
import "../tokens/IERC721Events.sol";
import "../libraries/CustomErrors.sol";
import "../libraries/LANFTUtils.sol";
import "../tokens/ERC721State.sol";
import "../libraries/BitMaps/BitMaps.sol";

abstract contract ERC721Mintable is IERC721Events {
    using BitMaps for BitMaps.BitMap;
    using ERC721State for ERC721State.ERC721LAState;

    /**
     * @dev Given an editionId and  tokenNumber, returns tokenId in the following format:
     * `[editionId][tokenNumber]` where `tokenNumber` is between 1 and EDITION_TOKEN_MULTIPLIER - 1
     * eg.: The second token from the 5th edition would be `500002`
     *
     */
    function editionedTokenId(uint256 editionId, uint256 tokenNumber)
        public
        view
        virtual
        returns (uint256 tokenId);

    /**
     * @dev Internal batch minting function
     * Does not emit events.
     * This is useful to emulate lazy minting
     */
    function _silentMint(
        uint256 _editionId,
        uint24 _quantity,
        address _recipient
    ) internal returns (uint256 firstTokenId) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        ERC721State.Edition storage edition = state._editions[_editionId];

        uint256 tokenNumber = edition.currentSupply + 1;

        if (_editionId > state._editionCounter) {
            revert CustomErrors.InvalidEditionId();
        }

        if (_quantity == 0 || _recipient == address(0)) {
            revert CustomErrors.InvalidMintData();
        }

        if (tokenNumber > edition.maxSupply) {
            revert CustomErrors.MaxSupplyError();
        }

        firstTokenId = editionedTokenId(_editionId, tokenNumber);

        // -1 is because first tokenNumber is included
        if (edition.currentSupply + _quantity > edition.maxSupply) {
            revert CustomErrors.MaxSupplyError();
        }

        edition.currentSupply += _quantity;
        state._owners[firstTokenId] = _recipient;
        state._batchHead.set(firstTokenId);
        state._balances[_recipient] += _quantity;
    }

    /**
     * @dev Internal batch minting function
     */
    function _safeMint(
        uint256 _editionId,
        uint24 _quantity,
        address _recipient
    ) internal returns (uint256 firstTokenId) {
        firstTokenId = _silentMint(_editionId, _quantity, _recipient);

        // Emit events
        for (
            uint256 tokenId = firstTokenId;
            tokenId < firstTokenId + _quantity;
            tokenId++
        ) {
            emit Transfer(address(0), _recipient, tokenId);
            LANFTUtils._checkOnERC721Received(
                address(0),
                _recipient,
                tokenId,
                ""
            );
        }
    }
}