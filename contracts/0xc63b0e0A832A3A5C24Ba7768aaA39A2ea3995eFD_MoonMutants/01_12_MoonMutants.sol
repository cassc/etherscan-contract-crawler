// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Blood.sol";
import "./MoonVamps.sol";
import "erc721a/contracts/ERC721A.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

contract MoonMutants is ERC721A, ERC721AQueryable, ERC721ABurnable, Owned {
  uint256 constant BLOOD_PRICE = 120;
  uint256 constant BASE_PRICE = 0.015 ether;
  uint256 constant MAX_SUPPLY_PLUS_ONE = 1251;

  string tokenBaseUri =
    "ipfs://QmQJagHKK87xbrfBq82drrfdADxKPD6gmX2tpzhoJDBM6W/?";

  bool public paused = true;

  Blood private immutable bloodContract;
  MoonVamps private immutable vampsContract;

  constructor(address _bloodAddress, address _vampsAddress)
    ERC721A("Moon Mutants", "MM")
    Owned(msg.sender)
  {
    bloodContract = Blood(_bloodAddress);
    vampsContract = MoonVamps(_vampsAddress);
  }

  // Rename mint function to optimize gas
  function mint_540(uint256 _quantity) external payable {
    unchecked {
      require(!paused, "MINTING PAUSED");

      uint256 _bloodBalance = bloodContract.balanceOf(msg.sender);

      require(_bloodBalance > 0, "NOT ENOUGH $BLOOD");

      uint256 _vampsBalance = vampsContract.balanceOf(msg.sender);

      require(_vampsBalance > 0, "NO MOON VAMPS OWNED");

      uint256 _totalSupply = totalSupply();

      require(
        _totalSupply + _quantity < MAX_SUPPLY_PLUS_ONE,
        "MAX SUPPLY REACHED"
      );

      uint256 _payableAmount = getPayableAmount(msg.sender, _quantity);

      require(msg.value == _payableAmount, "INCORRECT ETH AMOUNT");

      uint256 _bloodAmount = _bloodBalance;

      if (BLOOD_PRICE * _quantity < _bloodBalance) {
        _bloodAmount = BLOOD_PRICE * _quantity;
      }

      bloodContract.transferFrom(msg.sender, address(0), _bloodAmount);

      _mint(msg.sender, _quantity);
    }
  }

  function getPayableAmount(address _wallet, uint256 _quantity)
    public
    view
    returns (uint256)
  {
    uint256 _bloodBalance = bloodContract.balanceOf(_wallet);
    uint256 _remainder = 0;
    uint256 _paidMintCount = _quantity;

    if (_quantity * BLOOD_PRICE <= _bloodBalance) {
      return 0;
    }

    if (_bloodBalance >= BLOOD_PRICE) {
      _remainder = _bloodBalance % BLOOD_PRICE;
      _paidMintCount = _quantity - (_bloodBalance / BLOOD_PRICE);
    } else {
      _remainder = _bloodBalance;
    }

    uint256 _discount = (_remainder * 100) / BLOOD_PRICE;
    uint256 _extraFree = 1;

    if (_remainder == 0) {
      _extraFree = 0;
    }

    require(_paidMintCount - _extraFree < 1, "NOT ENOUGH $BLOOD FOR QUANTITY");

    return (BASE_PRICE - (_discount * BASE_PRICE) / 100);
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

    _mint(msg.sender, 1);
  }

  function withdraw() external onlyOwner {
    require(payable(owner).send(address(this).balance), "UNSUCCESSFUL");
  }
}