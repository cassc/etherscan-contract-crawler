//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract NexusChronicles is ERC1155Supply, Ownable {
  string public website = "https://nexuslegends.io";
  string public name_;
  string public symbol_;
  uint256 public currentBatch;
  uint256 public mintPrice = .01 ether;

  event PermanentURI(string _value, uint256 indexed _id);

  bool public saleOpen;
  bytes32 private merkleRoot;
  bytes32 private merkleRootL;

  struct Chronicle {
    string metadataURI;
    uint256 maxSupply;
    uint256 batch;
  }

  mapping(uint256 => Chronicle) public Chronicles;
  mapping(uint256 => bool) public Frozen;

  // Address => DropGroup => Minted?
  mapping(address => mapping(uint256 => bool)) public elementalMinted;
  mapping(address => mapping(uint256 => bool)) public legendaryMinted;

  constructor(string memory _name, string memory _symbol) ERC1155("ipfs://") {
    name_ = _name;
    symbol_ = _symbol;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function name() public view returns (string memory) {
    return name_;
  }

  function symbol() public view returns (string memory) {
    return symbol_;
  }

  function ownerMint(address _to, MINT[] calldata mintData) external onlyOwner {
    for (uint256 i; i < mintData.length; i++) {
      require(!Frozen[mintData[i].id], "Frozen.");
      require(
        totalSupply(mintData[i].id) + mintData[i].qty <= Chronicles[mintData[i].id].maxSupply,
        "Max supply reached"
      );
      _mint(_to, mintData[i].id, mintData[i].qty, "");
    }
  }

  struct MINT {
    uint256 id; // ID of the Chronicle to mint
    uint256 qty; // How many
  }

  function allowlistMint(
    MINT[] calldata mintData,
    bytes32[] calldata merkleProof,
    uint256[] calldata ticket
  ) external payable callerIsUser {
    require(saleOpen, "Sale not started");
    require(mintData.length == ticket.length, "Invalid ticket.");

    uint256 totalPrice;
    for (uint256 i; i < mintData.length; i++) {
      require(!Frozen[mintData[i].id], "Frozen.");
      require(Chronicles[mintData[i].id].batch == currentBatch, "Minting not allowed.");
      require(Chronicles[mintData[i].id].maxSupply > 0, "Chronicle does not exist");
      require(
        mintData[i].qty + totalSupply(mintData[i].id) <= Chronicles[mintData[i].id].maxSupply,
        "Max supply reached"
      );

      require(mintData[i].qty <= ticket[i], "Exceeds allocation.");

      totalPrice += mintPrice * mintData[i].qty;
    }
    require(msg.value == totalPrice, "Incorrect ETH amount");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, ticket));
    require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid proof.");

    elementalMinted[msg.sender][currentBatch] = true;

    for (uint256 i; i < mintData.length; i++) {
      if (mintData[i].qty > 0) {
        _mint(msg.sender, mintData[i].id, mintData[i].qty, "");
      }
    }
  }

  function legendaryMint(
    MINT[] calldata mintData,
    bytes32[] calldata merkleProof,
    uint256[] calldata ticket
  ) external payable callerIsUser {
    require(saleOpen, "Sale not started");

    uint256 total;
    for (uint256 i; i < mintData.length; i++) {
      require(!Frozen[mintData[i].id], "Frozen.");
      require(Chronicles[mintData[i].id].batch == currentBatch, "Minting not allowed.");
      require(Chronicles[mintData[i].id].maxSupply > 0, "Chronicle does not exist");
      require(
        mintData[i].qty + totalSupply(mintData[i].id) <= Chronicles[mintData[i].id].maxSupply,
        "Max supply reached"
      );

      total += mintData[i].qty;

      require(mintData[i].qty <= ticket[i], "Invalid");
    }
    require(total % 5 == 0, "Must mint in batches of 5.");
    require(msg.value == (mintPrice * (total / 5)), "Incorrect ETH amount");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, ticket));
    require(MerkleProof.verify(merkleProof, merkleRootL, leaf), "Invalid proof.");

    legendaryMinted[msg.sender][currentBatch] = true;

    for (uint256 i; i < mintData.length; i++) {
      if (mintData[i].qty > 0) {
        _mint(msg.sender, mintData[i].id, mintData[i].qty, "");
      }
    }
  }

  /**
   * @notice Create a Chronicle.
   * @param id The token id to set this chronicle to.
   * @param chronicle ["metadataURI", mintPrice, maxSupply]
   */
  function createChronicle(uint256 id, Chronicle calldata chronicle) external onlyOwner {
    require(Chronicles[id].maxSupply == 0, "Chronicle already exists");
    Chronicles[id] = chronicle;
  }

  function updateURI(uint256 id, string calldata _uri) external onlyOwner {
    require(!Frozen[id], "Frozen.");
    require(Chronicles[id].maxSupply > 0, "Chronicle does not exist");
    Chronicles[id].metadataURI = _uri;
  }

  function updateMintPrice(uint256 price) external onlyOwner {
    mintPrice = price;
  }

  function updateMaxSupply(uint256 id, uint256 qty) external onlyOwner {
    require(!Frozen[id], "Frozen.");
    require(Chronicles[id].maxSupply > 0, "Chronicle does not exist");
    Chronicles[id].maxSupply = qty;
  }

  /**
   * @notice Toggle the sale.
   */
  function toggleSale() external onlyOwner {
    saleOpen = !saleOpen;
  }

  function setWebsite(string calldata url) external onlyOwner {
    website = url;
  }

  function setCurrentBatch(uint256 batch) external onlyOwner {
    currentBatch = batch;
  }

  /**
   * @notice Set the merkle root.
   */
  function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  /**
   * @notice Set the legendary merkle root.
   */
  function updateLegendaryMerkle(bytes32 _merkleRoot) external onlyOwner {
    merkleRootL = _merkleRoot;
  }

  // Permanently freeze metadata and minting functions.
  function freeze(uint256 id) external onlyOwner {
    Frozen[id] = true;

    emit PermanentURI(Chronicles[id].metadataURI, id);
  }

  /**
   * @notice Get the metadata uri for a specific Chronicle.
   * @param id The Chronicle to return metadata for.
   */
  function uri(uint256 id) public view override returns (string memory) {
    require(exists(id), "URI: nonexistent token");

    return string(abi.encodePacked(Chronicles[id].metadataURI));
  }

  function getChronicle(uint256 id) external view returns (Chronicle memory) {
    return Chronicles[id];
  }

  function getMintedQty(
    address addr,
    uint256 mintType // 1: elementalMinted, 2: legendaryMinted
  ) external view returns (bool) {
    if (mintType == 1) {
      return elementalMinted[addr][currentBatch];
    } else if (mintType == 2) {
      return legendaryMinted[addr][currentBatch];
    } else {
      return false;
    }
  }

  function getSalesStatus() external view returns (bool) {
    return (saleOpen);
  }

  // ** - ADMIN - ** //
  function withdrawEther(address payable _to, uint256 _amount) external onlyOwner {
    _to.transfer(_amount);
  }

  function withdrawAll(address payable _to) external onlyOwner {
    _to.transfer(address(this).balance);
  }
}