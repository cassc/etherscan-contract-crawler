// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RENA is ERC721AQueryable, Ownable {
  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;

  uint256 public cost = 0.022 ether;
  uint256 public maxSupply = 2222;
  uint256 public fixedMintAmount = 1;

  bool public revealed = false;
  bool public presale = false;
  bool public publicsale = false;

  bytes32 public whitelistRoot;

  mapping(address => bool) public publicMintedStatus;
  mapping(address => bool) public presaleMintedStatus;

  constructor() ERC721A("Rena Official NFT", "RENA") {
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

  // ====== public ======
  function whitelistMint(bytes32[] calldata _merkleProof) public payable callerIsUser {
    // Is presale active
    require(presale, "presale is not active");
    //

    // Whitelist requires
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, whitelistRoot, leaf), "user is not whitelisted");
    //

    // Amount and status controls
    uint256 supply = totalSupply();
    require(supply + fixedMintAmount <= maxSupply, "max NFT limit exceeded");

    require(!presaleMintedStatus[msg.sender], "max NFT limit per wallet exceeded");
    //

    // Payment control
    require(msg.value >= cost * fixedMintAmount, "insufficient funds");
    //

    // Change presale minted status before mint
    presaleMintedStatus[msg.sender] = true;
    //
    
    _safeMint(msg.sender, fixedMintAmount);
  }

  function mint() public payable callerIsUser {
    // Is publicsale active
    require(publicsale, "publicsale is not active");
    //

    // Amount and status controls
    uint256 supply = totalSupply();
    require(supply + fixedMintAmount <= maxSupply, "max NFT limit exceeded");

    require(!publicMintedStatus[msg.sender], "max NFT limit per wallet exceeded");
    //

    // Payment control
    require(msg.value >= cost * fixedMintAmount, "insufficient funds");
    //

    // Change public minted status before mint
    publicMintedStatus[msg.sender] = true;
    //

    _safeMint(msg.sender, fixedMintAmount);
  }

  function ownerMint(address _to, uint256 _mintAmount) public onlyOwner {
    // Amount control
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

  // Whitelist and OG roots (presale)
  function setWhitelistRoot(bytes32 _whitelistRoot) public onlyOwner{
    whitelistRoot = _whitelistRoot;
  }
  //
  
  // Set cost
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
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

  // Withdraw funds
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}