// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract PaymentsSplitter is PaymentSplitter {
    constructor(address[] memory _payees, uint256[] memory _shares)
        payable
        PaymentSplitter(_payees, _shares)
    {}

    function releaseTo(address payable account) public virtual {
        release(account);
    }

    function totalReleasedETH() public view returns (uint256) {
        return totalReleased();
    }
}