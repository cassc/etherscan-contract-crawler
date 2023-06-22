// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

/// @author no-op.eth (nft-lab.xyz)
/// @title Frnds Club
contract Frnds is ERC721A, PaymentSplitter, Ownable {
  /** Maximum number of tokens per tx */
  uint256 public constant MAX_TX = 10;
  /** Maximum amount of tokens in collection */
  uint256 public constant MAX_SUPPLY = 6556;
  /** Price per token */
  uint256 public cost = 0.038 ether;
  /** Base URI */
  string public baseURI;

  /** Merkle tree for whitelist */
  bytes32 public merkleRoot;
  /** Whitelist max per wallet */
  uint256 public constant MAX_PER_WHITELIST = 5;

  /** Public sale state */
  bool public saleActive = false;
  /** Presale state */
  bool public presaleActive = false;

  /** Notify on sale state change */
  event SaleStateChanged(bool _val);
  /** Notify on presale state change */
  event PresaleStateChanged(bool _val);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 _val);

  constructor(
    string memory _name, 
    string memory _symbol, 
    address[] memory _shareholders, 
    uint256[] memory _shares
  ) ERC721A(_name, _symbol) PaymentSplitter(_shareholders, _shares) {}

  /// @notice Returns the base URI
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /// @notice Checks if an address is whitelisted
  /// @param _addr Address to check
  /// @param _proof Merkle proof
  function isWhitelisted(address _addr, bytes32[] calldata _proof) public view returns (bool) {
    bytes32 _leaf = keccak256(abi.encodePacked(_addr));
    return MerkleProof.verify(_proof, merkleRoot, _leaf);
  }

  /// @notice Sets public sale state
  /// @param _val New sale state
  function setSaleState(bool _val) external onlyOwner {
    saleActive = _val;
    emit SaleStateChanged(_val);
  }

  /// @notice Sets presale state
  /// @param _val New presale state
  function setPresaleState(bool _val) external onlyOwner {
    presaleActive = _val;
    emit PresaleStateChanged(_val);
  }

  /// @notice Sets the whitelist
  /// @param _val Root
  function setWhitelist(bytes32 _val) external onlyOwner {
    merkleRoot = _val;
  }

  /// @notice Sets the price
  /// @param _val New price
  function setCost(uint256 _val) external onlyOwner {
    cost = _val;
  }

  /// @notice Sets the base metadata URI
  /// @param _val The new URI
  function setBaseURI(string calldata _val) external onlyOwner {
    baseURI = _val;
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param _amt The amount to reserve
  function reserve(uint256 _amt) external onlyOwner {
    _mint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in presale
  /// @param _amt The number of tokens to mint
  /// @param _proof Merkle proof
  /// @dev Must send cost * amt in ETH
  function preMint(uint256 _amt, bytes32[] calldata _proof) external payable {
    require(presaleActive, "Presale is not yet active.");
    require(isWhitelisted(msg.sender, _proof), "Address is not whitelisted.");
    require(_numberMinted(msg.sender) + _amt <= MAX_PER_WHITELIST, "Amount of tokens exceeds whitelist limit.");
    require(totalSupply() + _amt <= MAX_SUPPLY, "Amount exceeds supply.");
    require(cost * _amt == msg.value, "ETH sent not equal to cost.");

    _safeMint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in public sale
  /// @param _amt The number of tokens to mint
  /// @dev Must send cost * amt in ETH
  function mint(uint256 _amt) external payable {
    require(saleActive, "Sale is not yet active.");
    require(_amt <= MAX_TX, "Amount of tokens exceeds transaction limit.");
    require(totalSupply() + _amt <= MAX_SUPPLY, "Amount exceeds supply.");
    require(cost * _amt == msg.value, "ETH sent not equal to cost.");

    _safeMint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }
}