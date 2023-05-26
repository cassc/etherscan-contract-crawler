//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract Template is Ownable, ERC721Enumerable, ERC721URIStorage  {

  using BitMaps for BitMaps.BitMap;
  using Strings for uint256;

  uint256 public MAX_SUPPLY;
  uint256 public price;
  bytes32 public merkleRoot;
  bool public salePaused;
  string[] public templates; //array of templates URIs - index 0 should be default template
  string private _baseTokenExtension;    
  mapping (uint256 => uint256) public tokenIdToTemplateIndex;
  mapping (address => bool) public claimed;

  BitMaps.BitMap private _isTemplateLocked;
  BitMaps.BitMap private _isTemplateRetired;

  constructor(uint256 maxSupply, uint256 initialPrice) ERC721("Template", "TMPLT") {
    salePaused = true;
    MAX_SUPPLY = maxSupply;
    price = initialPrice;
    _baseTokenExtension = '';
  }

  modifier canMint(uint256 quantity) {
    require(totalSupply() + quantity <= MAX_SUPPLY, "MINT:MAX SUPPLY REACHED");
    _;
  }

  modifier indexExists(uint256 index) {
    require(index < templates.length, "INDEX DOESNT EXIST");
    _;
  }

  // function _baseURI() internal view virtual override returns (string memory) {
  //     return _baseTokenURI;
  // }


  /************ OWNER FUNCTIONS ************/

  // function changeBaseURI(string calldata baseURI) public onlyOwner {
  //   _baseTokenURI = baseURI;
  // }

  function setMerkleRoot(bytes32 root, uint quantityToAirdrop) public onlyOwner {
    merkleRoot = root;
    MAX_SUPPLY += quantityToAirdrop;
  }
  
  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
  }

  function beginSale() public onlyOwner {
    salePaused = false;
  }

  function pauseSale() public onlyOwner {
    salePaused = true;
  }

  function ownerMint(uint256 quantity) public onlyOwner {
    require(totalSupply() + quantity <= MAX_SUPPLY, "MINT:MAX SUPPLY REACHED");
    for(uint i = 0; i < quantity; i++) {
      _mint(owner(), totalSupply());
    }
  }

  function addTemplate(string calldata templateURI) public onlyOwner {
    templates.push(templateURI);
  }

  function setTemplate(uint256 index, string calldata templateURI) public onlyOwner indexExists(index) {
    require(!_isTemplateLocked.get(index), "SET_TEMPLATE:TEMPLATE LOCKED");
    templates[index] = templateURI;
  }
  
  function setTokenExtension(string memory extension) public onlyOwner {
    _baseTokenExtension = extension;
  }      

  function lockTemplate(uint256 index) public onlyOwner indexExists(index) {
    _isTemplateLocked.set(index);
  }

  function retireTemplate(uint256 index) public onlyOwner indexExists(index) {
    require(index > 0, "RETIRE_TEMPLATE:INDEX 0");
    _isTemplateLocked.set(index); //lock by default template
    _isTemplateRetired.set(index);
  }

  /************ PUBLIC FUNCTIONS ************/

  function isTemplateLocked(uint256 index) public indexExists(index) view returns (bool) {
    return _isTemplateLocked.get(index);
  }

  function isTemplateRetired(uint256 index) public indexExists(index) view returns (bool) {
    return _isTemplateRetired.get(index);
  }

  function mint(uint256 quantity) public canMint(quantity) payable {
    require(msg.value == price * quantity, "MINT:MSG.VALUE INCORRECT");
    require(!salePaused, "MINT:SALE PAUSED");
    for (uint256 i = 0; i < quantity; i++) {
      _safeMint(msg.sender, totalSupply());
    }
  }

  function claim(bytes32[] calldata proof) public {
    require(!claimed[msg.sender], "CLAIM:ALREADY CLAIMED");
    require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "CLAIM:INVALID PROOF");
    claimed[msg.sender] = true;
    _mint(msg.sender, totalSupply());
  }

  function applyTemplate(uint256 tokenId, uint256 index) public indexExists(index) {
    require(ownerOf(tokenId) == msg.sender, "LOCK:NOT OWNER OF TOKEN");
    require(!isTemplateRetired(index), "LOCK:TEMPLATE RETIRED");
    tokenIdToTemplateIndex[tokenId] = index;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return string(abi.encodePacked(templates[tokenIdToTemplateIndex[tokenId]], tokenId.toString(), _baseTokenExtension));
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }
}