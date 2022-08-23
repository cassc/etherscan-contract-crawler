// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract PuffGoNFT is ERC721Burnable, ERC721URIStorage, AccessControl {

    event NewToken(uint tokenId, address user);
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint public currentTokenId;
    string baseURI;

    constructor(string memory _name, string memory _symbol, string memory _uri) ERC721(_name, _symbol) {
        AccessControl._grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControl._setupRole(MANAGER_ROLE, msg.sender);
        baseURI = _uri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId); 
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721URIStorage, ERC721) {
        ERC721URIStorage._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage, ERC721) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function mint(address _to, uint _num) external onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < _num; i ++) {
            _mint(_to, currentTokenId + 1 + i);
            emit NewToken(currentTokenId + 1 + i, _to);
        }
        currentTokenId += _num;
    }

    function burn(uint256 _tokenId) public virtual override(ERC721Burnable) onlyRole(BURNER_ROLE) {
        ERC721Burnable.burn(_tokenId);
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyRole(MANAGER_ROLE) {
        ERC721URIStorage._setTokenURI(_tokenId, _tokenURI);
    }

    function setBaseURI(string memory _newBaseURI) external onlyRole(MANAGER_ROLE) {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseURI;
    }

    function totalSupply() external view returns(uint) {
        return currentTokenId;
    }
}