// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

/// @author no-op.eth (nft-lab.xyz)
/// @title The Pride
contract ThePride is ERC721A, PaymentSplitter, Ownable {
  /** Maximum number of tokens per wallet */
  uint256 public constant MAX_WALLET = 5;
  /** Maximum amount of tokens in collection */
  uint256 public constant MAX_SUPPLY = 5000;
  /** Price per token */
  uint256 public cost = 0.0069 ether;
  /** Max free */
  uint256 public free = 1000;
  /** Base URI */
  string public baseURI;
  /** Staking service */
  address public authorizedOperator;

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

  /// @notice Gets cost to mint n amount of NFTs, taking account for first one free
  /// @param _numberMinted How many a given wallet has already minted
  /// @param _numberToMint How many a given wallet is planning to mint
  /// @param _costPerMint Price of one nft
  function subtotal(uint256 _numberMinted, uint256 _numberToMint, uint256 _costPerMint) public pure returns (uint256) {
    return _numberToMint * _costPerMint - (_numberMinted > 0 ? 0 : _costPerMint);
  }

  /// @notice Gets number of NFTs minted for a given wallet
  /// @param _wallet Wallet to check
  function numberMinted(address _wallet) external view returns (uint256) {
    return _numberMinted(_wallet);
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

  /// @notice Sets the authorized operator
  /// @param _val The new operator
  /// @dev Allows staking service to transfer nfts
  function setAuthorizedOperator(address _val) external onlyOwner {
    authorizedOperator = _val;
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param _amt The amount to reserve
  function reserve(uint256 _amt) external onlyOwner {
    require(free >= _amt, "Cannot exceed free mint limit.");
    free -= _amt;
    _mint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in presale
  /// @param _amt The number of tokens to mint
  /// @param _proof Merkle proof
  /// @dev Must send cost * amt in ETH
  function preMint(uint256 _amt, bytes32[] calldata _proof) external payable {
    uint256 _walletMints = _numberMinted(msg.sender);
    require(presaleActive, "Presale is not active.");
    require(isWhitelisted(msg.sender, _proof), "Address is not whitelisted.");
    require(_walletMints + _amt <= MAX_PER_WHITELIST, "Amount of tokens exceeds whitelist limit.");
    require(totalSupply() + _amt <= MAX_SUPPLY, "Amount exceeds supply.");
    require(subtotal(_walletMints, _amt, cost) == msg.value, "ETH sent not equal to cost.");
    require(free > 0, "Presale has ended.");
    
    free -= 1;
    // Switch to public once all free mints are gone
    if (free == 0) { presaleActive = false; saleActive = true; }
    
    _safeMint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in public sale
  /// @param _amt The number of tokens to mint
  /// @dev Must send cost * amt in ETH
  function mint(uint256 _amt) external payable {
    require(saleActive, "Sale is not active.");
    require(_numberMinted(msg.sender) + _amt <= MAX_WALLET, "Amount of tokens exceeds wallet limit.");
    require(totalSupply() + _amt <= MAX_SUPPLY, "Amount exceeds supply.");
    require(cost * _amt == msg.value, "ETH sent not equal to cost.");

    _safeMint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Transferrance of nft
  /// @param from From
  /// @param to To
  /// @param tokenId ID to transfer
  /// @param data Additional call data
  /// @dev We give the staking service direct access as a convenience to the consumer (one less transaction, gas)
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable virtual override(ERC721A) {
    if (authorizedOperator != _msgSender()) {
      require(from == _msgSenderERC721A() || isApprovedForAll(from, _msgSenderERC721A()), "ERC721A: transfer caller is not owner nor approved");
    }
    super.safeTransferFrom(from, to, tokenId, data);
  }
}