// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract ERC2981 is IERC2981, ERC165 {

    struct Royalty {
        address recipient;
        uint96 numerator;
    }

    Royalty private _defaultRoyalty;

    mapping (uint256 => Royalty) private _tokenRoyalties;

    constructor() {
        _setDefaultRoyalty(msg.sender, 1000);
    }

    function _setDefaultRoyalty(address recipient, uint96 numerator) internal {
        _defaultRoyalty = Royalty(recipient, numerator);
    }

    function _setTokenRoyalty(uint256 tokenId, address recipient, uint96 numerator) internal {
        _tokenRoyalties[tokenId] = Royalty(recipient, numerator);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure returns (uint96) {
        return 10000;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view  override returns (address, uint256) {
        Royalty memory royalty = _tokenRoyalties[tokenId];
        
        if (royalty.recipient == address(0)) {
            royalty = _defaultRoyalty;
        }

        uint256 royaltyAmount = (salePrice * royalty.numerator) / _feeDenominator();
        return (royalty.recipient, royaltyAmount);
    }
}