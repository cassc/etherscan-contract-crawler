// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

library LibUint256Array {
    function sum(uint256[] memory self) internal pure returns (uint256) {
        uint256 amountOut = 0;

        for (uint256 i = 0; i < self.length; i++) {
            amountOut += self[i];
        }

        return amountOut;
    }
}