// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTBasePass is ERC721AQueryable, Ownable {
  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;

  uint256 public cost = 0.015 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxPublicMint = 4;

  bool public revealed = false;
  bool public presale = false;
  bool public publicsale = false;

  bytes32 public whitelistRoot;

  mapping(address => bool) public presaleMintedStatus;
  mapping(address => uint256) public publicMintedBalance;

  constructor() ERC721A("NFT Base Pass", "NBP") {
  }

  // ====== Settings ======
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "cannot be called by a contract");
    _;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function _startTokenId() internal pure override returns (uint256){
    return 1;
  }
  //

  // ====== Public ======
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable callerIsUser {
    // Is presale active
    require(presale, "presale is not active");
    //

    // Whitelist requires
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _mintAmount));
    require(MerkleProof.verify(_merkleProof, whitelistRoot, leaf), "user is not whitelisted");
    //

    // Amount and payments controls
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    require(!presaleMintedStatus[msg.sender], "max NFT limit exceeded per wallet");
    //

    // Change presale minted status before mint
    presaleMintedStatus[msg.sender] = true;
    //
    
    _safeMint(msg.sender, _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable callerIsUser {
    // Is publicsale active
    require(publicsale, "publicsale is not active");
    //

    // Amount controls
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    require(publicMintedBalance[msg.sender] + _mintAmount <= maxPublicMint, "max NFT limit exceeded per wallet");
    //

    // Payment control
    require(msg.value >= cost * _mintAmount, "insufficient funds");
    //

    // Increment public minted balance before mint
    publicMintedBalance[msg.sender] += _mintAmount;
    //

    _safeMint(msg.sender, _mintAmount);
  }

  function ownerMint(address _to, uint256 _mintAmount) public onlyOwner {
    // Amount Control
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    //

    _safeMint(_to, _mintAmount);
  }

  // ====== View ======
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), baseExtension))
        : "";
  }

  // ====== Only Owner ======
  function reveal() public onlyOwner {
    revealed = true;
  }

  // Whitelist Root (Presale)
  function setWhitelistRoot(bytes32 _whitelistRoot) public onlyOwner{
    whitelistRoot = _whitelistRoot;
  }
  //
  
  // Max Mint Amounts - Cost
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
  
  function setPublicMaxMint(uint256 _newAmount) public onlyOwner {
    maxPublicMint = _newAmount;
  }
  //

  // Metadata
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }
  //

  // Sale states
  function setPresale() public onlyOwner {
    presale = !presale;
  }

  function setPublicsale() public onlyOwner {
    publicsale = !publicsale;
  }
  //

  // Withdraw Funds
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}