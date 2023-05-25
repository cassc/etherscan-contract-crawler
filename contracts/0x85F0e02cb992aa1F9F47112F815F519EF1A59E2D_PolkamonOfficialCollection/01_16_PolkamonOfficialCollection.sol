// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract PolkamonOfficialCollection is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721URIStorage
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _internalBaseURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) public ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());

        _internalBaseURI = baseURI;
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControlEnumerable, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory newBaseUri) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC721: must have admin role to change baseUri"
        );
        _internalBaseURI = newBaseUri;
    }

    function mint(address to, uint256 tokenId) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC721: must have minter role to mint"
        );

        _mint(to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721URIStorage, ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _internalBaseURI;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC721: must have admin role to set Token URIs"
        );
        super._setTokenURI(tokenId, _tokenURI);
    }
}