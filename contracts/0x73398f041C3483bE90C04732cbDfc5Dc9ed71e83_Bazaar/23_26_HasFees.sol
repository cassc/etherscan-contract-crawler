// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./HasOwners.sol";
import "./Monetary.sol";


abstract contract HasFees is HasOwners {
    using Monetary for Monetary.Crypto;

    struct FeeInfo {
        address recipient;
        uint24 basispoints;
    }

    FeeInfo public fees;

    constructor(address[] memory owners, address recipient, uint24 basispoints) HasOwners(owners) {
        setFees_(recipient, basispoints);
    }

    function setFees(address recipient, uint24 basispoints) external onlyOwner {
        setFees_(recipient, basispoints);
    }

    function setFees_(address recipient, uint24 basispoints) private {
        require(basispoints <= 10000, "HasFees: fee basispoints too high");
        fees.recipient = recipient;
        fees.basispoints = basispoints;
    }

    function feeInfo(Monetary.Crypto memory price) internal view returns (address receiver, Monetary.Crypto memory fee) {
        receiver = fees.recipient;
        fee = price.multipliedBy(fees.basispoints).dividedBy(10000);
    }
}