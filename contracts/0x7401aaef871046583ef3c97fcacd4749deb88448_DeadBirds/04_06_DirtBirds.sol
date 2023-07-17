// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DirtBirds is ERC721A, Ownable {
  uint256 constant EXTRA_MINT_PRICE = 0.0069 ether;
  uint256 constant MAX_SUPPLY_PLUS_ONE = 10001;
  uint256 constant MAX_PER_TRANSACTION_PLUS_ONE = 11;

  string tokenBaseUri = "ipfs://bafybeidr5f3rqlnnihqq6rsydltmznbsz5zcrb34wxqr37jqh6kbzuiq6y/";

  bool public paused = true;

  mapping(address => uint256) private _freeMintedCount;

  constructor() ERC721A("Dirt Birds", "DB") {}

  function mint(uint256 _quantity) external payable {
    require(!paused, "Minting paused");

    uint256 _totalSupply = totalSupply();

    require(_totalSupply + _quantity < MAX_SUPPLY_PLUS_ONE, "Exceeds supply");
    require(_quantity < MAX_PER_TRANSACTION_PLUS_ONE, "Exceeds max per tx");

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

    require(msg.value >= payForCount * EXTRA_MINT_PRICE, "ETH sent not correct");

    _mint(msg.sender, _quantity);
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
    require(totalSupply() == 0, "Reserves already taken");

    _mint(msg.sender, 100);
  }

  function withdraw() external onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "Withdraw unsuccessful"
    );
  }
}