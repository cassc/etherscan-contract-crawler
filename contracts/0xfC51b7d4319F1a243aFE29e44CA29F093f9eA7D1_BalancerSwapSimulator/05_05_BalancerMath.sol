// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

// https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/math/Math.sol
library BalancerMath {

    function div(uint256 a, uint256 b, bool roundUp) internal pure returns (uint256) {
        return roundUp ? divUp(a, b) : divDown(a, b);
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, '!OVEF');
        return c;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, '!b0');
        return a / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, '!b0');

        if (a == 0) {
            return 0;
        } else {
            return 1 + (a - 1) / b;
        }
    }
}