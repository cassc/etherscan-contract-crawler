// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract NFT is OwnableUpgradeable, ERC721AUpgradeable, PausableUpgradeable {
  string public uri;

  uint256 public royalties;
  uint256 public price;
  uint256 public maxSupply;

  // Take note of the initializer modifiers.
  // - `initializerERC721A` for `ERC721AUpgradeable`.
  // - `initializer` for OpenZeppelin's `OwnableUpgradeable`.
  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _uri,
    uint256 _royalties,
    uint256 _maxSupply,
    address owner
  ) public initializerERC721A initializer {
    __ERC721A_init(_name, _symbol);
    __Ownable_init();
    __Pausable_init();

    uri = _uri;
    royalties = _royalties;
    maxSupply = _maxSupply;
    _pause();
    transferOwnership(owner);
  }

  function setPrice(uint256 amount) external onlyOwner {
    price = amount;
  }

  function setURI(string calldata _uri) external onlyOwner {
    uri = _uri;
  }

  function setRoyalties(uint256 amount) external onlyOwner {
    royalties = amount;
  }

  function togglePause() external onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  function buy(uint256 quantity) external payable whenNotPaused {
    require(quantity <= 20, "Too many at once");
    require(quantity + _totalMinted() <= maxSupply, "Supply limit");
    require(msg.value >= price * quantity, "Incorrect ETH");
    // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
    _mint(msg.sender, quantity);
  }

  function reserve(uint256 quantity, address beneficiary) external whenNotPaused onlyOwner {
    require(quantity <= 20, "Too many at once");
    require(quantity + _totalMinted() <= maxSupply, "Supply limit");
    // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
    _mint(beneficiary, quantity);
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view returns (address, uint256) {
    return (owner(), (_salePrice * royalties) / 10000);
  }

  function _baseURI() internal view override returns (string memory) {
    return uri;
  }

  function _startTokenId() internal view override returns (uint256) {
    return 1;
  }
}