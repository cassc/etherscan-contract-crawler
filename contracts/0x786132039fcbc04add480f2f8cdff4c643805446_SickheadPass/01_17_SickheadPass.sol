// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IMintPass.sol";
import "./IPaper.sol";

/// @author no-op.eth (nft-lab.xyz)
/// @title S!ck!ck S!ckheads VIP Passes
contract SickheadPass is ERC1155, IMintPass, IPaper, Ownable, PaymentSplitter {
  /** Name of collection */
  string public constant name = "S!ckhead VIP Pass";
  /** Symbol of collection */
  string public constant symbol = "SVP";
  /** Maximum amount of tokens in collection */
  uint256 public MAX_SUPPLY = 500;
  /** Maximum amount of tokens mintable per tx */
  uint256 public MAX_TX = 2;
  /** Maximum amount of tokens mintable per wallet */
  uint256 public MAX_WALLET = 2;
  /** Cost per mint */
  uint256 public cost = 0.1 ether;
  /** URI for the contract metadata */
  string public contractURI;
  /** For burning */
  address public authorizedBurner;
  /** For paper */
  address public floatWallet;

  /** Total supply */
  uint256 private _supply = 0;

  /** Sale state */
  bool public saleActive = false;
  /** Purchase list */
  mapping(address => uint256) public purchases;

  /** Notify on sale state change */
  event SaleStateChanged(bool _val);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 _val);

  /** For URI conversions */
  using Strings for uint256;

  constructor(
    string memory _uri,
    address[] memory _shareholders, 
    uint256[] memory _shares
  ) ERC1155(_uri) PaymentSplitter(_shareholders, _shares) {}

  /// @notice Sets public sale state
  /// @param _val The new value
  function setSaleState(bool _val) external onlyOwner {
    saleActive = _val;
    emit SaleStateChanged(_val);
  }

  /// @notice Sets cost per mint
  /// @param _val New price
  /// @dev Send in WEI
  function setCost(uint256 _val) external onlyOwner {
    cost = _val;
  }

  /// @notice Sets admin burn address
  /// @param _val Burn operator address
  /// @dev Makes burning a one-step process
  function setAuthorizedBurner(address _val) external onlyOwner {
    authorizedBurner = _val;
  }

  /// @notice Sets float wallet address
  /// @param _val Float wallet
  /// @dev Necessary for paper
  function setFloatWallet(address _val) external onlyOwner {
    floatWallet = _val;
  }

  /// @notice Sets the base metadata URI
  /// @param _val The new URI
  function setBaseURI(string memory _val) external onlyOwner {
    _setURI(_val);
  }

  /// @notice Sets the contract metadata URI
  /// @param _val The new URI
  function setContractURI(string memory _val) external onlyOwner {
    contractURI = _val;
  }

  /// @notice Returns the amount of tokens sold
  /// @return supply The number of tokens sold
  function totalSupply() public view returns (uint256) {
    return _supply;
  }

  /// @notice Returns the URI for a given token ID
  /// @param _id The ID to return URI for
  /// @return Token URI
  function uri(uint256 _id) public view override returns (string memory) {
    return string(abi.encodePacked(super.uri(_id), _id.toString()));
  }

  /// @notice Checks the price of the NFT
  /// @param _tokenId The ID of the NFT which the pricing corresponds to
  function price(uint256 _tokenId) external view override returns (uint256) {
    require(_tokenId == 0, "Invalid token ID.");
    return cost;
  }

  /// @notice Gets any potential reason that the user wallet is not able to claim qty of NFTs
  /// @param _userWallet The address of the user's wallet
  /// @param _quantity The number of NFTs to be minted
  /// @param _tokenId The ID of the NFT that the ineligibility reason corresponds to
  function getClaimIneligibilityReason(address _userWallet, uint256 _quantity, uint256 _tokenId) external view override returns (string memory) {
    if (!saleActive) { return "Sale is not yet active."; }
    if (_tokenId != 0) { return "Invalid token ID."; }
    if (_quantity > MAX_TX) { return "Amount of tokens exceeds transaction limit."; }
    if (purchases[_userWallet] >= MAX_WALLET) { return "Amount of tokens exceeds wallet limit."; }
    
    return "";
  }

  /// @notice Checks the total amount of NFTs left to be claimed
  /// @param _tokenId the ID of the NFT which the pricing corresponds to
  function unclaimedSupply(uint256 _tokenId) external view override returns (uint256) {
    require(_tokenId == 0, "Invalid token ID.");
    return MAX_SUPPLY - totalSupply();
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param _amt The amount to reserve
  function reserve(uint256 _amt) external onlyOwner {
    require(_supply + _amt <= MAX_SUPPLY, "Amount exceeds supply.");

    _supply += _amt;
    _mint(msg.sender, 0, _amt, "0x0000");

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in public sale
  /// @param _userWallet Wallet to be minted to
  /// @param _quantity Amount to be minted
  /// @dev Must send COST * amt in ETH
  function claimTo(address _userWallet, uint256 _quantity, uint256) external payable override {
    address _receiver = msg.sender == floatWallet ? _userWallet : msg.sender;
    require(saleActive, "Sale is not yet active.");
    require(_quantity <= MAX_TX, "Amount of tokens exceeds transaction limit.");
    require(purchases[_receiver] + _quantity <= MAX_WALLET, "Amount of tokens exceeds wallet limit.");
    require(_supply + _quantity <= MAX_SUPPLY, "Amount exceeds supply.");
    require(cost * _quantity == msg.value, "ETH sent is below cost.");

    _supply += _quantity;
    purchases[_receiver] += _quantity;
    _mint(_receiver, 0, _quantity, "0x0000");

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Burns a token
  /// @param _account Current token holder
  /// @param _id ID to burn
  /// @param _value Amount of ID to burn
  /// @dev Authorized burner can bypass approval to allow a one-step burn process
  function burn(address _account, uint256 _id, uint256 _value) external override {
    require(
      _account == _msgSender() || isApprovedForAll(_account, _msgSender()) || authorizedBurner == _msgSender(), 
      "ERC1155: caller is not owner nor approved"
    );

    _supply -= _value;
    _burn(_account, _id, _value);
  }
}