// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../Adminable.sol';

abstract contract WithLimits is Adminable {
    // Max sell per user in currency
    uint256 public maxSell;
    // Min contribution per TX in currency
    uint256 public minSell;

    function getMinMaxLimits() external view returns (uint256, uint256) {
        return (minSell, maxSell);
    }

    function setMin(uint256 value) public onlyOwnerOrAdmin {
        require(maxSell == 0 || value <= maxSell, 'Must be smaller than max');
        minSell = value;
    }

    function setMax(uint256 value) public onlyOwnerOrAdmin {
        require(minSell == 0 || value >= minSell, 'Must be bigger than min');
        maxSell = value;
    }
}