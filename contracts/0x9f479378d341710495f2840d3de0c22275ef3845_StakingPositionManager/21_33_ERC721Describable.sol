// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./IERC721Describable.sol";
import "./IERC721Descriptor.sol";

abstract contract ERC721Describable is IERC721Describable, ERC721 {

    address private $descriptor;

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721Describable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function descriptor() external override view returns (address) {
        return $descriptor;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        IERC721Descriptor _descriptor = IERC721Descriptor($descriptor);
        require(address(_descriptor) != address(0), 'ERC721Describable: MISSING_DESCRIPTOR');
        return _descriptor.tokenURI(tokenId, _tokenURIData(tokenId));
    }

    function _updateDescriptor(address newDescriptor) internal virtual {
        require(newDescriptor != address(0), 'ERC721Describable: INVALID_DESCRIPTOR');
        emit DescriptorUpdate($descriptor, newDescriptor, _msgSender());
        $descriptor = newDescriptor;
    }

    function _tokenURIData(uint256 tokenId) internal virtual view returns (bytes memory);
}