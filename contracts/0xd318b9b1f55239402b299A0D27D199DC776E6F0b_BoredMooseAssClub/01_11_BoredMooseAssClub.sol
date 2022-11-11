// ____ ____ ____ _________
// /  __/  _ /  __/  __/  _ \
// | | /| / \|  \/|  \ | | \|
// | |_\| \_/|    |  /_| |_/|
// \____\____\_/\_\____\____/_
// / \__//  _ /  _ / ___/  __/
// | |\/|| / \| / \|    |  \
// | |  || \_/| \_/\___ |  /_
// \_/__\\____\____\____\____\
// /  _ / ___/ ___\
// | / \|    |    \
// | |-|\___ \___ |
// \_/_\\____\____/____
// /   _/ \  / \ //  _ \
// |  / | |  | | || | //
// |  \_| |_/| \_/| |_\\
// \____\____\____\____/
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DefaultOperatorFilterer721} from "./DefaultOperatorFilterer721.sol";


contract BoredMooseAssClub is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer721 {

  using Strings for uint256;

  uint256 public immutable collectionSize = 4444;
  bytes32 private mooseMerkleRoot;
  bytes32 private tpListMerkleRoot;

  bool public mooseMintActive;
  bool public tpListMintActive;
  bool public publicMintActive;

  mapping(address => uint) public hasMinted;
  mapping(address => uint) public hasMooseMinted;
  mapping(address => uint) public hasTPMinted;

  string public baseUri = "https://mooselands.io/bmac/";

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "Cannot be called by contract");
    _;
  }

  constructor() ERC721A("BoredMooseAssClub", "BMAC") {
    mooseMintActive = false;
    tpListMintActive = false;
    publicMintActive = false;
  }

  // PUBLIC
  function publicMint() public callerIsUser nonReentrant{
    require(publicMintActive, "Public mint is not active");
    require(hasMinted[msg.sender] + 1 <= 1, "Max total mint amount reached");
    require(
      totalSupply() + 1 <= collectionSize,
      "Minting over collection size"
    );
    _safeMint(msg.sender, 1);
    hasMinted[msg.sender] = hasMinted[msg.sender] + 1;
  }

  function tpListMint(bytes32[] calldata _merkleProof, uint _quantity)
  public
  callerIsUser nonReentrant
  {
    require(tpListMintActive, "TP List Sale is not active");
    require(_quantity <= 2, "Max 2");
    require(hasTPMinted[msg.sender] + _quantity <= 2, "Too many with previous mints included");

    require(
      totalSupply() + _quantity <= collectionSize,
      "Minting over collection size"
    );

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProof.verify(_merkleProof, tpListMerkleRoot, leaf) || MerkleProof.verify(_merkleProof, tpListMerkleRoot, leaf) ,
      "Invalid Proof"
    );

    _safeMint(msg.sender, _quantity);
    hasTPMinted[msg.sender] = hasTPMinted[msg.sender] + _quantity;
  }

  function mooseMint(bytes32[] calldata _merkleProof, uint _quantity)
  public
  callerIsUser nonReentrant
  {
    require(mooseMintActive, "Moose Sale not active");
    require(_quantity <= 4, "Max 4");
    require(hasMooseMinted[msg.sender] + _quantity <= 4, "Too many with previous mints included");
    require(
      totalSupply() + _quantity <= collectionSize,
      "Minting over Moose allocation"
    );

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProof.verify(_merkleProof, mooseMerkleRoot, leaf),
      "Invalid Proof"
    );
    _safeMint(msg.sender, _quantity);
    hasMooseMinted[msg.sender] = hasMooseMinted[msg.sender] + _quantity;
  }

  function ownerMint(address _to, uint _quantity) public onlyOwner(){
    require(
      totalSupply() + _quantity <= collectionSize,
      "Minting over collection size"
    );
    require(_quantity > 0, "Quantity must be greater than 0");
    _safeMint(_to, _quantity);
  }

  function togglePublicMint() public onlyOwner {
    publicMintActive = !publicMintActive;
  }

  function toggleTPListMint() public onlyOwner {
    tpListMintActive = !tpListMintActive;
  }


  function toggleMooseMint() public onlyOwner {
    mooseMintActive = !mooseMintActive;
  }

  function mooseToTpListMint() public onlyOwner {
    mooseMintActive = false;
    tpListMintActive = true;
  }

  function tpListToPublic() public onlyOwner {
    tpListMintActive = false;
    publicMintActive = true;
  }

  function setTpListMerkleRoot(bytes32 _tpListMerkleRoot) public onlyOwner {
    tpListMerkleRoot = _tpListMerkleRoot;
  }

  function setMooseMerkleRoot(bytes32 _mooseMerkleRoot) public onlyOwner {
    mooseMerkleRoot = _mooseMerkleRoot;
  }

  function setBaseUri(string memory _baseUri) public onlyOwner {
    baseUri = _baseUri;
  }

  function tokenURI(uint256 _tokenId)
  public
  view
  override
  returns (string memory)
  {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

    return string(abi.encodePacked(baseUri, _tokenId.toString(), ".json"));
  }

  function getTPListMerkleRoot() public view onlyOwner returns (bytes32) {
    return tpListMerkleRoot;
  }

  function getMooseMerkleRoot() public view onlyOwner returns (bytes32) {
    return mooseMerkleRoot;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 0;
  }

  function transferFrom(address from, address to, uint256 tokenId) 
    public 
    payable 
    override 
    onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
    }

  function safeTransferFrom(address from, address to, uint256 tokenId) 
    public 
    payable 
    override 
    onlyAllowedOperator(from) 
    {
      super.safeTransferFrom(from, to, tokenId);
    }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
    {
      super.safeTransferFrom(from, to, tokenId, data);
    }

}