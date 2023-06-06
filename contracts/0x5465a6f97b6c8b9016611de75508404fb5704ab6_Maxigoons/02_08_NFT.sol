//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./ERC721a.sol";

abstract contract NFT is ERC721a, VRFConsumerBase {
  struct Sale {
    uint256 unitPrice;
    uint256 maxAmount;
    bytes32 treeRoot;
  }

  event OwnerUpdated(address indexed user, address indexed newOwner);

  event Revealed(uint256 seed, bytes32 requestId);

  bool public enabled;

  address public owner;

  address public vault;

  string public contentId;

  string public provenance;

  uint256 public maxSupply;

  uint256 public maxPerWallet;

  uint256 public reserveAmount;

  uint256 public seed;

  uint256 public level;

  uint256 public vrfFee = 2 * 10**18;

  bytes32 public vrfHash =
    0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;

  Sale[] public sales;

  mapping(uint256 => mapping(address => uint256)) public balanceOfSale;

  constructor(
    uint256 _maxSupply,
    uint256 _reserveAmount,
    uint256 _maxPerWallet,
    string memory _contentId,
    string memory _provenance,
    address _vault,
    address vrfCoordinator,
    address linkToken
  ) VRFConsumerBase(vrfCoordinator, linkToken) {
    maxSupply = _maxSupply;
    reserveAmount = _reserveAmount;
    maxPerWallet = _maxPerWallet;
    contentId = _contentId;
    provenance = _provenance;
    vault = _vault;

    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "401");
    _;
  }

  function updateOwner(address newOwner) external onlyOwner {
    owner = newOwner;

    emit OwnerUpdated(msg.sender, newOwner);
  }

  function setVRF(uint256 fee, bytes32 _hash) external onlyOwner {
    vrfFee = fee;
    vrfHash = _hash;
  }

  function setSale(
    uint256 index,
    uint256 unitPrice,
    uint256 maxAmount,
    bytes32 treeRoot
  ) external onlyOwner {
    require(index <= sales.length, "422");

    if (index == sales.length) {
      // Create
      sales.push(Sale(unitPrice, maxAmount, treeRoot));
    } else {
      // Update
      Sale storage sale = sales[index];

      sale.unitPrice = unitPrice;
      sale.maxAmount = maxAmount;
      sale.treeRoot = treeRoot;
    }
  }

  function setLevel(uint256 index) external onlyOwner {
    require(sales.length > 0 && index < sales.length, "422");

    level = index;
  }

  function enable() external onlyOwner {
    enabled = true;
  }

  function disable() external onlyOwner {
    enabled = false;
  }

  function reveal() public onlyOwner returns (bytes32) {
    require(seed == 0, "403");
    require(LINK.balanceOf(address(this)) >= vrfFee, "402");

    return requestRandomness(vrfHash, vrfFee);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal
    override
  {
    require(seed == 0, "403");

    seed = randomness;

    emit Revealed(randomness, requestId);
  }

  function hasLevel(
    uint256 index,
    address candidate,
    bytes32[] memory proof
  ) public view returns (bool) {
    require(index < sales.length, "404");

    Sale memory sale = sales[index];

    return
      MerkleProof.verify(
        proof,
        sale.treeRoot,
        keccak256(abi.encodePacked(candidate))
      );
  }

  function withdraw() external onlyOwner {
    payable(vault).transfer(address(this).balance);
  }

  function baseURI() public view virtual returns (string memory) {
    return string(abi.encodePacked("ipfs://", contentId, "/metadata/"));
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_ownerOf(id) != address(0), "404");

    uint256 metaId;

    if (seed == 0) {
      // Conceal
      metaId = 0;
    } else {
      // Reveal
      metaId = _metadataOf(id);
    }

    return string(abi.encodePacked(baseURI(), toString(metaId), ".json"));
  }

  function contractURI() public view virtual returns (string memory) {
    return string(abi.encodePacked(baseURI(), "contract.json"));
  }

  function reserve(uint256 amount) public virtual onlyOwner {
    require(seed == 0, "403");
    require(totalSupply + amount <= maxSupply, "403");
    require(balanceOf[vault] + amount <= reserveAmount, "403");

    _safeMintBatch(vault, amount);
  }

  function _metadataOf(uint256 id) internal view returns (uint256) {
    uint256 seed_ = seed;

    uint256 max = maxSupply;

    uint256[] memory idToMeta = new uint256[](max);

    for (uint256 i = 0; i < max; i++) {
      idToMeta[i] = i;
    }

    for (uint256 i = 0; i < max - 1; i++) {
      uint256 j = i + (uint256(keccak256(abi.encode(seed_, i))) % (max - i));

      (idToMeta[i], idToMeta[j]) = (idToMeta[j], idToMeta[i]);
    }

    // Token ID starts at #1
    return idToMeta[id - 1] + 1;
  }

  function _sell(
    uint256 index,
    uint256 amount,
    uint256 value,
    bytes32[] memory proof
  ) internal {
    Sale memory sale = sales[index];

    bool isProtected = sale.treeRoot != 0;

    // Unauthorized
    require(enabled && sales.length > 0, "401");

    if (isProtected) {
      require(hasLevel(index, msg.sender, proof), "401");
    }

    // Payment required
    require(amount * sale.unitPrice == value, "402");

    // Forbidden
    require(index <= level, "403");
    require(balanceOf[msg.sender] + amount <= maxPerWallet, "403");
    require(totalSupply + amount <= maxSupply, "403");

    if (isProtected) {
      balanceOfSale[index][msg.sender] += amount;

      require(balanceOfSale[index][msg.sender] <= sale.maxAmount, "403");
    } else {
      // Open sale
      // Trick `sale.maxAmount` becomes `maxPerTx`
      require(amount <= sale.maxAmount, "403");
    }

    _safeMintBatch(msg.sender, amount);
  }
}