// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface INDYA {
  function mint(address to, uint256 boxId) external;
}

contract NidyaBox is ERC721AQueryable, Ownable, ReentrancyGuard {
  string public baseURI;
  string public baseExtension = ".json";

  uint256 public cost = 0.04 ether;
  uint256 public maxPresaleMint = 2000;

  uint256 public constant maxSupply = 10000;
  uint256 public constant fixedMintAmount = 1;

  bool public presale = false;
  bool public publicsale = false;
  bool public boxStatus = false;

  address public nidyaContract;

  bytes32 public whitelistRoot;

  mapping(address => bool) public presaleMintedStatus;
  mapping(address => bool) public publicMintedStatus;

  constructor() ERC721A("Nidya Box", "NBOX") {
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

  // ==== Box Opening ====
  function openBox(uint256 boxId) external nonReentrant callerIsUser {
    // Can open box
    require(boxStatus, "box opening is closed");

    // Check if caller is the owner of the box
    address to = ownerOf(boxId);
    require(to == msg.sender, "unowned box");

    // Burn the box before mint
    _burn(boxId, true);

    // Mint the token with the given ID
    INDYA nidya = INDYA(nidyaContract);
    nidya.mint(to, boxId);
  }

  // ====== Mint Functions ======
  function whitelistMint(bytes32[] calldata _merkleProof) external payable callerIsUser {
    // Is presale active
    require(presale, "presale is not active");

    // Whitelist requires
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, whitelistRoot, leaf), "user is not whitelisted");

    // Amount controls
    uint256 supply = totalSupply();
    require(supply + fixedMintAmount <= maxPresaleMint, "max NFT limit exceeded [WL]");

    require(!presaleMintedStatus[msg.sender], "max NFT limit exceeded per wallet [WL]");
    //

    // Change minted status before mint
    presaleMintedStatus[msg.sender] = true;
    
    _safeMint(msg.sender, fixedMintAmount);
  }

  function mint() external payable callerIsUser {
    // Is publicsale active
    require(publicsale, "publicsale is not active");

    // Amount controls
    uint256 supply = totalSupply();
    require(supply + fixedMintAmount <= maxSupply, "max NFT limit exceeded");

    require(!publicMintedStatus[msg.sender], "max NFT limit exceeded per wallet");
    //

    // Payment control
    require(msg.value >= cost * fixedMintAmount, "insufficient funds");

    // Change minted status before mint
    publicMintedStatus[msg.sender] = true;

    _safeMint(msg.sender, fixedMintAmount);
  }

  function ownerMint(address _to, uint256 _mintAmount) external onlyOwner {
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
    
    string memory currentBaseURI = _baseURI();
    return currentBaseURI;
  }

  // ====== Only Owner ======
  // Merkle Root
  function setWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner{
    whitelistRoot = _whitelistRoot;
  }
  //
  
  // Set Cost
  function setCost(uint256 _newCost) external onlyOwner {
    cost = _newCost;
  }
  
  // Set Presale Limit
  function setPresaleMaxMint(uint256 _newAmount) external onlyOwner {
    maxPresaleMint = _newAmount;
  }

  // Metadata
  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
    baseExtension = _newBaseExtension;
  }
  //

  // Sale States
  function setPresale() external onlyOwner {
    presale = !presale;
  }

  function setPublicsale() external onlyOwner {
    publicsale = !publicsale;
  }
  //

  // Set Main Contract
  function setNidyaContract(address _addr) external onlyOwner {
    nidyaContract = _addr;
  }

  // Change Box Opening State
  function toggleBoxStatus() external onlyOwner {
    boxStatus = !boxStatus;
  }

  // Control is Token Exists
  function exists(uint256 id) external view returns(bool) {
    return _exists(id);
  }

  // Withdraw Funds
  function withdraw() external payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}