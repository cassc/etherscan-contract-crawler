// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/// @title TicketBinaryBet structure for LogiumBinaryBet
/// @notice details structure for binary bets
library TicketBinaryBet {
    /// Ticket details specific to LogiumBinaryBet implementation
    /// Bet parameters:
    /// - isUp - true for UP bet, false for DOWN bet
    /// - pool - uniswap pool for bet strike check. Either an USDC-token or WETH-token pool
    /// - strikeUniswapTick - token/USDC sorted tick (see Market library), if passed bet can be exercised in exercised window
    /// - period - bet period in secs
    /// - ratio - issuer to taker stake proportion encoded as specified in RatioMath library
    /// - issuerWinFee - fee taken from issuer profit on claim and transferred to feeCollector, encoded with 9 decimal points
    /// - traderWinFee - fee taken from trader profit on exercise and transferred to feeCollector, encoded with 9 decimal points
    /// - exerciseWindowDuration - exercise window duration in sec, exercise window is from take "time + period - exerciseWindowDuration" to "time + period"
    /// - claim - address to transfer profit on claim, if 0x0 profit is transferred to freeCollateral
    struct Details {
        bool isUp;
        IUniswapV3Pool pool;
        int24 strikeUniswapTick;
        uint32 period;
        int24 ratio;
        uint32 issuerWinFee;
        uint32 traderWinFee;
        uint32 exerciseWindowDuration;
        address claimTo;
    }

    /// EIP712 type of Details struct
    bytes public constant DETAILS_TYPE =
        "Details(bool isUp,address pool,int24 strikeUniswapTick,uint32 period,int24 ratio,uint32 issuerWinFee,uint32 traderWinFee,uint32 exerciseWindowDuration,address claimTo)";

    function unpackBinaryBetDetails(bytes calldata self)
        internal
        pure
        returns (Details memory out)
    {
        require(self.length == 63, "Invalid details length");
        bytes1 isUpEnc = self[0];
        require(
            (isUpEnc == 0) || (isUpEnc == bytes1(uint8(1))),
            "Invalid bool encoding"
        );
        out.isUp = bool(isUpEnc == bytes1(uint8(1)));
        // solhint-disable no-inline-assembly
        assembly {
            // isUp is decoded above
            calldatacopy(add(out, sub(0x40, 20)), add(self.offset, 1), 20) // pool
            let strike := sar(sub(256, 24), calldataload(add(self.offset, 21)))
            mstore(add(out, sub(0x60, 0x20)), strike)
            calldatacopy(add(out, sub(0x80, 4)), add(self.offset, 24), 4) // period
            let ratio := sar(sub(256, 24), calldataload(add(self.offset, 28)))
            mstore(add(out, sub(0xa0, 0x20)), ratio)
            calldatacopy(add(out, sub(0xc0, 4)), add(self.offset, 31), 4) // issuerWinFee
            calldatacopy(add(out, sub(0xe0, 4)), add(self.offset, 35), 4) // traderWinFee
            calldatacopy(add(out, sub(0x100, 4)), add(self.offset, 39), 4) // exerciseWindowDuration
            calldatacopy(add(out, sub(0x120, 20)), add(self.offset, 43), 20) // claimTo
        }
    }

    function packBinaryBetDetails(Details memory self)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                self.isUp,
                self.pool,
                self.strikeUniswapTick,
                self.period,
                self.ratio,
                self.issuerWinFee,
                self.traderWinFee,
                self.exerciseWindowDuration,
                self.claimTo
            );
    }

    function hashDetails(Details memory self) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(DETAILS_TYPE),
                    self.isUp,
                    self.pool,
                    self.strikeUniswapTick,
                    self.period,
                    self.ratio,
                    self.issuerWinFee,
                    self.traderWinFee,
                    self.exerciseWindowDuration,
                    self.claimTo
                )
            );
    }
}