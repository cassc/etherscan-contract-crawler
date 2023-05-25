// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * The CozyPenguin NFT contract.
 *
 * This contract is designed to operate in phases. We store a merkle tree
 * containing hashed tuples of (address, phase, max tokens). This tree ensures
 * that during the phased launch only folks allowed to mint during the current
 * phase can mint.
 *
 * After the phased launch the contract enters an on sale period where anyone
 * is allowed to mint.
 *
 * When we release the NFT, we leverage one Chainlink VRF call to generate a
 * random offset. We then will internally modify our NFT metadata files to
 * incorporate this random offset before storing it on chain.
 *
 * This means that after release we ensure that token #1 maps to an NFT named
 * #1 despite the image it links to being set to (1 + randomOffset % 10000).
 * The image base URI is not modifiable after release so it serves as our
 * provenance. We cannot reorder the images to benefit ourselves.
 *
 * That being said, we acknowledge that this does pose the risk of us
 * maliciously modifying the metadata files post release and before we lock
 * down the contract. We accept this risk because doing so is transparent and
 * anyone can verify that we performed the mapping correctly.
 *
 * Once the NFT is released and appropriately mapped, the contract will be
 * locked to prevent any and all tampering forever.
 */
contract CozyPenguin is ERC721, IERC721Enumerable, VRFConsumerBase, Ownable {
  using Strings for uint;

  string private constant NAME = "Cozy Penguin";
  string private constant SYMBOL = "CZPG";

  string public imageBaseUri;
  string public metadataBaseUri;
  string public unknownTokenUri;

  uint public maxPhase;
  uint public immutable maxTokens;
  uint public maxTokensPerUser;

  bytes32 public merkleRoot;
  mapping(address => uint) public numClaimedByUser;

  // A safety net to confirm addresses set properly
  address public immutable linkAddress;
  address public immutable vrfCoordinatorAddress;
  bytes32 public vrfKeyHash;
  uint public vrfFee;

  uint public totalTokenSupply;
  uint public randomOffset;
  uint public phase;

  bool public randomized;
  bool public revealed;
  bool public locked;

  event PhaseUpdated(uint phase);

  constructor(
    uint _maxPhase,
    uint _maxTokens,
    uint _maxTokensPerUser,
    address _vrfCoordinator,
    address _link,
    bytes32 _vrfKeyHash,
    uint _vrfFee
  ) ERC721(NAME, SYMBOL) VRFConsumerBase(_vrfCoordinator, _link) {
    maxPhase = _maxPhase;
    maxTokens = _maxTokens;
    maxTokensPerUser = _maxTokensPerUser;
    vrfCoordinatorAddress = _vrfCoordinator;
    linkAddress = _link;
    vrfKeyHash = _vrfKeyHash;
    vrfFee = _vrfFee;
  }

  // ----------- Setters -----------

  function setVrfSettings(bytes32 _vrfKeyHash, uint _vrfFee) external onlyOwner {
    vrfKeyHash = _vrfKeyHash;
    vrfFee = _vrfFee;
  }

  function setImageBaseUri(string calldata uri) external onlyOwner notLocked {
    require(!randomized, "Cannot set new image URI after random offset determined");
    imageBaseUri = uri;
  }

  function setMetadataBaseUri(string calldata uri) external onlyOwner notLocked {
    metadataBaseUri = uri;
  }

  function setUnknownTokenUri(string calldata uri) external onlyOwner notLocked {
    unknownTokenUri = uri;
  }

  function setPhase(uint _phase) external onlyOwner notLocked {
    require(_phase <= maxPhase, "Cannot set phase greater than max phase");
    phase = _phase;
    emit PhaseUpdated(_phase);
  }

  function setMaxPhase(uint _maxPhase) external onlyOwner notLocked {
    maxPhase = _maxPhase;
  }

  function setMaxTokensPerUser(uint _maxTokensPerUser) external onlyOwner notLocked {
    require(_maxTokensPerUser <= maxTokens, "Max tokens per user too large");
    maxTokensPerUser = _maxTokensPerUser;
  }

  function setMerkleRoot(bytes32 root) external onlyOwner notLocked {
    merkleRoot = root;
  }

  function setRevealed(bool _revealed) external onlyOwner notLocked {
    bytes memory testMetadataBaseUri = bytes(metadataBaseUri);
    require(testMetadataBaseUri.length != 0, "Cannot reveal when Metadata Base URI is empty");
    require(phase == maxPhase, "Cannot reveal when contract is not at max phase");
    require(randomized, "Cannot reveal when a random offset has not been generated");
    revealed = _revealed;
  }

  // ----------- Getters -----------

  function isValidProof(
    bytes32[] calldata _proof,
    uint _userPhase,
    uint _userMaxTokens
  ) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encode(msg.sender, _userPhase, _userMaxTokens));
    return MerkleProof.verify(_proof, merkleRoot, leaf);
  }

  function getNumClaimedByUser(address user) external view returns (uint) {
    return numClaimedByUser[user];
  }

  // ----------- ERC721 ---------------

  function tokenURI(uint tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (!revealed) {
      return unknownTokenUri;
    }

    return string(abi.encodePacked(metadataBaseUri, tokenId.toString(), ".json"));
  }

  function _mintMultiple(uint numberOfTokens, address recipient) private {
    for (uint i = 0; i < numberOfTokens; i += 1) {
      uint index = totalTokenSupply;
      if (index < maxTokens) {
        totalTokenSupply += 1;
        numClaimedByUser[recipient] += 1;
        _safeMint(recipient, index + 1);
      }
    }
  }

  function mintPresale(
    uint numberOfTokens,
    uint userPhase,
    uint userMaxTokens,
    bytes32[] calldata proof
  ) external {
    require(totalTokenSupply + numberOfTokens <= maxTokens, "Not enough tokens");
    require(phase != maxPhase, "Presale is over");
    require(userPhase <= phase, "Phase is not open");

    require(isValidProof(proof, userPhase, userMaxTokens), "Proof was invalid");

    uint claimed = numClaimedByUser[msg.sender];
    require(claimed + numberOfTokens <= userMaxTokens, "Minting more than allowed");

    _mintMultiple(numberOfTokens, msg.sender);
  }

  function mint(uint numberOfTokens) external {
    require(totalTokenSupply + numberOfTokens <= maxTokens, "Not enough tokens");
    require(phase == maxPhase, "Sale has not begun");

    uint claimed = numClaimedByUser[msg.sender];
    require(claimed + numberOfTokens <= maxTokensPerUser, "Minting more than allowed");

    _mintMultiple(numberOfTokens, msg.sender);
  }

  // -------- IERC721Enumerable -----------

  function totalSupply() external view override returns (uint) {
    return totalTokenSupply;
  }

  function tokenOfOwnerByIndex(address owner, uint index) external view override returns (uint) {
    require(index < ERC721.balanceOf(owner), "Index out of range");
    uint foundTokens = 0;
    uint batchSize = 100;
    uint start = 1;
    uint tokenIdUpperBound = totalTokenSupply + 1;
    uint end = (start + batchSize) > tokenIdUpperBound ? tokenIdUpperBound : (start + batchSize);
    do {
      TokenEnumerationResult memory result = tokensOfOwnerInRange(owner, start, end);
      if (index - foundTokens < result.foundCount) {
        return result.tokenIds[index - foundTokens];
      }
      foundTokens += result.foundCount;
      start = result.lastIndex;
      end = (start + batchSize) > tokenIdUpperBound ? tokenIdUpperBound : (start + batchSize);
    } while (end <= tokenIdUpperBound);

    require(false, "Not enough owned tokens were found to reach index");
    return 0;
  }

  struct TokenEnumerationResult {
    uint lastIndex;
    uint foundCount;
    uint[100] tokenIds;
  }

  function tokensOfOwnerInRange(
    address owner,
    uint start,
    uint end
  ) public view returns (TokenEnumerationResult memory result) {
    require(start < end && end <= totalTokenSupply + 1, "Invalid range");
    for (uint tokenId = start; tokenId < end; tokenId += 1) {
      if (owner == ERC721.ownerOf(tokenId)) {
        result.tokenIds[result.foundCount] = tokenId;
        result.foundCount += 1;
        if (result.foundCount == 100) {
          result.lastIndex = tokenId + 1;
          return result;
        }
      }
    }
    result.lastIndex = end;
  }

  function tokenByIndex(uint index) external view override returns (uint) {
    require(index < totalTokenSupply, "Invalid index");
    return index + 1;
  }

  // -------- Random Offset -----------

  function generateRandomOffset() external onlyOwner {
    require(!randomized, "Random offset already set");
    requestRandomness(vrfKeyHash, vrfFee);
  }

  function fulfillRandomness(bytes32, uint randomness) internal override {
    require(!randomized, "Random offset already set");
    randomOffset = randomness % maxTokens;
    randomized = true;
  }

  // ------------ Locking -------------

  function lock() external onlyOwner {
    require(revealed, "Project not yet revealed");

    locked = true;
  }

  modifier notLocked() {
    require(!locked, "Contract is locked");
    _;
  }

  // ------------ Withdraw -------------

  function withdrawLink(address _link) external onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(_link);
    bool succeed = link.transfer(msg.sender, link.balanceOf(address(this)));
    require(succeed, "Transfer failed");
  }
}