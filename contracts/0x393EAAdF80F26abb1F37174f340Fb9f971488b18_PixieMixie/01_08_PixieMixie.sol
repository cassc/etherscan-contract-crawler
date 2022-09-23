// SPDX-License-Identifier: MIT
/*
******************************************************************
                 
                 Contract DEGEN PIGEONS GENERATOR


******************************************************************
*/
       
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


    pragma solidity ^0.8.0;
    
    contract PixieMixie  is ERC721A, Ownable, ReentrancyGuard {
        using Strings for uint256;
    
        constructor() ERC721A("pixiemixie", "pxm") {}
    
        //URI uriPrefix is the BaseURI
        string public uriPrefix = "ipfs://NA/";
        string public uriSuffix = ".json";
      
        // hiddenMetadataUri is the not reveal URI
        string public hiddenMetadataUri= "ipfs://QmStgs4ZgkbE47DcA3UU5LBAwbwaa3CvKGghssGG5w6Mtm/"; 
        
        uint256 public cost = 0.0099 ether; 
        uint256 public WLcost = 0.0099 ether;
        uint256 public maxSupply = 999;
        uint256 public wlSupply = 999;
        uint256 public nftPerAddressLimit = 3;
        uint256 public maxMintAmount = 3;
      
        bool public paused = false;
        bool public revealed = false;
        bool public onlyWhitelisted = false;
      
        bytes32 public merkleRoot = 0xbfdb99ea119cfb7c0ea3a21c8c595f9f89d101505e7013ff5e6103b82e1cb0a3;

  mapping(address => uint256) public addressMintedBalance;

  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(balanceOf(msg.sender) + _mintAmount <= maxMintAmount , "Exceeds Max mint!");
    require(!paused, "The contract is paused!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    require(!onlyWhitelisted, "Public mint is not active");
        if (msg.sender != owner()) {
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        
        require(msg.value >= cost * _mintAmount, "insufficient funds");
    }
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
     
    }

    _safeMint(msg.sender, _mintAmount);
  }

  function mintWl(uint256 _mintAmount, bytes32[] memory _merkleProof) public payable mintCompliance(_mintAmount) {
    require(msg.value >= WLcost * _mintAmount, "Insufficient funds!");
    require(onlyWhitelisted, "The presale ended!");
    require(totalSupply() + _mintAmount <= wlSupply, "The presale ended!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
        MerkleProof.verify(_merkleProof, merkleRoot, leaf),
        "Invalid Merkle Proof."
    );

    _safeMint(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address[] memory _receiver) public onlyOwner {
    for (uint256 i = 0; i < _receiver.length; i++) {
      _safeMint(_receiver[i], _mintAmount);
    }
  }


  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);
      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId+1;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
    if (revealed == false) {
      return hiddenMetadataUri;}
    string memory currentBaseURI = _baseURI();
    _tokenId = _tokenId+1;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  
  function setWLcost(uint256 _WLcost) public onlyOwner {
    WLcost = _WLcost;
  }


  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
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


  function setWlSupply(uint256 _wlSupply) public onlyOwner {
    wlSupply = _wlSupply;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}