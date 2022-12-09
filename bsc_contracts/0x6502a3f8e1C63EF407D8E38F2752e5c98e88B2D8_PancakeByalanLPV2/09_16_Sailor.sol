//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ByalanIsland.sol";

import "../interfaces/ISailor.sol";

abstract contract Sailor is ByalanIsland, ISailor {
    uint256 public constant override MAX_FEE = 10000;
    uint256 public override totalFee = 300; // 3%
    uint256 public constant MAX_TOTAL_FEE = 1000; // 10%

    uint256 public override callFee = 4000; // 40% of total fee
    uint256 public treasuryFee = 3000; // 30% of total fee
    uint256 public override kswFee = 3000; // 30% of total fee
    uint256 public feeSum = 10000;

    event SetTotalFee(uint256 totalFee);
    event SetCallFee(uint256 fee);
    event SetTreasuryFee(uint256 fee);
    event SetKSWFee(uint256 fee);

    function setTotalFee(uint256 _totalFee) external onlyOwner {
        require(_totalFee <= MAX_TOTAL_FEE, "!cap");

        totalFee = _totalFee;
        emit SetTotalFee(_totalFee);
    }

    function setCallFee(uint256 _fee) external onlyOwner {
        callFee = _fee;
        feeSum = callFee + treasuryFee + kswFee;
        emit SetCallFee(_fee);
    }

    function setTreasuryFee(uint256 _fee) external onlyOwner {
        treasuryFee = _fee;
        feeSum = callFee + treasuryFee + kswFee;
        emit SetTreasuryFee(_fee);
    }

    function setKSWFee(uint256 _fee) external onlyOwner {
        kswFee = _fee;
        feeSum = callFee + treasuryFee + kswFee;
        emit SetKSWFee(_fee);
    }
}