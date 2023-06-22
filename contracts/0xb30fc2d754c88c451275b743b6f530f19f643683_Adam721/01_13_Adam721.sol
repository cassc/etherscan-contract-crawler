// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./AccessControlInitializer.sol";
import "./IAdam721.sol";


contract Adam721 is ERC721, AccessControl, AccessControlInitializer, IAdam721 {

    event ChangeBaseTokenURI(address indexed operator, string newValue);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant BASE_TOKEN_URI_SETTER_ROLE = keccak256("BASE_TOKEN_URI_SETTER_ROLE");

    string private _baseTokenURI;
    mapping (uint256 => string) private _tokenURIs;

    constructor (string memory name, string memory symbol, string memory baseTokenURI, bytes32[] memory roles, address[] memory addresses)
        ERC721(name, symbol)
    {
        _setBaseTokenURI(baseTokenURI);
        _setupRoleBatch(roles, addresses);
    }

    function burn(uint256 tokenId) external virtual override onlyRole(BURNER_ROLE) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Adam721: caller is not owner nor approved");
        // tokenId's existence is checked in ERC721::_burn(uint256)
        _burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
            // not emit ChangeTokenURI on burn
        }
    }

    function gracefulOwnerOf(uint256 tokenId) external view virtual override returns (address) {
        if (_exists(tokenId)) {
            return ownerOf(tokenId);
        }
        return address(0);
    }

    function safeMint(address to, uint256 tokenId, bytes memory data) external virtual override onlyRole(MINTER_ROLE) {
        // to's existence and tokenId's existence is checked in ERC721::_mint(address,uint256) via ERC721::_safeMint(address,uint256,bytes)
        _safeMint(to, tokenId, data);
    }

    function setBaseTokenURI(string memory newValue) external virtual onlyRole(BASE_TOKEN_URI_SETTER_ROLE) {
        _setBaseTokenURI(newValue);
    }

    function setTokenURI(uint256 tokenId, string memory newValue) external virtual override onlyRole(MINTER_ROLE) {
        // tokenId's existence is checked in _setTokenURI(uint256,string)
        _setTokenURI(tokenId, newValue);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721, AccessControl)
        returns (bool)
    {
        return interfaceId == type(IAdam721).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, IERC721Metadata) returns (string memory) {
        require(_exists(tokenId), "Adam721: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _setBaseTokenURI(string memory newValue) internal virtual {
        _baseTokenURI = newValue;
        emit ChangeBaseTokenURI(_msgSender(), newValue);
    }

    function _setTokenURI(uint256 tokenId, string memory newValue) internal virtual {
        require(_exists(tokenId), "Adam721: URI set of nonexistent token");
        _tokenURIs[tokenId] = newValue;
        emit ChangeTokenURI(_msgSender(), tokenId, newValue);
    }
}