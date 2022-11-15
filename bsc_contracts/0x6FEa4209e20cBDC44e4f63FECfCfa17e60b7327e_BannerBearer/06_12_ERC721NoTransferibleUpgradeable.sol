// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract ERC721NoTransferibleUpgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    //============= ERRORS =============//
    error NotTransferible();

    //============= METADATA VARIABLES =============//
    string private _name;
    string private _symbol;
    uint256 public totalSupply;

    //============= MAPPINGS =============//
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => string) private _tokenURIs;

    uint256[50] private __gap;

    function __ERC721NoTransferible_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __ERC721NoTransferible_init_unchained(name_, symbol_);
    }

    function __ERC721NoTransferible_init_unchained(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _tokenURIs[tokenId];
    }

    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance)
    {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address owner)
    {
        return _owners[tokenId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        revert NotTransferible();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        revert NotTransferible();
    }

    function approve(address approved, uint256 tokenId) public virtual {
        revert NotTransferible();
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        revert NotTransferible();
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        revert NotTransferible();
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {
        revert NotTransferible();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        unchecked {
            _balances[to] += 1;
        }
        totalSupply += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _setTokenURI(uint256 tokenId, string calldata uri)
        internal
        virtual
    {
        _tokenURIs[tokenId] = uri;
    }
}