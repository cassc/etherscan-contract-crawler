pragma solidity ^0.6.12;

import "./SafeMath.sol";

library FeeHelpers {
    using SafeMath for uint256;
    
    function getClaimBurnFee(uint256 lastStakedTimestamp, uint256 claimBurnFee) public view returns (uint256) {
        uint256 base = 1;

        if (block.timestamp < lastStakedTimestamp + 1 days) {
            return base.mul(100).div(25);
        } else if (block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(20);
        } else if (block.timestamp < lastStakedTimestamp + 3 days) {
            return base.mul(100).div(10);
        } else if (block.timestamp < lastStakedTimestamp + 4 days) {
            return base.mul(100).div(5);
        } else {
            return base.mul(100).div(claimBurnFee);
        }
    }

    function getClaimTreasuryFee(uint256 lastStakedTimestamp, uint256 claimTreasuryFeePercent) public view returns (uint256) {
        uint256 base = 1;

        if (block.timestamp < lastStakedTimestamp + 1 days) {
            return base.mul(100).div(9);
        } else if (block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(8);
        } else if (block.timestamp < lastStakedTimestamp + 3 days || block.timestamp < lastStakedTimestamp + 4 days) {
            return base.mul(100).div(5);
        } else if (block.timestamp > lastStakedTimestamp + 4 days && block.timestamp < lastStakedTimestamp + 14 days) {
            return base.mul(100).div(4);
        } else {
            return base.mul(100).div(claimTreasuryFeePercent);
        }
    }

    function getClaimLPFee(uint256 lastStakedTimestamp, uint256 claimLPFeePercent) public view returns (uint256) {
        uint256 base = 1;

        if (block.timestamp < lastStakedTimestamp + 1 days) {
            return base.mul(100).div(15);
        } else if (block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(12);
        } else if (block.timestamp < lastStakedTimestamp + 3 days || block.timestamp < lastStakedTimestamp + 4 days) {
            return base.mul(100).div(10);
        } else if (block.timestamp > lastStakedTimestamp + 4 days && block.timestamp < lastStakedTimestamp + 14 days) {
            return base.mul(100).div(5);
        } else {
            return base.mul(100).div(claimLPFeePercent);
        }
    }
    
    function getClaimLiquidBalancePcnt(uint256 lastStakedTimestamp, uint256 claimLiquidBalancePercent) public view returns (uint256) {
        uint256 base = 1;

        if (block.timestamp < lastStakedTimestamp + 1 days) {
            return base.mul(100).div(1);
        } else if (block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(10);
        } else if (block.timestamp < lastStakedTimestamp + 3 days) {
            return base.mul(100).div(15);
        } else if (block.timestamp > lastStakedTimestamp + 3 days && block.timestamp < lastStakedTimestamp + 14 days) {
            return base.mul(100).div(20);
        } else {
            return base.mul(100).div(claimLiquidBalancePercent);
        }
    }

    function getUnstakeBurnFee(uint256 lastStakedTimestamp, uint256 unstakeBurnFeePercent) public view returns (uint256) {
        uint256 base = 1;

        if (block.timestamp < lastStakedTimestamp + 1 days || block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(25);
        } else if (block.timestamp < lastStakedTimestamp + 3 days) {
            return base.mul(100).div(20);
        } else if (block.timestamp < lastStakedTimestamp + 4 days) {
            return base.mul(100).div(15);
        } else if (block.timestamp > lastStakedTimestamp + 4 days && block.timestamp < lastStakedTimestamp + 14 days) {
            return base.mul(100).div(5);
        } else {
            return base.mul(100).div(unstakeBurnFeePercent);
        }
    }

    function getUnstakeTreasuryFee(uint256 lastStakedTimestamp, uint256 unstakeTreasuryFeePercent) public view returns (uint256) {
        uint256 base = 1;

        if (block.timestamp < lastStakedTimestamp + 1 days || block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(25);
        } else if (block.timestamp < lastStakedTimestamp + 3 days) {
            return base.mul(100).div(20);
        } else if (block.timestamp < lastStakedTimestamp + 4 days) {
            return base.mul(100).div(15);
        } else if (block.timestamp > lastStakedTimestamp + 4 days && block.timestamp < lastStakedTimestamp + 14 days) {
            return base.mul(100).div(5);
        } else {
            return base.mul(100).div(unstakeTreasuryFeePercent);
        }
    }
    
    function getUnstakeLPFee(uint256 lastStakedTimestamp, uint256 unstakeLPFeePercent) public view returns (uint256) {
        uint256 base = 1;
        if (block.timestamp < lastStakedTimestamp + 1 days || block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(25);
        } else if (block.timestamp < lastStakedTimestamp + 3 days) {
            return base.mul(100).div(20);
        } else if (block.timestamp < lastStakedTimestamp + 4 days) {
            return base.mul(100).div(15);
        } else if (block.timestamp > lastStakedTimestamp + 4 days && block.timestamp < lastStakedTimestamp + 14 days) {
            return base.mul(100).div(10);
        } else {
            return base.mul(100).div(unstakeLPFeePercent);
        }
    }

    function getBloodyMaryExitFee(uint256 bloodyMaryExitFeePercent) public pure returns (uint256) {
        uint256 base = 1;
        return base.mul(100).div(bloodyMaryExitFeePercent);
    }
}