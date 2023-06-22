// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FourierPunks is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

  mapping(uint256 => bool) chosenPunks;
  string public _baseURIextended;
  uint public constant FOPUNK_PRICE = 69000000000000000; // 0.069 ETH hehehe
  uint public constant FOPUNK_MAX = 420; // 420 supply heh heh heh
  bool public hereWeGo = false;
  bool public metadataFixable = true;

  constructor() ERC721("FourierPunks","FOPUNKS"){
    // owner is keeping the first one, thats all
    _safeMint(owner(),0);
    setBaseURI("https://api.fopunks.com/metadata/fopunk?token_id=");
  }

  function approximate(uint256 tokenId) public payable{
        require(hereWeGo, "Minting not active");
        require(totalSupply() < FOPUNK_MAX, "No more left to mint");
        require(tokenId < FOPUNK_MAX, "Invalid ID");
        require(msg.value >= FOPUNK_PRICE, "Not enough ETH sent");
        _safeMint(msg.sender, tokenId);
  }

  function gogogo() public onlyOwner{
    require(!hereWeGo,'Already started');
    hereWeGo = true;
  }

  function stahp() public onlyOwner{
    require(hereWeGo,'Already paused');
    hereWeGo = false;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
  {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
      super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
      public
      view
      override(ERC721, ERC721URIStorage)
      returns (string memory)
  {
      return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function _baseURI() internal view virtual 
      override(ERC721)
      returns (string memory) {
      return _baseURIextended;
  }

  function setBaseURI(string memory baseURI_) public onlyOwner() {
      require(metadataFixable,'Metadata is already locked');
      _baseURIextended = baseURI_;
  }

  function setTokenURI(
        uint256 tokenId, 
        string memory tokenURI
    ) public  onlyOwner() {
        require(metadataFixable,'Metadata is already locked');
        _setTokenURI(tokenId, tokenURI);
    }

  function lockMetadata() public onlyOwner(){
    require(metadataFixable,'Metadata is already locked');
    // no turning back from this...
    metadataFixable = false;
  }

  function withdraw() public payable onlyOwner(){
    payable(msg.sender).send(address(this).balance);
  }

}