//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract M4Lands is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private supply;
  string public uriPrefix = "https://ipfs.m4rabbit.io/lands/";
  uint256 public cost = 0 ether;
  uint256 public maxSupply = 8000;
  uint256 public maxMintAmountPerTx = 10;
  bytes32 public WLMerkleRoot;
  bool public paused = true;
  bool public wl = true;

  constructor() ERC721("M4 LAND NFT", "M4LAND") {
    _mintLoop(0x65DB3fFCf5F4Da01095302b5418A6F12173658F2, 100);//reserve a bunch to the m4rabbit.eth wallet since this is a free mint we want to have some for holders who miss out
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function setWl() public {
    wl = !wl;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount, bytes32[] memory _proof) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    if (wl){
     require(MerkleProof.verify(_proof, WLMerkleRoot, leaf), "Not whitelisted");
     _mintLoop(msg.sender, _mintAmount);
    } else {
     _mintLoop(msg.sender, _mintAmount);
    }
  }

  function setSaleRoot(bytes32 _root) public onlyOwner {
    WLMerkleRoot = _root;
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner mintCompliance(_mintAmount) {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);
      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))        : "";
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function Paused() public onlyOwner {
    paused = !paused;
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}