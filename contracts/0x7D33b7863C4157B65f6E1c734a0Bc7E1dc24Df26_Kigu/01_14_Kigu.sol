// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
import "./PaymentMinimum.sol";

//  ___  __    ___  ________  ___  ___     
// |\  \|\  \ |\  \|\   ____\|\  \|\  \    
// \ \  \/  /|\ \  \ \  \___|\ \  \\\  \   
//  \ \   ___  \ \  \ \  \  __\ \  \\\  \  
//   \ \  \\ \  \ \  \ \  \|\  \ \  \\\  \ 
//    \ \__\\ \__\ \__\ \_______\ \_______\
//     \|__| \|__|\|__|\|_______|\|_______|

/// @author no-op.eth (nft-lab.xyz)
/// @title Kigu
contract Kigu is ERC721A, Ownable, PaymentMinimum, OperatorFilterer {  
  /** Maximum number of tokens per wallet */
  uint256 public constant MAX_WALLET = 10;
  /** Maximum amount of tokens in collection */
  uint256 public constant MAX_SUPPLY = 10000;
  
  /** Structure for tiers array */
  struct Tier {
    /** Number of tokens within a given tier */
    uint16 total;
    /** Cost per token within a given tier */
    uint128 cost;
    /** Free mint allowed? */
    bool free;
  }

  /** Price tiers (during free mint, discounted, full price, in that order) */
  Tier[3] public tiers;

  /** Base URI */
  string public baseURI;

  /** Public sale state */
  bool public saleActive = false;

  /** Notify on sale state change */
  event SaleStateChanged(bool _val);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 _val);

  /** Amount exceeds max supply */
  error SupplyExceeded();
  /** Amount of tokens exceeds wallet limit */
  error WalletLimitExceeded();
  /** ETH sent not equal to cost */
  error InvalidPrice();
  /** Cannot exceed free mint limit */
  error FreeLimitExceeded();
  /** Sale is not active */
  error SaleInactive();
  /** Invalid tier */
  error InvalidTier();

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _minimum,
    address _builder,
    address[] memory _shareholders,
    uint256[] memory _shares
  )
    ERC721A(_name, _symbol)
    PaymentMinimum(_minimum, _builder, _shareholders, _shares)
    OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), false) 
  {
    // Initialize tiers
    tiers[0] = Tier({total: 2000, cost: 0.0033 ether, free: true});
    tiers[1] = Tier({total: 3000, cost: 0.0050 ether, free: false});
    tiers[2] = Tier({total: 5000, cost: 0.0099 ether, free: false});
  }

  /// @notice Returns the base URI
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /// @notice Gets number of NFTs minted for a given wallet
  /// @param _wallet Wallet to check
  function numberMinted(address _wallet) external view returns (uint256) {
    return _numberMinted(_wallet);
  }

  /// @notice Determines the current tier based on the current total supply
  /// @param _totalSupply The current total supply
  function currentTier(uint256 _totalSupply) public view returns (Tier memory) {
    uint256 _freeTierTotal = tiers[0].total;
    if (_totalSupply < _freeTierTotal) { return tiers[0]; }
    if (_totalSupply < _freeTierTotal + tiers[1].total) { return tiers[1]; }
    return tiers[2];
  }

  /// @notice Determines the price for a transaction based on the tier, number already minted, and amount to mint
  /// @param _numberMinted The amount the wallet has already minted
  /// @param _numberToMint The number the wallet is attempting to mint
  /// @param _tier The currently active tier
  function subtotal(uint256 _numberMinted, uint256 _numberToMint, Tier memory _tier) public pure returns (uint256) {
    uint256 _costPerMint = _tier.cost;
    return _numberToMint * _costPerMint - (_tier.free && _numberMinted == 0 ? _costPerMint : 0);
  }

  /// @notice Sets public sale state
  /// @param _val New sale state
  function setSaleState(bool _val) external onlyOwner {
    saleActive = _val;
    emit SaleStateChanged(_val);
  }

  /// @notice Sets the price for a given tier
  /// @param _index Tier index to modify [0: free, 1: discounted, 2: full price]
  /// @param _val New price
  function setTierCost(uint256 _index, uint128 _val) external onlyOwner {
    if (_index >= tiers.length) { revert InvalidTier(); }
    tiers[_index].cost = _val;
  }

  /// @notice Sets the base metadata URI
  /// @param _val The new URI
  function setBaseURI(string calldata _val) external onlyOwner {
    baseURI = _val;
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param _amt The amount to reserve
  function reserve(uint256 _amt) external onlyOwner {
    if (tiers[0].total < totalSupply() + _amt) { revert FreeLimitExceeded(); }
    _mint(msg.sender, _amt);

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token
  /// @param _amt The number of tokens to mint
  /// @dev Must send cost * amt in ETH
  function mint(uint256 _amt) external payable {
    uint256 _walletMints = _numberMinted(msg.sender);
    uint256 _totalSupply = totalSupply();
    if (!saleActive) { revert SaleInactive(); }
    if (_totalSupply + _amt > MAX_SUPPLY) { revert SupplyExceeded(); }
    if (_walletMints + _amt > MAX_WALLET) { revert WalletLimitExceeded(); }
    if (subtotal(_walletMints, _amt, currentTier(_totalSupply)) != msg.value) { revert InvalidPrice(); }

    _safeMint(msg.sender, _amt);
    emit TotalSupplyChanged(totalSupply());
  }

  /// @dev Override to use filter operator
  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  /// @dev Override to use filter operator
  /// @dev We give the staking/other service direct access as a convenience to the consumer (one less transaction, gas)
  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  /// @dev Override to use filter operator
  /// @dev We give the staking/other service direct access as a convenience to the consumer (one less transaction, gas)
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}