// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "erc721a/contracts/ERC721A.sol";  
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract DinhoNFT is ERC721A, Ownable, AccessControl {

    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    // Create a new role identifier for the owner role
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");    

    using Strings for uint256;
    
    uint256 private immutable maxSupply;
    bool public revealed;
    string private baseURI;

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
        return            
            interfaceId == type(IAccessControl).interfaceId || 
            super.supportsInterface(interfaceId);
    }
    constructor(uint256 _maxSupply,string memory _baseUri) ERC721A("Dinho NFT", "Dinho") {        
        maxSupply = _maxSupply;
        revealed = false;
        baseURI = _baseUri;
        _setupRole(OWNER_ROLE,msg.sender);
    } 

    function totalMinted() external view returns(uint256){
        return _totalMinted();
    }
  
    function mint(address buyer,uint256 _quantity) public onlyRole(MINTER_ROLE) {
        require((getMaxSupply() - _totalMinted()) >= _quantity,"Dinho NFT: remaining token supply is not enough.");                         
        _safeMint(buyer, _quantity);
    }
   
    function setupMinterRole(address account) public onlyRole(OWNER_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }

    function setupOwnerRole(address account) public onlyRole(OWNER_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        
        return revealed 
            ? string(abi.encodePacked(_baseURI(),'series/jsons/', tokenId.toString(), '.json')) 
            : string(abi.encodePacked(_baseURI(),'jsons/generic.json'));
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newUri) public onlyRole(OWNER_ROLE){
        baseURI = newUri;
    }

    function setRevealed() public onlyRole(OWNER_ROLE) {
        revealed = true;
    }
}