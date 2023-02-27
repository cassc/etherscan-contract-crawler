// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../sale/Timed.sol';
import '../Adminable.sol';

abstract contract GeneralIDO is Adminable, Timed {
    // Actual rate is: rate / 1e6
    // 6.123456 actual rate = 6123456 specified rate
    uint256 public rate;
    uint256 public tokensForSale;

    constructor(uint256 _rate, uint256 _tokensForSale) {
        rate = _rate;
        tokensForSale = _tokensForSale;
    }

    function setTokensForSale(uint256 _tokensForSale) external onlyOwnerOrAdmin {
        require(
            !isLive() || _tokensForSale > tokensForSale,
            'Sale: Sale is live, cap change only allowed to a higher value'
        );
        tokensForSale = _tokensForSale;
    }

    function calculatePurchaseAmount(uint256 purchaseAmountWei) public view returns (uint256) {
        return (purchaseAmountWei * rate) / 1e6;
    }

    function setRate(uint256 newRate) public onlyOwnerOrAdmin {
        require(!isLive(), 'Sale: Sale is live, rate change not allowed');
        rate = newRate;
    }

    function stringsEqual(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}