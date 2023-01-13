// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./_tornado.sol";

interface IERC20 {
  function balanceOf(address owner) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
}

interface IERC721 {
  function balanceOf(address owner) external view returns (uint256);
}

contract ETHTornado is Tornado {
  address feeReceiver;
  address feeSetter;

  uint256 public feesCollected;
  address public fndToken;
  uint256 minFnd;
  uint16 feeIn = 10; // 1%
  uint16 feeOut = 10; // 1%
  uint16 taxDiscount = 9; // 0.9%
  Nft[] public nfts;

  struct Nft {
    address nftAddress;
    uint16 minHold;
  }

  modifier onlyFeeSetter() {
    require(msg.sender == feeSetter, "Only fee setter can call this function");
    _;
  }

  constructor(
    IVerifier _verifier,
    IHasher _hasher,
    uint256 _denomination,
    uint32 _merkleTreeHeight
  ) Tornado(_verifier, _hasher, _denomination, _merkleTreeHeight) {
    feeReceiver = msg.sender;
    feeSetter = msg.sender;
  }

  function _processDeposit() internal override {
    require(msg.value == denomination, "Please send `mixDenomination` ETH along with transaction");
    feesCollected += msg.value * feeIn / 1000;
  }

  function _processWithdraw(
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) internal override {
    // sanity checks
    require(msg.value == 0, "Message value is supposed to be zero for ETH instance");
    require(_refund == 0, "Refund value is supposed to be zero for ETH instance");
    uint16 totalFees = feeOut;
    bool discounted = isDiscount(_recipient);
    if (discounted) {
      totalFees -= taxDiscount;
    }
    uint256 denominationWithInFee = denomination * (1000 - feeIn) / 1000;
    uint256 denominationWithTotalFees = denomination * (1000 - totalFees - feeIn) / 1000;
    feesCollected += denominationWithInFee - denominationWithTotalFees;
    (bool success, ) = _recipient.call{ value: denominationWithTotalFees - _fee }("");
    require(success, "payment to _recipient did not go thru");
    if (_fee > 0) {
      (success, ) = _relayer.call{ value: _fee }("");
      require(success, "payment to _relayer did not go thru");
    }
  }

  function setFees(uint8 _feeIn, uint8 _feeOut) external onlyFeeSetter {
    require(_feeIn <= 50, "FeeIn should be less than 5%");
    require(_feeOut <= 50, "FeeOut should be less than 5%");
    feeIn = _feeIn;
    feeOut = _feeOut;
  }

  function setTaxDiscount(uint8 _taxDiscount) external onlyFeeSetter {
    require(_taxDiscount <= 50, "TaxDiscount should be less than 5%");
    taxDiscount = _taxDiscount;
  }

  function isDiscount(address recipient) public view returns (bool) {
    if (fndToken != address(0)) {
      uint256 fndBalance = IERC20(fndToken).balanceOf(recipient);
      if (fndBalance >= minFnd) {
        return true;
      }
    }
    for (uint256 i = 0; i < nfts.length; i++) {
      Nft memory n = nfts[i];
      if (IERC721(n.nftAddress).balanceOf(recipient) >= n.minHold) {
        return true;
      }
    }
    return false;
  }

  function setFeeReceiver(address _feeReceiver) external onlyFeeSetter {
    feeReceiver = _feeReceiver;
  }

  function setFndToken(address _fndToken) external onlyFeeSetter {
    fndToken = _fndToken;
  }

  function addNft(address _nftAddress, uint16 _minHold) external onlyFeeSetter {
    nfts.push(Nft(_nftAddress, _minHold));
  }

  function removeNft(uint256 _index) external onlyFeeSetter {
    require(_index < nfts.length, "Index out of bounds");
    nfts[_index] = nfts[nfts.length - 1];
    nfts.pop();
  }

  function setMinFnd(uint256 _minFnd) external onlyFeeSetter {
    minFnd = _minFnd;
  }

  function setFeeSetter(address _feeSetter) external onlyFeeSetter {
    feeSetter = _feeSetter;
  }

  function withdrawFeesCollected() external onlyFeeSetter {
    (bool success, ) = feeReceiver.call{ value: feesCollected }("");
    require(success, "payment to feeReceiver did not go thru");
    feesCollected = 0;
  }
}