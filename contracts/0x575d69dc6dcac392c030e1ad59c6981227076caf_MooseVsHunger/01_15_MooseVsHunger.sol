// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/utils/Strings.sol';

/// @author no-op (nftlab: https://discord.gg/kH7Gvnr2qp)
/// @title Moose Vs. Hunger
contract MooseVsHunger is ERC1155, Ownable, PaymentSplitter {
  /** Wallets list */
  mapping(address => uint256) public whitelist;

  /** Maximum number of tokens per tx */
  uint256 public constant MAX_TX = 10;
  /** Maximum amount of tokens in collection */
  uint256 public constant MAX_SUPPLY = 10000;
  /** Price per token */
  uint256 public constant COST = 0.055 ether;
  /** Name of collection */
  string public constant name = "Moose Vs. Hunger";
  /** Symbol of collection */
  string public constant symbol = "MOOSE";
  /** URI for the contract metadata */
  string public contractURI;
  
  /** Public sale state */
  bool public saleActive = false;
  /** Presale state */
  bool public presaleActive = false;

  /** Total supply */
  Counters.Counter private _supply;

  /** Notify on sale state change */
  event SaleStateChanged(bool val);
  /** Notify on presale state change */
  event PresaleStateChanged(bool val);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 val);

  /** For URI conversions */
  using Strings for uint256;
  /** For supply count */
  using Counters for Counters.Counter;

  constructor(
    string memory _uri, 
    address[] memory shareholders, 
    uint256[] memory shares
  ) ERC1155(_uri) PaymentSplitter(shareholders, shares) {}

  /// @notice Adds addresses to whitelist with a max buy count
  /// @param wallets The wallets to be added to whitelist
  /// @param count The maximum buy count during presale
  function setWhitelist(address[] memory wallets, uint256[] memory count) external onlyOwner {
    for (uint256 i = 0; i < wallets.length; i++) {
      whitelist[wallets[i]] = count[i];
    }
  }

  /// @notice Sets public sale state
  /// @param val The new value
  function setSaleState(bool val) external onlyOwner {
    saleActive = val;
    emit SaleStateChanged(val);
  }

  /// @notice Sets presale state
  /// @param val The new value
  function setPresaleState(bool val) external onlyOwner {
    presaleActive = val;
    emit PresaleStateChanged(val);
  }

  /// @notice Sets the base metadata URI
  /// @param val The new URI
  function setBaseURI(string memory val) external onlyOwner {
    _setURI(val);
  }

  /// @notice Sets the contract metadata URI
  /// @param val The new URI
  function setContractURI(string memory val) external onlyOwner {
    contractURI = val;
  }

  /// @notice Returns the amount of tokens sold
  /// @return supply The number of tokens sold
  function totalSupply() public view returns (uint256) {
    return _supply.current();
  }

  /// @notice Returns the URI for a given token ID
  /// @param id The ID to return URI for
  /// @return Token URI
  function uri(uint256 id) public view override returns (string memory) {
    return string(abi.encodePacked(super.uri(id), id.toString()));
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param amt The amount to reserve
  function reserve(uint256 amt) external onlyOwner {
    uint256 _currentSupply = _supply.current();
    for (uint256 i = 0; i < amt; i++) {
      _supply.increment();
      _mint(msg.sender, _currentSupply + i, 1, "0x0000");
    }

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in public sale
  /// @param amt The number of tokens to mint
  /// @dev Must send COST * amt in ETH
  function mint(uint256 amt) external payable {
    uint256 _currentSupply = _supply.current();
    require(saleActive, "Sale is not yet active.");
    require(amt <= MAX_TX, "Amount of tokens exceeds transaction limit.");
    require(_currentSupply + amt <= MAX_SUPPLY, "Amount exceeds supply.");
    require(COST * amt <= msg.value, "ETH sent is below cost.");

    for (uint256 i = 0; i < amt; i++) {
      _supply.increment();
      _mint(msg.sender, _currentSupply + i, 1, "0x0000");
    }

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in presale
  /// @param amt The number of tokens to mint
  /// @dev Must send COST * amt in ETH
  function preMint(uint256 amt) external payable {
    uint256 _currentSupply = _supply.current();
    require(presaleActive, "Presale is not yet active.");
    require(amt <= whitelist[msg.sender], "Amount of tokens exceeds whitelist limit.");
    require(_currentSupply + amt <= MAX_SUPPLY, "Amount exceeds supply.");
    require(COST * amt <= msg.value, "ETH sent is below cost.");

    for (uint256 i = 0; i < amt; i++) {
      _supply.increment();
      whitelist[msg.sender] -= 1;
      _mint(msg.sender, _currentSupply + i, 1, "0x0000");
    }

    emit TotalSupplyChanged(totalSupply());
  }
}