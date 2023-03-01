// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



contract WSB is ERC721A, Ownable{
    using Strings for uint256;
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;


//Create mint setters and price

    uint256 public cost = 0.15 ether;
    uint256 public maxSupply = 2000;
    uint256 public maxMintAmountPerTx = 3;
    uint256 public mintLimit = 3;


//Create Setters for status
    bool public paused = true;
    bool public revealed = false;

//Mappings 
    mapping (address => uint256) public whitelistedAmount;

//WL Group
    bytes32 private merkleRoot;

//Crossmint
    address public crossmintAddress;      


  constructor() ERC721A("WSB", "WSB") {
    setHiddenMetadataUri("ipfs://QmfYXQDcgr68dmk7z92Kpg6ioY2TB3HT2KyZarryHMaJvr/placeholder.json");
  }


  function devMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= maxSupply, "Max supply exceeded!");
        _safeMint(msg.sender, quantity);
    }


  function mint(uint256 quantity) public payable {
    require(!paused, "The contract is paused!");
    require(tx.origin == msg.sender,"Contracts forbidden from minting!");
    require(quantity > 0 && quantity <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + quantity <= maxSupply, "Max supply exceeded!");
    require(quantity + _numberMinted(msg.sender) <= maxSupply, "Exceeded the limit");
    require(msg.value >= cost * quantity, "Insufficient funds!");
       _safeMint(msg.sender, quantity);
  }


  function wlMint(bytes32[] memory _merkleProof, uint256 quantity) public payable {
    require(tx.origin == msg.sender,"Contracts forbidden from minting!");
    require(quantity > 0 && quantity <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + quantity <= maxSupply, "Max supply exceeded!");
    require(quantity + _numberMinted(msg.sender) <= maxSupply, "Exceeded the limit");
    require(msg.value >= cost * quantity, "Insufficient funds!");
 
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "You are not whitelisted");

       _safeMint(msg.sender, quantity);

  }


  function crossmint(uint256 quantity, address _to) public payable {
    require(cost == msg.value, "Incorrect value sent");
    require(quantity > 0 && quantity <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + quantity <= maxSupply, "Max supply exceeded!");
    require(totalSupply() + 1 <= maxSupply, "No more left");
    require(quantity + _numberMinted(msg.sender) <= maxSupply, "Exceeded the limit");
// ethereum (all)  = 0xdab1a1854214684ace522439684a145e62505233  
    require(msg.sender == crossmintAddress, "This function is for Crossmint only.");
       _safeMint(_to, quantity);
  }


  function airdropMint(uint256 quantity, address _receiver) public onlyOwner {
    require(totalSupply() + quantity <= maxSupply, "Max supply exceeded!");
    _safeMint(_receiver, quantity);
  }


///Hidden metadata unless revealed


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


/////Esential Functions


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCrossmintAddress(address _crossmintAddress) public onlyOwner {
    crossmintAddress = _crossmintAddress;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
    merkleRoot = _merkleRoot;
  }

  function getMerkleRoot() external view returns (bytes32){
    return merkleRoot;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMintLimit(uint256 _mintLimit) public onlyOwner {
    mintLimit = _mintLimit;
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



  function withdraw() public onlyOwner {
    // This will pay Safe wallet 100% of the initial sale.
    // =============================================================================
    (bool hs, ) = payable(0x9251b2B97671C859076CEDcD42aA7Ee2deddB129).call{value: address(this).balance * 100 / 100}("");
    require(hs);
    // =============================================================================

    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}