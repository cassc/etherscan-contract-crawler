// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*----------------------------------------------------------\
|                             _                 _           |
|        /\                  | |     /\        | |          |
|       /  \__   ____ _ _ __ | |_   /  \   _ __| |_ ___     |
|      / /\ \ \ / / _` | '_ \| __| / /\ \ | '__| __/ _ \    |
|     / ____ \ V / (_| | | | | |_ / ____ \| |  | ||  __/    |
|    /_/    \_\_/ \__,_|_| |_|\__/_/    \_\_|   \__\___|    |
|                                                           |
|    https://avantarte.com/careers                          |
|    https://avantarte.com/support/contact                  |
|                                                           |
\----------------------------------------------------------*/

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 * @author Liron Navon
 *
 * Royalty information can only be specified globally for all token ids via {_setDefaultRoyalty}.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * It does the same as open zepplins royalties setup,
 * but doesn't include a royalty per token, only a single royalty for all tokens.
 * https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721Royalty
 */

contract SimpleRoyalties is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    address private _royaltyReciever;
    uint256 private _royaltyFraction;

    constructor(address _reciever, uint256 _fraction) {
        _setRoyalty(_reciever, _fraction);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        uint256 royaltyAmount = (_salePrice * _royaltyFraction) /
            _feeDenominator();
        return (_royaltyReciever, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint256) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setRoyalty(address receiver, uint256 fraction) internal virtual {
        require(fraction <= _feeDenominator(), "ERC2981: fraction too high");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _royaltyReciever = receiver;
        _royaltyFraction = fraction;
    }
}