// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "./access/AdminControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract BushidoRoyale is ERC721A, AdminControl, VRFConsumerBase, Ownable {
  using Strings for uint256;
  using MerkleProof for bytes32[];

  // General mint settings
  uint256 public constant maxSupply = 7777;
  uint256 public currentMaxSupply = 3000;
  uint256 public maxPerTransaction = 20;
  bool public letContractMint = false;

  // Phase 1: Free mints
  uint256 public freeMintStartTimestamp;
  bytes32 public rootMintFree;
  mapping (address => uint256) public freeMints;
  bool public freeMintsActive = false;

  // Phase 2: Allowlist Sale
  uint256 public presaleStartTimestamp;
  bytes32 public root;
  mapping (address => uint256) public presaleMints;
  uint256 public presalePrice = 0.09 ether;
  bool public presaleActive = false;

  // Phase 3: Public Sale
  uint256 public saleStartTimestamp;
  uint256 public salePrice = 0.09 ether;
  bool public saleActive = false;

  // Owner mints
  uint256 public ownerMints;
  uint256 public ownerMintAllowance = 200;

  // Chainlink & Randomness
  // Assume three mint stages (0, 1, 2) requiring hashes and offsets
  bytes32 private s_keyHash;
  uint256 private s_fee;
  mapping (uint256 => bytes32) public provenanceHashes;
  mapping (uint256 => uint256) public offsets;
  mapping (uint256 => bool) public offsetsRequested;
  mapping (uint256 => uint256) public stageSizes;
  mapping (bytes32 => uint256) public offsetRequestIds;

  // Metadata
  string public tokenBaseURI;
  string private notRevealedUri;
  bool private revealed = false;

  // Addresses
  address private payableAddressTeam;
  address private payableAddressDev;

  constructor(
    bytes32 merkleroot, bytes32 _rootMintFree, string memory uri,
    address vrfCoordinator, address link, bytes32 keyhash, uint256 fee,
    address _payableAddressTeam, address _payableAddressDev
  ) ERC721A("Bushido Royale", "BROYALE") VRFConsumerBase(vrfCoordinator, link) {
    root = merkleroot;
    rootMintFree = _rootMintFree;
    notRevealedUri = uri;
    s_keyHash = keyhash;
    s_fee = fee;
    payableAddressTeam = _payableAddressTeam;
    payableAddressDev = _payableAddressDev;
  }

  // Mint Functions

  function mintPresale(uint256 _allowance, bytes32[] calldata _proof, uint256 _tokenQuantity) external payable {
    require(presaleActive, "PRESALE NOT ACTIVE");
    require(block.timestamp >= presaleStartTimestamp, "PRESALE NOT ACTIVE");
    require(_proof.verify(root, keccak256(abi.encodePacked(msg.sender, _allowance))), "NOT ON ALLOWLIST");
    require(presaleMints[msg.sender] + _tokenQuantity <= _allowance, "MINTING MORE THAN ALLOWED");
    require(_tokenQuantity * presalePrice <= msg.value, "INCORRECT PAYMENT AMOUNT");

    uint256 currentSupply = totalSupply();
    require(_tokenQuantity + currentSupply <= currentMaxSupply, "NOT ENOUGH LEFT IN STOCK");

    _mint(msg.sender, _tokenQuantity);

    presaleMints[msg.sender] += _tokenQuantity;
  }

  function mintFree(uint256 _allowance, bytes32[] calldata _proof, uint256 _tokenQuantity) external {
    require(freeMintsActive, "FREE MINT NOT ACTIVE");
    require(block.timestamp >= freeMintStartTimestamp, "FREE MINT NOT ACTIVE");
    require(_proof.verify(rootMintFree, keccak256(abi.encodePacked(msg.sender, _allowance))), "NOT ON FREE MINT ALLOWLIST");
    require(freeMints[msg.sender] + _tokenQuantity <= _allowance, "MINTING MORE THAN ALLOWED");

    uint256 currentSupply = totalSupply();
    require(_tokenQuantity + currentSupply <= currentMaxSupply, "NOT ENOUGH LEFT IN STOCK");

    _mint(msg.sender, _tokenQuantity);

    freeMints[msg.sender] += _tokenQuantity;
  }

  function mint(uint256 _tokenQuantity) external payable {
    if (!letContractMint) {
      require(msg.sender == tx.origin, "CONTRACT NOT ALLOWED TO MINT");
    }

    require(saleActive, "SALE NOT ACTIVE");
    require(block.timestamp >= saleStartTimestamp, "SALE NOT ACTIVE");
    require(_tokenQuantity <= maxPerTransaction, "MINTING MORE THAN ALLOWED IN A SINGLE TRANSACTION");
    require(_tokenQuantity * salePrice <= msg.value, "INCORRECT PAYMENT AMOUNT");

    uint256 currentSupply = totalSupply();

    require(_tokenQuantity + currentSupply <= currentMaxSupply, "NOT ENOUGH LEFT IN STOCK");

    _mint(msg.sender, _tokenQuantity);
  }

  function ownerMint(address _to, uint256 _tokenQuantity) external onlyAdmin {
    uint256 currentSupply = totalSupply();
    require(_tokenQuantity + ownerMints <= ownerMintAllowance, "MINTING MORE THAN ALLOWED");
    require(_tokenQuantity + currentSupply <= maxSupply, "NOT ENOUGH LEFT IN STOCK");

    _mint(_to, _tokenQuantity);

    ownerMints += _tokenQuantity;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");

    if (revealed == false) {
      return notRevealedUri;
    } else {
      return string(abi.encodePacked(tokenBaseURI, tokenId.toString()));
    }
  }

  // Chainlink Randomness

  function generateRandomOffset(uint256 _mintStage, uint256 _stageSize) public onlyAdmin {
    require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK to pay fee");
    require(!offsetsRequested[_mintStage], "Already generated random offset");
    bytes32 requestId = requestRandomness(s_keyHash, s_fee);
    offsetRequestIds[requestId] = _mintStage;
    stageSizes[_mintStage] = _stageSize;
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    uint256 mintStage = offsetRequestIds[requestId];
    // transform the result to a number between 1 and the size of the stage inclusively
    uint256 newOffset = (randomness % stageSizes[mintStage]) + 1;
    offsets[mintStage] = newOffset;
    offsetsRequested[mintStage] = true;
  }

  // Admin Configuration

  function setFreeMints(bool _freeMintStatus) external onlyAdmin {
    freeMintsActive = _freeMintStatus;
  }

  function setPresale(bool _presaleStatus) external onlyAdmin {
    presaleActive = _presaleStatus;
  }

  function setSale(bool _saleStatus) external onlyAdmin {
    saleActive = _saleStatus;
  }

  function setURIStatus(bool _revealed, string calldata _tokenBaseURI) external onlyAdmin {
    require(bytes(_tokenBaseURI).length > 0, "_tokenBaseURI is empty");
    revealed = _revealed;
    tokenBaseURI = _tokenBaseURI;
  }

  function setRoot(bytes32 _root) external onlyAdmin {
    require(_root.length > 0, "_root is empty");
    root = _root;
  }

  function setRootMintFree(bytes32 _root) external onlyAdmin {
    require(_root.length > 0, "_root is empty");
    rootMintFree = _root;
  }

  function setMaxPerTransaction(uint256 _maxPerTransaction) external onlyAdmin {
    require(_maxPerTransaction > 0, "maxPerTransaction should be positive");
    maxPerTransaction = _maxPerTransaction;
  }

  function setPrice(uint _salePrice) external onlyAdmin {
    salePrice = _salePrice;
  }

  function setPresalePrice(uint _presalePrice) external onlyAdmin {
    presalePrice = _presalePrice;
  }

  function setLetContractMint(bool _letContractMint) external onlyAdmin {
    letContractMint = _letContractMint;
  }

  function setOwnerMintAllowance(uint256 _ownerMintAllowance) external onlyAdmin {
    ownerMintAllowance = _ownerMintAllowance;
  }

  function setCurrentMaxSupply(uint256 _currentMaxSupply) external onlyAdmin {
    require(_currentMaxSupply <= maxSupply, "REQUESTED SUPPLY TOO HIGH");
    currentMaxSupply = _currentMaxSupply;
  }

  function setProvenanceHash(uint256 _mintStage, bytes32 _provenanceHash) external onlyAdmin {
    provenanceHashes[_mintStage] = _provenanceHash;
  }

  function setFreeMintStartTimestamp(uint256 _freeMintStartTimestamp) external onlyAdmin {
    require(_freeMintStartTimestamp > 0);
    freeMintStartTimestamp = _freeMintStartTimestamp;
  }

  function setPresaleStartTimestamp(uint256 _presaleStartTimestamp) external onlyAdmin {
    require(_presaleStartTimestamp > 0);
    presaleStartTimestamp = _presaleStartTimestamp;
  }

  function setSaleStartTimestamp(uint256 _saleStartTimestamp) external onlyAdmin {
    require(_saleStartTimestamp > 0);
    saleStartTimestamp = _saleStartTimestamp;
  }

  function withdraw() external onlyAdmin {
    Address.sendValue(payable(payableAddressDev), address(this).balance * 2 / 10);
    Address.sendValue(payable(payableAddressTeam), address(this).balance);
  }

  function withdrawTokens(IERC20 token) public onlyAdmin {
		require(address(token) != address(0));
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}

  // Required Overrides
  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
    return interfaceId == type(IAccessControl).interfaceId ||
           interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
           interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
           interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  receive() external payable {}
}