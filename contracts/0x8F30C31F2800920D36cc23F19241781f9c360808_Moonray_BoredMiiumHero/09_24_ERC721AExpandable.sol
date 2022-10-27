// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// ERC721A from Chiru Labs
import 'erc721a/contracts/ERC721A.sol';

// OZ Libraries
import '@openzeppelin/contracts/utils/Strings.sol';

import './ExpandableTypedTokenExtension.sol';

/**
 * @title ERC721AExpandable
 * @author @NiftyMike | @Dr3amLabs
 * @dev Extend ERC721A contract to add expandable token types.
 */
abstract contract ERC721AExpandable is ExpandableTypedTokenExtension, ERC721A {
    using Strings for uint256;

    constructor(string memory __name, string memory __symbol) ERC721A(__name, __symbol) {
        // Nothing to do
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl)
        returns (bool)
    {
        // ERC721A terminates the chain of super calls, so it needs to be explicitly called.
        return ERC721A.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function maxSupply() external view returns (uint256) {
        return _expandableMaxSupply();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'No token');

        string memory base = _baseURI();
        require(bytes(base).length > 0, 'Base unset');

        uint256 flavor = _getFlavorForToken(tokenId);

        return
            string(
                abi.encodePacked(base, _getUriFragmentForToken(tokenId, _getTokenFlavor(flavor)))
            );
    }

    function _canMint(
        uint256 count,
        uint256 flavorId,
        bool enforceValue,
        uint256 valueSent
    ) internal view returns (TokenFlavor memory) {
        TokenFlavor memory tokenFlavor = _getTokenFlavor(flavorId);
        _checkFlavorIsValid(tokenFlavor);
        _checkCountIsValid(tokenFlavor, count);

        if (enforceValue) {
            _checkValueIsValid(tokenFlavor, count, valueSent);
        }
        tokenFlavor.totalMinted += uint64(count);

        return tokenFlavor;
    }

    function _internalMintTokensOfFlavor(
        address minter,
        uint256 count,
        uint256 flavorId
    ) internal {
        uint256 nextToken = _nextTokenId();

        _safeMint(minter, count);

        _setFlavorForToken(nextToken, flavorId);
        if (count > 1) {
            // Even though this code has to do quite a few duplicate lookups to get the ownerships initialized
            // the gas efficiency is still quite good. It's only about 5% cheaper to modify ERC721a to directly
            // set extra data.
            for (
                uint256 nextTokenIdx = nextToken + 1;
                nextTokenIdx < nextToken + count;
                nextTokenIdx++
            ) {
                _initializeOwnershipAt(nextTokenIdx);
                _setFlavorForToken(nextTokenIdx, flavorId);
            }
        }
    }

    function _setFlavorForToken(uint256 tokenId, uint256 selectedSkin) internal {
        _setExtraDataAt(tokenId, uint24(selectedSkin));
    }

    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal pure override returns (uint24) {
        if (from == to) {
            // Nothing to do. Just doing this to get rid of warning.
        }

        // Just return the existing extra data, which is the selected flavor for the token.
        return previousExtraData;
    }

    function _getFlavorForToken(uint256 tokenId) internal view returns (uint256) {
        uint24 extraData = uint24(_ownershipAt(tokenId).extraData);
        return uint256(extraData);
    }
}