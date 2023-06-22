// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @author no-op.eth (nft-lab.xyz)
/// @title DomainPlug Membership Pass
contract DomainPlugPass is ERC1155, Ownable {
  /** Name of collection */
  string public constant name = "DomainPlug Membership Pass";
  /** Symbol of collection */
  string public constant symbol = "DMP";
  /** Maximum amount of tokens in collection */
  uint256 public constant MAX_SUPPLY = 1000;
  /** Maximum amount of tokens mintable per tx */
  uint256 public constant MAX_TX = 4;
  /** Cost per mint */
  uint256 public cost = 0.25 ether;
  /** URI for the contract metadata */
  string public contractURI;
  /** Funds recipient */
  address public recipient;

  /** Total supply */
  uint256 private _supply = 0;

  /** Sale state */
  bool public saleActive = false;

  /** Notify on sale state change */
  event SaleStateChanged(bool _val);
  /** Notify on total supply change */
  event TotalSupplyChanged(uint256 _val);

  /** For URI conversions */
  using Strings for uint256;

  constructor(string memory _uri) ERC1155(_uri) {}

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

  /// @notice Sets a new funds recipient
  /// @param _val New address
  function setRecipient(address _val) external onlyOwner {
    recipient = _val;
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

  /// @notice Withdraws contract funds
  function withdraw() public payable onlyOwner {
    payable(recipient).transfer(address(this).balance);
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
  /// @param _quantity Amount to be minted
  /// @dev Must send COST * amt in wei
  function mint(uint256 _quantity) external payable {
    require(saleActive, "Sale is not yet active.");
    require(_quantity <= MAX_TX, "Amount of tokens exceeds transaction limit.");
    require(_supply + _quantity <= MAX_SUPPLY, "Amount exceeds supply.");
    require(cost * _quantity == msg.value, "ETH sent not equal to cost.");

    _supply += _quantity;
    _mint(msg.sender, 0, _quantity, "0x0000");

    emit TotalSupplyChanged(totalSupply());
  }
}