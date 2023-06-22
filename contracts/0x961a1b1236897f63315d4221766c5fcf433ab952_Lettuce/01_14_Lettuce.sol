// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";

/// @title HODL THE LETTUCE
contract Lettuce is ERC721A, Ownable, PaymentSplitter, OperatorFilterer {
  /** Maximum amount of tokens in collection */
  uint256 public constant MAX_SUPPLY = 2500;
  /** Amount of NFTs reserved for presale holders */
  uint256 public CLAIMABLE_MINTS = 748;

  /** URI */
  string public uri;
  /** Public sale state */
  bool public saleActive = false;
  /** Price per mint */
  uint256 public price = 0.069 ether;
  /** Wallets whitelisted for claim */
  bytes32 public root;
  /** Number of claims */
  uint256 public mintsClaimed;

  /** Notify on sale state change */
  event SaleStateChanged(bool _val);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 _val);

  /** ETH sent not equal to cost */
  error InvalidPrice();
  /** Amount exceeds max supply */
  error SupplyExceeded();
  /** Claim exceeded */
  error ClaimExceeded();
  /** Sale is not active */
  error SaleInactive();
  /** Not authorized */
  error Unauthorized();

  constructor(
    string memory _name,
    string memory _symbol,
    address[] memory _shareholders,
    uint256[] memory _shares
  ) ERC721A(_name, _symbol)
    PaymentSplitter(_shareholders, _shares)
    OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), false) {}

  /// @notice Determines if a wallet is eligible to claim a free mint
  /// @param _addr Address in question
  /// @param _proof Address proof
  /// @param _root Merkle root
  /// @param _numMinted Amount of mints wallet already has
  function isClaimEligible(address _addr, bytes32[] calldata _proof, bytes32 _root, uint256 _numMinted) public pure returns (bool) {
    return _numMinted == 0 && MerkleProof.verify(_proof, _root, keccak256(bytes.concat(keccak256(abi.encode(_addr, 1)))));
  }

  /// @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
  /// @param tokenId Token ID being referenced
  /// @dev ID is unused (same metadata)
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) { revert URIQueryForNonexistentToken(); }

    string memory _uri = uri;
    return bytes(_uri).length != 0 ? string(_uri) : '';
  }

  /// @notice Gets number of NFTs minted for a given wallet
  /// @param _wallet Wallet to check
  function numberMinted(address _wallet) external view returns (uint256) {
    return _numberMinted(_wallet);
  }

  /// @notice Sets merkle root
  /// @param _val New merkle root
  function setRoot(bytes32 _val) external onlyOwner {
    root = _val;
  }

  /// @notice Sets public sale state
  /// @param _val New sale state
  function setSaleState(bool _val) external onlyOwner {
    saleActive = _val;
    emit SaleStateChanged(_val);
  }

  /// @notice Sets price per mint
  /// @param _val New price
  function setPrice(uint256 _val) external onlyOwner {
    price = _val;
  }

  /// @notice Sets the metadata URI
  /// @param _val The new URI
  function setURI(string calldata _val) external onlyOwner {
    uri = _val;
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param _amt The amount to reserve
  function reserve(uint256 _amt) external onlyOwner {
    if (MAX_SUPPLY < totalSupply() + _amt) { revert SupplyExceeded(); }
    _mint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Allows a presale holder to claim a free mint
  /// @param _proof Wallet merkle proof
  function claim(bytes32[] calldata _proof) external {
    if (!saleActive) { revert SaleInactive(); }
    if (mintsClaimed >= CLAIMABLE_MINTS) { revert ClaimExceeded(); }
    if (!isClaimEligible(msg.sender, _proof, root, _numberMinted(msg.sender))) { revert Unauthorized(); }
    mintsClaimed++;
    _safeMint(msg.sender, 1);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token
  /// @param _amt The number of tokens to mint
  /// @dev Must send cost * amt in ETH
  function mint(uint256 _amt) external payable {
    if (!saleActive) { revert SaleInactive(); }
    if (totalSupply() + _amt > MAX_SUPPLY - CLAIMABLE_MINTS) { revert SupplyExceeded(); }
    if (price * _amt != msg.value) { revert InvalidPrice(); }

    _safeMint(msg.sender, _amt);
    emit TotalSupplyChanged(totalSupply());
  }

  /// @dev Override to use filter operator
  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  /// @dev Override to use filter operator
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  /// @dev Override to use filter operator
  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  /// @dev Override to use filter operator
  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  /// @dev Override to use filter operator
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}