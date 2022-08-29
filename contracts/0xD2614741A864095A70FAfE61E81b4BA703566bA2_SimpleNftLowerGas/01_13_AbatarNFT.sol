// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SimpleNftLowerGas is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  bytes32 public RootMerkle = 0xc7305f4e74a898a4b4acd147c5e5d030df2cf4ff8f54f7a9afab36dcf1f98a21;

  uint256 public cost = 0.1 ether;
  uint256 public privateCost = 0.09 ether;
  uint256 public maxSupply = 7777;
  uint public Steps = 0;
  uint256 public costCapsuleHolder=0 ether;
  uint256 public maxMintAmountPerTx = 10;
  uint indexHolders = 0;
  bool public paused = false;
  bool public revealed = true;
  address public CapsuleAddress = 0x31E2B813E3EAc9B96746771Ed975D9bCc671fd27;
  mapping(uint =>  address ) public Holders;
  
  constructor() ERC721("Agent", "HGM") {
    setHiddenMetadataUri("ipfs://__CID__/hidden.json");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 ,"Invalid mint amount!" );
    require(_mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }
  
  function totalSupply() public view returns (uint256) {
    return supply.current();
  }
  function mintOwner(uint256 _mintAmount) public payable onlyOwner mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    
    _mintLoop(msg.sender, _mintAmount);
  }
  function updatemerkleRoot (bytes32 _RootMerkle) public onlyOwner {
      RootMerkle = _RootMerkle;
  }
    function mintWL(uint256 _mintAmount,bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {

  require(!paused, "the contract is paused");
    
    require(Steps == 1,"is not a whitelist phase");
    bytes32 leafToCheck = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, RootMerkle, leafToCheck), "Incorrect proof");
    require(msg.value >= privateCost * _mintAmount, "insufficient funds");

    
      _mintLoop(msg.sender, _mintAmount);

    }
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(Steps != 1,"is a whitelist phase");

    if (Steps == 0)
    {
     require(ERC721(CapsuleAddress).balanceOf(msg.sender) > 0 , "you are not capsule holder");
     require(ERC721(CapsuleAddress).balanceOf(msg.sender) >= balanceOf(msg.sender) + _mintAmount, "you had exceeded the number of nft on free mint ");
    require(msg.value == costCapsuleHolder , "It is a free mint");

    }
    else if (Steps == 2)
    {
        require(msg.value == cost * _mintAmount, "insufficient funds");

    }
    
    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
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

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }
  function capsuleAddress(address _capsule) public onlyOwner {
    CapsuleAddress = _capsule;
  }
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }
  
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }
  function setSteps(uint Step) public onlyOwner {
    Steps = Step;
  }

  function withdraw() public onlyOwner {
    // This will pay HashLips 5% of the initial sale.
    // You can remove this if you want, or keep it in to support HashLips and his channel.
    // =============================================================================
    //Address wallet to get
    //(bool hs, ) = payable(0x89Daa64181A921c1E7d8677B9C1BdBb72350630F).call{value: address(this).balance * 9 / 100}("");
    //require(hs);
    // =============================================================================

    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
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
  function printHolders() public view returns (address[] memory) {
      address[] memory _holders= new address[](indexHolders);
      uint index = 0;
      for (uint256 i = 0; i < indexHolders; i++) {
       if (balanceOf(Holders[i]) > 0)
       {
        _holders[index] = Holders[i];
        index ++;
       }
    }
    return (_holders);
  }
}