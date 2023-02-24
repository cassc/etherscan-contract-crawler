/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

library CrossPipResult {
    struct Result {
        uint128 baseCrossPipOut;
        uint128 quoteCrossPipOut;
        uint128 toPip;
    }

    /// @notice update amount quote and base when fill amm
    /// @param self the result of cross pip
    /// @param baseCrossPipOut amount base cross pip out
    /// @param quoteCrossPipOut amount quote cross pip out
    function updateAmountResult(
        Result memory self,
        uint128 baseCrossPipOut,
        uint128 quoteCrossPipOut
    ) internal pure {
        self.baseCrossPipOut += baseCrossPipOut;
        self.quoteCrossPipOut += quoteCrossPipOut;
    }

    /// @notice update the pip when fill amm
    /// @param self the result of cross pip
    /// @param toPip the pip reach to
    function updatePipResult(Result memory self, uint128 toPip) internal pure {
        self.toPip = toPip;
    }
}