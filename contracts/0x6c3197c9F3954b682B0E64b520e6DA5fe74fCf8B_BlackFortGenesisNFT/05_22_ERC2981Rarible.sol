// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./IERC2981Rarible.sol";
import "./LibPart.sol";


abstract contract ERC2981Rarible is ERC2981, IERC2981Rarible {
    LibPart.Part[] private _defaultRoyalties;
    mapping (uint256 => LibPart.Part[]) private _royalties;

    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _tokenRoyalties = _royalties[id];
        if (_tokenRoyalties.length == 0) {
            return _defaultRoyalties;
        }
        return _tokenRoyalties;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public virtual override view returns (address, uint256) {
        LibPart.Part[] memory _tokenRoyalties = _royalties[tokenId];
        if (_tokenRoyalties.length == 0) {
            _tokenRoyalties = _defaultRoyalties;
            if (_tokenRoyalties.length == 0) {
                return (address(0), 0);
            }
        }

        uint256 percent = 0;
        for (uint i = 0; i < _tokenRoyalties.length; i++) {
            percent += _tokenRoyalties[i].value;
        }

        return (_tokenRoyalties[0].account, percent * salePrice / _feeDenominator());
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, IERC165) returns (bool) {
        return interfaceId == type(IERC2981Rarible).interfaceId || super.supportsInterface(interfaceId);
    }

    function _setDefaultRoyalties(LibPart.Part[] memory royalties) internal {
        _validateRoyalties(royalties);
        delete _defaultRoyalties;

        for (uint i = 0; i < royalties.length; i++) {
            _defaultRoyalties.push(royalties[i]);
        }
    }

    function _setTokenRoyalties(uint256 id, LibPart.Part[] memory royalties) internal {
        _validateRoyalties(royalties);
        delete _royalties[id];

        for (uint i = 0; i < royalties.length; i++) {
            _royalties[id].push(royalties[i]);
        }

        emit RoyaltiesSet(id, royalties);
    }

    function _validateRoyalties(LibPart.Part[] memory royalties) internal pure {
        uint256 totalValue = 0;
        for (uint i = 0; i < royalties.length; i++) {
            LibPart.Part memory currentRoyalty = royalties[i];
            require(currentRoyalty.account != address(0), "ERC721RaribleRoyalty: setting royalties to the zero address");
            require(currentRoyalty.value != 0, "ERC721RaribleRoyalty: royalty value should be positive");
            totalValue += currentRoyalty.value;
        }
        require(totalValue < _feeDenominator() / 2, "ERC721RaribleRoyalty: royalty total value should be less than 5000");
    }
}