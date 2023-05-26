// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract SybilHunterDistribution is PaymentSplitter {
    uint256 public immutable startTimestamp;

    constructor(
        address[] memory payees,
        uint256[] memory shares_,
        uint256 _startTimestamp
    ) payable PaymentSplitter(payees, shares_) {
        startTimestamp = _startTimestamp;
    }

    function release(IERC20 token, address account) public override {
        require(block.timestamp >= startTimestamp, "SHD: Too early to release.");
        super.release(token, account);
    }
}