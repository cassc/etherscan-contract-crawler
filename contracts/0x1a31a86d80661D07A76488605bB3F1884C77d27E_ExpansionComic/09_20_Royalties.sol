// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165, ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 */
abstract contract Royalties is IERC2981, ERC165 {
    struct Royalty {
        address receiver;
        uint96 royaltyFraction;
    }

    Royalty _defaultRoyalty;

    mapping(uint256 => Royalty) _tokenRoyalty;

    uint256 ROYALTY_DENOMINATOR = 10000;

    /**
     * @notice Default Royalty Details
     */
    function getDefaultRoyaltyDetails() external view returns (Royalty memory) {
        return _defaultRoyalty;
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) public view virtual override returns (address, uint256) {
        Royalty memory royalty = _tokenRoyalty[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyalty;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) /
            ROYALTY_DENOMINATOR;

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // * INTERNAL * //

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyalty;
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _deleteTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyalty[tokenId];
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= ROYALTY_DENOMINATOR,
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyalty = Royalty(receiver, feeNumerator);
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= ROYALTY_DENOMINATOR,
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyalty[tokenId] = Royalty(receiver, feeNumerator);
    }
}