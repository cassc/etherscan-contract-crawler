// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./ISafeguardPool.sol";

library SafeguardPoolUserData {
    // In order to preserve backwards compatibility, make sure new join and exit kinds are added at the end of the enum.
    enum JoinKind { INIT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT, EXACT_TOKENS_IN_FOR_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

    uint256 private constant _MASK_128_BITS = 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 private constant _OFFSET_128_BITS = 128;

    function joinKind(bytes memory self) internal pure returns (JoinKind) {
        return abi.decode(self, (JoinKind));
    }

    function exitKind(bytes memory self) internal pure returns (ExitKind) {
        return abi.decode(self, (ExitKind));
    }

    // Swaps
    
    function pricingParameters(bytes memory self) internal pure
    returns(
        address expectedOrigin,
        uint256 originBasedSlippage,
        bytes32 priceBasedParams,
        bytes32 quoteBalances,
        uint256 quoteTotalSupply,
        bytes32 balanceBasedParams,
        bytes32 timeBasedParams
    ) {
        return abi.decode(self, (address, uint256, bytes32, bytes32, uint256, bytes32, bytes32));
    }

    function decodeSignedSwapData(bytes calldata self) internal pure 
    returns(bytes memory swapData, bytes memory signature, uint256 quoteIndex, uint256 deadline) {
        (
            swapData,
            signature,
            quoteIndex,
            deadline
        ) = abi.decode(self, (bytes, bytes, uint256, uint256));
    }

    function unpackPairedUints(bytes32 packedUint) internal pure returns(uint256 a, uint256 b) {
        assembly{
            a := shr(_OFFSET_128_BITS, packedUint)
            b := and(_MASK_128_BITS, packedUint)
        }
    }

    // Joins

    function allowlistData(bytes memory self) internal pure
    returns (uint256 deadline, bytes memory signature, bytes memory joinData) {
        (deadline, signature, joinData) = abi.decode(self, (uint256, bytes, bytes));
    }

    function initJoin(bytes memory self) internal pure returns (JoinKind kind, uint256[] memory amountsIn) {
        (kind, amountsIn) = abi.decode(self, (JoinKind, uint256[]));
    }

    function allTokensInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut) {
        (, bptAmountOut) = abi.decode(self, (JoinKind, uint256));
    }

    // Exits

    function exactBptInForTokensOut(bytes memory self) internal pure returns (uint256 bptAmountIn) {
        (, bptAmountIn) = abi.decode(self, (ExitKind, uint256));
    }

    function decodeSignedExitData(bytes memory self) internal pure 
    returns(ExitKind kind, uint256 deadline, bytes memory exitData, bytes memory signature){
        (
            kind,
            deadline,
            exitData,
            signature
        ) = abi.decode(self, (ExitKind, uint256, bytes, bytes));
    }

    // Join/Exit + Swap
    function exactJoinExitSwapData(bytes memory self) internal pure 
    returns (bool swapTokenIn, bytes memory swapData, bytes memory signature, uint256 quoteIndex, uint256 deadline){
        (
            , // corresponds to join or exit kind
            , // minBptAmountOut or maxBptAmountIn
            , // join amountsIn or exit amounts Out
            swapTokenIn, // excess token in or limit token in
            swapData, // swap pricing data
            signature, // the signature based on swapData & other quote pricing information
            quoteIndex, // the index of the quote
            deadline // swap deadline
        ) = abi.decode(self, (uint8, uint, uint[], bool, bytes, bytes, uint256, uint256));

    }

    // Join/Exit + Swap
    function exactJoinExitAmountsData(bytes memory self) internal pure 
    returns (uint256 limitBptAmount, uint256[] memory joinExitAmounts) {
        
        (
            , // corresponds to join or exit kind
            limitBptAmount, // minBptAmountOut or maxBptAmountIn
            joinExitAmounts // join amountsIn or exit amounts Out
        ) = abi.decode(self, (uint8, uint, uint[]));

    }

}