// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract MoonBats is ERC721A, ERC721AQueryable, Owned {
  uint256 constant EXTRA_MINT_PRICE = 0.006 ether;
  uint256 constant MAX_SUPPLY_PLUS_ONE = 10001;
  uint256 constant MAX_PER_TRANSACTION_PLUS_ONE = 11;

  string tokenBaseUri = "ipfs://bafybeih3n5wd7egkeywir4vwitszjb7igcw23vpp6h76bllovnshwlkhfq/";

  bool public paused = true;

  mapping(address => uint256) private _freeMintedCount;

  constructor() ERC721A("Moon Bats", "MB") Owned(msg.sender) {}

  // Rename mint function to optimize gas
  function mint_540(uint256 _quantity) external payable {
    unchecked {
      require(!paused, "MINTING PAUSED");

      uint256 _totalSupply = totalSupply();

      require(_totalSupply + _quantity < MAX_SUPPLY_PLUS_ONE, "MAX SUPPLY REACHED");
      require(_quantity < MAX_PER_TRANSACTION_PLUS_ONE, "MAX PER TRANSACTION IS 10");

      uint256 payForCount = _quantity;
      uint256 freeMintCount = _freeMintedCount[msg.sender];

      if (freeMintCount < 1) {
        if (_quantity > 1) {
          payForCount = _quantity - 1;
        } else {
          payForCount = 0;
        }

        _freeMintedCount[msg.sender] = 1;
      }

      require(
        msg.value == payForCount * EXTRA_MINT_PRICE,
        "INCORRECT ETH AMOUNT"
      );

      _mint(msg.sender, _quantity);
    }
  }

  function freeMintedCount(address owner) external view returns (uint256) {
    return _freeMintedCount[owner];
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function setBaseURI(string calldata _newBaseUri) external onlyOwner {
    tokenBaseUri = _newBaseUri;
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function collectReserves() external onlyOwner {
    require(totalSupply() == 0, "RESERVES TAKEN");

    _mint(msg.sender, 100);
  }

  function withdraw() external onlyOwner {
    require(
      payable(owner).send(address(this).balance),
      "UNSUCCESSFUL"
    );
  }
}