// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./HasOwners.sol";


abstract contract HasFees is HasOwners {

    struct FeeInfo {
        address recipient;
        uint24 amount;
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
        fees.amount = basispoints;
    }

    function feeInfo(uint salePrice) internal view returns (address receiver, uint fee) {
        receiver = fees.recipient;
        fee = (salePrice * fees.amount) / 10000;
    }
}