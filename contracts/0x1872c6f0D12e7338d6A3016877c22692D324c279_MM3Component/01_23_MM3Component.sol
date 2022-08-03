// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/utils/OwnerPausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract MM3Component is OwnerPausable, BaseTokenURI, ERC721Pausable, ERC721Royalty, AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => uint256) public slotIndex;

    constructor() ERC721("MM3 Component", "MM3C") BaseTokenURI("https://metadata.mm3nft.com/part/metadata/") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());

        // 5%
        _setDefaultRoyalty(0x7D7Fdd631D04a60b1d349CE55de74459e70C099D, 500);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        uint256 _slotIndex,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        slotIndex[tokenId] = _slotIndex;
        _safeMint(to, tokenId, data);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not owner nor approved");

        delete slotIndex[tokenId];
        _burn(tokenId);
    }

    function setDefaultRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function _baseURI() internal view override(BaseTokenURI, ERC721) returns (string memory) {
        return BaseTokenURI._baseURI();
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Royalty, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}