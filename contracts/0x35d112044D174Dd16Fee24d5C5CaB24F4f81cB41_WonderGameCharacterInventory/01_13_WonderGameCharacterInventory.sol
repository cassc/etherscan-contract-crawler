pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./WonderlandAccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WonderGameCharacterInventory is ERC721, WonderlandAccessControl {
    using Strings for uint256;
    string private baseURI;
    mapping(uint256 => string) private _secondaryTokenURI;

    event SecondaryTokenURIUpdated(uint256 tokenId, string oldUri, string newUri);

    constructor(
        string memory name_, 
        string memory symbol_,
       string memory __baseURI
    ) 
        ERC721(name_, symbol_)
    {
       baseURI = __baseURI;
    }

    function _character(uint256 _tokenId) internal pure returns (uint256) {
        uint256 mask = 0x00000000000000000000000000000000000000000000000FFFF0000;
        return (_tokenId & mask) >> 16;
    }

    function character(uint256 _tokenId) public view returns (uint256){
        require(_exists(_tokenId), "Token does not exist");
        return _character(_tokenId);
    }

   function setBaseURI(string memory __baseURI) public onlyRole(OWNER_ROLE) {
       baseURI = __baseURI;
   }

   function _baseURI() internal override view returns (string memory) {
       return baseURI;
   }

    function _mint(address _to, uint256 _tokenId, string memory _secondaryTokenUri, uint256 _generation) internal {
        _mint(_to, _tokenId);
        _setSecondaryTokenURI(_tokenId, _secondaryTokenUri);
    }

   function mintBatch(address _to, uint256[] memory _tokenIds,string[] memory _secondaryTokenUris, uint256 _generation) public onlyRole(MINTER_ROLE) {
       require(_tokenIds.length == _secondaryTokenUris.length, "Invalid token data");
       for(uint256 i=0;i<_tokenIds.length;i++) {
           _mint(_to, _tokenIds[i], _secondaryTokenUris[i], _generation);
       }
   }

    function mint(address _to,uint256 _tokenId,string memory _secondaryTokenUri,uint256 _generation)public onlyRole(MINTER_ROLE){
        _mint(_to,_tokenId,_secondaryTokenUri,_generation);
    }

    function _setSecondaryTokenURI(uint256 _tokenId, string memory _tokenUri) internal {
        _secondaryTokenURI[_tokenId] = _tokenUri;
    }

    function setSecondaryTokenUri(uint256 _tokenId, string memory _tokenUri) public onlyRole(OWNER_ROLE) {
        emit SecondaryTokenURIUpdated(_tokenId, _secondaryTokenURI[_tokenId], _tokenUri);
        _setSecondaryTokenURI(_tokenId, _tokenUri);
    }

    function secondaryTokenURI(uint256 _tokenId) public view returns (string memory) {
        return _secondaryTokenURI[_tokenId];
    }

    function burn(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "Only owner can burn token");
        _burn(_tokenId);
        delete _secondaryTokenURI[_tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public override (ERC721, AccessControl) view returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}