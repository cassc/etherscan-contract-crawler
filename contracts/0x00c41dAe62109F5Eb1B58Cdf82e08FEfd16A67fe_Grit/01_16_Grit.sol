// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Grit is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Pausable,
    AccessControl
{
    //events
    event MinterAdded(address account);
    event MinterRemoved(address account);
    event AdminTransferred(address oldOwner, address newOwner);
    
    using Strings for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");   
    string public baseURI ="https://tokens.gala.games/team-grit/grit/avatars/";

    constructor(address minter) ERC721("GRIT", "GRIT") {
        _grantRole(MINTER_ROLE, minter);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) 
    {
        return baseURI;
    }    

    function safeMint(address to, uint256 tokenId)
        public
        whenNotPaused
        onlyRole(MINTER_ROLE)
    {
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }  

    function addMinter(address account) 
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(MINTER_ROLE, account);
        emit MinterAdded(account);
    }

    function removeMinter(address account) 
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(MINTER_ROLE, account);
        emit MinterRemoved(account);
    }


    function transferAdmin(address oldOwner, address newOwner) 
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);        
        emit AdminTransferred(oldOwner, newOwner);
    }   

    function setBaseUri(string memory uri) 
    public 
    onlyRole(DEFAULT_ADMIN_ROLE)
    whenNotPaused
    {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function pause() 
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _pause();
    }

    function unpause()   
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _unpause();
    }
}