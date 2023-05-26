// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "./CollaborativeOwnable.sol";
import "./ERC721Enumerable.sol";
import "./IOwlToken.sol";
import "./MerkleProof.sol";
import "./ProxyRegistry.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract NightOwls is ERC721Enumerable, CollaborativeOwnable, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address;
  using Strings for uint256;

  uint256 public maxSupply = 2420;

  string public baseURI = "";
  address public proxyRegistryAddress = address(0);
  
  address public owlTokenAddress = address(0);

  uint256 public mintPrice = 50000000000000000;
  uint16 public mintLimit = 4;
  bool public mintIsActive = false;

  mapping(address => uint16) public whitelistMinted;
  bytes32 public whitelistMerkleRoot;
  uint256 public whitelistMintPrice = 50000000000000000;
  uint16 public whitelistMintLimit = 2;
  bool public whitelistMintIsActive = false;

  mapping(address => bool) public prepaidMinted;
  bytes32 public prepaidMerkleRoot;
  bool public prepaidMintIsActive = false;
  uint16 public reservedForPrepaid = 0;
  
  address public projectWithdrawAddress = address(0);
  address public developerWithdrawAddress = address(0);
  uint16 public developerPercentage = 155;

  constructor(address _proxyRegistryAddress, address _developerWithdrawAddress, address _projectWithdrawAddress) ERC721("Night Owls", "OWLS") {
    proxyRegistryAddress = _proxyRegistryAddress;
    developerWithdrawAddress = _developerWithdrawAddress;
    projectWithdrawAddress = _projectWithdrawAddress;
  }

  //
  // Public / External
  //

  function remainingForMint() public view returns (uint256) {
    uint256 ts = totalSupply();
    uint256 available = maxSupply.sub(ts.add(reservedForPrepaid));
    return available;
  }

  function mint(uint16 quantity) external payable nonReentrant {
    require(mintIsActive);
    require(quantity > 0 && quantity <= mintLimit && quantity <= remainingForMint());
    require(msg.value >= mintPrice.mul(quantity));

    uint256 ts = totalSupply();

    for (uint16 i = 0; i < quantity; i++) {
      _safeMint(_msgSender(), ts + i);
    }
  }

  function whitelistMint(bytes32[] calldata merkleProof, uint16 quantity) external payable nonReentrant {
    require(whitelistMintIsActive);
    require(quantity > 0 && quantity <= whitelistMintLimit && quantity <= remainingForMint());
    require(msg.value >= whitelistMintPrice.mul(quantity));
    
    uint16 alreadyMinted = whitelistMinted[_msgSender()];
    require(alreadyMinted < whitelistMintLimit);

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf), "1");

    uint256 ts = totalSupply();

    for (uint16 i = 0; i < quantity; i++) {
      _safeMint(_msgSender(), ts + i);
    }

    whitelistMinted[_msgSender()] = alreadyMinted + quantity;
  }

  function prepaidMint(bytes32[] calldata merkleProof, uint16 quantity) external nonReentrant {
    require(prepaidMintIsActive);
    require(quantity > 0 && quantity <= reservedForPrepaid);
    require(!prepaidMinted[_msgSender()]);

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), uint256(quantity)));
    require(MerkleProof.verify(merkleProof, prepaidMerkleRoot, leaf), "2");

    uint256 ts = totalSupply();
    require(ts.add(quantity) <= maxSupply);

    for (uint16 i = 0; i < quantity; i++) {
      _safeMint(_msgSender(), ts + i);
    }

    prepaidMinted[_msgSender()] = true;
    reservedForPrepaid = reservedForPrepaid - quantity;
  }

  // Override ERC721
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  // Override ERC721
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId));
        
    string memory __baseURI = _baseURI();
    return bytes(__baseURI).length > 0 ? string(abi.encodePacked(__baseURI, tokenId.toString(), ".json")) : '.json';
  }

  // Override ERC721
  function isApprovedForAll(address owner, address operator) override public view returns (bool) {
    if (address(proxyRegistryAddress) != address(0)) {
      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
      if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
      }
    }
    return super.isApprovedForAll(owner, operator);
  }
  
  // Override ERC721
  function transferFrom(address from, address to, uint256 tokenId) public override {
    if (owlTokenAddress != address(0)) {
      IOwlToken(owlTokenAddress).onNightOwlTransfer(from, to);
    }
    super.transferFrom(from, to, tokenId);
  }

  // Override ERC721
  function safeTransferFrom(address from, address to, uint256 tokenId) public override {
    if (owlTokenAddress != address(0)) {
      IOwlToken(owlTokenAddress).onNightOwlTransfer(from, to);
    }
    super.safeTransferFrom(from, to, tokenId);
  }

  // Override ERC721
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
    if (owlTokenAddress != address(0)) {
      IOwlToken(owlTokenAddress).onNightOwlTransfer(from, to);
    }
    super.safeTransferFrom(from, to, tokenId, data);
  }

  //
  // Collaborator Access
  //

  function setBaseURI(string memory uri) external onlyCollaborator {
    baseURI = uri;
  }

  function reduceMaxSupply(uint256 newMaxSupply) external onlyCollaborator {
    require(newMaxSupply >= 0 && newMaxSupply < maxSupply);
    require(newMaxSupply >= totalSupply());
    maxSupply = newMaxSupply;
  }

  function reduceMintPrice(uint256 newPrice) external onlyCollaborator {
    require(newPrice >= 0 && newPrice < mintPrice);
    mintPrice = newPrice;
  }

  function reduceWhitelistMintPrice(uint256 newPrice) external onlyCollaborator {
    require(newPrice >= 0 && newPrice < whitelistMintPrice);
    whitelistMintPrice = newPrice;
  }

  function airDrop(address to, uint16 quantity) external onlyCollaborator {
    require(to != address(0));
    require(quantity > 0);
    require(quantity <= remainingForMint());

    uint256 ts = totalSupply();

    for (uint16 i = 0; i < quantity; i++) {
      _safeMint(to, ts + i);
    }
  }

  function setMintIsActive(bool active) external onlyCollaborator {
    mintIsActive = active;
  }

  function setWhitelistMintIsActive(bool active) external onlyCollaborator {
    whitelistMintIsActive = active;
  }

  function setWhitelistMerkleRoot(bytes32 newRoot) external onlyCollaborator {
    whitelistMerkleRoot = newRoot;
  }

  function setPrepaidMintIsActive(bool active) external onlyCollaborator {
    prepaidMintIsActive = active;
  }

  function setPrepaidMerkleRoot(bytes32 newRoot, uint16 newReserved) external onlyCollaborator {
    require(newReserved <= maxSupply);
    prepaidMerkleRoot = newRoot;
    reservedForPrepaid = newReserved;
  }

  function setProxyRegistryAddress(address prAddress) external onlyCollaborator {
    proxyRegistryAddress = prAddress;
  }

  function setOwlTokenAddress(address newAddress) external onlyCollaborator {
    owlTokenAddress = newAddress;
  }

  function withdraw() external onlyCollaborator nonReentrant {
    uint256 balance = address(this).balance;

    uint256 developerBalance = balance.mul(developerPercentage).div(1000);
    uint256 collaboratorBalance = balance.sub(developerBalance);

    payable(projectWithdrawAddress).transfer(collaboratorBalance);
    payable(developerWithdrawAddress).transfer(developerBalance);
  }
}