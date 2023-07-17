// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TruePlebsInGoblinTown is ERC721A, Ownable {
  event Mint(address indexed _from);

  using MerkleProof for bytes32[];
  
  // State of mint
  enum MintType{ NOTSTARTED, OG, ALLOWLIST, PUBLIC }
  MintType public mintType = MintType.NOTSTARTED;
  
  uint256 public constant maxSupply = 1669;
  uint256 public constant price = 0.069 ether;
  uint256 public totalClaimedCount = 0;

  // limit per address
  uint256 public constant claimLimit = 1;
  uint256 public constant limitPerAddress = 2;
  uint256 public constant claimableTokensCount = 200;
  uint256 public partnerReserve = 50;
  uint256 public teamReserve = 20;

  // Merkle Roots 
  bytes32 private allowlistMerkleRoot;
  bytes32 private ogMerkleRoot;

  bool public isRevealed;

  address public teamAddress = 0x1703A1847c4c0109e08AA94599446770721FCCdb;
  address private partnerAddress = 0x5d6788c1609f06A2C895a198e82cFc7a15Ca0dc5;

  constructor() 
    ERC721A("True Plebs in Goblin Town", "TPIGT") {}

  // MODIFIERS
  modifier isOgsale() {
    require(mintType == MintType.OG, 'Og sale not started!');
    _;
  }

  modifier isPresale() {
    require(mintType == MintType.ALLOWLIST, 'Presale not started!');
    _;
  }

  modifier isPublicSale() {
    require(mintType == MintType.PUBLIC, 'Public sale not started!');
    _;
  }

  modifier merkleProofCheckOgs(bytes32[] calldata _merkleProof) {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, ogMerkleRoot, leaf), 'You are not OG!');
    _;
  }

  modifier merkleProofCheckAllowlist(bytes32[] calldata _merkleProof) {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf), 'You are not in allowlist');
    _;
  }

  // FUNCTIONS SETTERS
   function setMintType(MintType _type) external onlyOwner {
    mintType = _type;
  }

  function setIsRevealed(bool _isRevealed) public onlyOwner {
    isRevealed = _isRevealed;
  }

  function setCoverURI(string memory _coverURI) external onlyOwner {
    coverURI = _coverURI;
  }

  function setOgMerkleRoot(bytes32 _ogMerkleRoot) external onlyOwner {
    ogMerkleRoot = _ogMerkleRoot;
  }

  function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot) external onlyOwner {
    allowlistMerkleRoot = _allowlistMerkleRoot;
  }

  function devMint() external {
      require(1 + _numberMinted(msg.sender) <= teamReserve, "Already claimed");
      require(msg.sender == teamAddress);
      _safeMint(msg.sender, teamReserve);
      emit Mint(msg.sender);
  }

  function partnerMint() external {
      require(1 + _numberMinted(msg.sender) <= partnerReserve, "Already claimed");
      require(msg.sender == partnerAddress);
      _safeMint(msg.sender, partnerReserve);
      emit Mint(msg.sender);
  }
  
  function claim(bytes32[] calldata _merkleProof) external 
    isOgsale 
    merkleProofCheckOgs(_merkleProof) {
      require(totalSupply() + 1 <= maxSupply, "Not enough tokens left");
      require(totalClaimedCount + 1 <= claimableTokensCount, "Not enough claimable tokens left");
      require(1 + _numberMinted(msg.sender) <= claimLimit, "Already claimed");

      _safeMint(msg.sender, 1);

      totalClaimedCount++;
      emit Mint(msg.sender);
  }

  function allowlistMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable
    isPresale
    merkleProofCheckAllowlist(_merkleProof)
    {
      require(quantity > 0, 'Zero is zero!');
      require(quantity + _numberMinted(msg.sender) <= limitPerAddress, "Exceeded the limit");
      require(totalSupply() + quantity <= maxSupply, "Not enough tokens left");
      require(msg.value >= (price * quantity), "Not enough ether sent");

      _safeMint(msg.sender, quantity);
      emit Mint(msg.sender);
  }

  function publicMint(uint256 quantity) external payable isPublicSale {
    require(quantity > 0, 'Zero is zero!');
    require(quantity + _numberMinted(msg.sender) <= limitPerAddress, "Exceeded the limit");
    require(totalSupply() + quantity <= maxSupply, "Not enough tokens left");
    require(msg.value >= (price * quantity), "Not enough ether sent");
    _safeMint(msg.sender, quantity);
    emit Mint(msg.sender);
  }


  // // metadata URI
  
  string private _baseTokenURI;
  string public coverURI;

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    require(_exists(id), "Metadata: URI query for nonexistent token");
    if (!isRevealed) {
      return coverURI;
    }

    return string(abi.encodePacked(_baseTokenURI, Strings.toString(id), ".json"));
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}