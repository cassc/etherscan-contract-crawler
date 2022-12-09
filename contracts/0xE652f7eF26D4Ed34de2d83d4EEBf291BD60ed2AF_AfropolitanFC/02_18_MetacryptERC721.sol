// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/// @title ERC721A with ERC2981 Royalties
/// @author Metacrypt (https://www.metacrypt.org/)
abstract contract MetacryptERC721 is ERC721AQueryable, ERC2981 {
    string private baseURIStorage;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURIValue,
        address _royaltyReceiver,
        uint96 _royaltyNumerator
    ) ERC721A(_name, _symbol) {
        _setDefaultRoyalty(_royaltyReceiver, _royaltyNumerator);

        baseURIStorage = _baseURIValue;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURIStorage;
    }

    function _setBaseURI(string calldata _newBaseURI) internal {
        baseURIStorage = _newBaseURI;
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
        // return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}