// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ExchangeCore.sol";
import "../../utils/libraries/Market.sol";

contract Exchange is ExchangeCore {
    function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask)
        public
        pure
        returns (bytes memory)
    {
        ArrayUtils.guardedArrayReplace(array, desired, mask);
        return array;
    }

    function calculateFinalPrice(
        Market.Side side,
        Market.SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    )
        public
        view
        returns (uint256)
    {
        return SaleKindInterface.calculateFinalPrice(side, saleKind, basePrice, extra, listingTime, expirationTime);
    }

    function hashToSign_(
        address[7] memory addrs,
        uint256[9] memory uints,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        Market.HowToCall howToCall,
        bytes calldata callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata
    )
        public
        view
        returns (bytes32)
    { 
        return hashToSign(
          Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, callData, replacementPattern, addrs[5], staticExtradata, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8])
        );
    }

    function validateOrderParameters_ (
        address[7] memory addrs,
        uint256[9] memory uints,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        Market.HowToCall howToCall,
        bytes calldata callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata
    )
        view
        public
        returns (bool)
    {
        Market.Order memory order = Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, callData, replacementPattern, addrs[5], staticExtradata, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]);
        return validateOrderParameters(
          order
        );
    }

    function validateOrder_ (
        address[7] memory addrs,
        uint256[9] memory uints,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        Market.HowToCall howToCall,
        bytes calldata callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        uint8 v,
        bytes32[2] memory rs
    )
        view
        public
        returns (bool)
    {
        Market.Order memory order = Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, callData, replacementPattern, addrs[5], staticExtradata, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]);
        return validateOrder(
          hashToSign(order),
          order,
          Market.Sig(v, rs[0], rs[1])
        );
    }

    function approveOrder_ (
        address[7] memory addrs,
        uint256[9] memory uints,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        Market.HowToCall howToCall,
        bytes calldata callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        bool orderbookInclusionDesired
    ) 
        public
    {
        Market.Order memory order = Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, callData, replacementPattern, addrs[5], staticExtradata, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]);
        return approveOrder(order, orderbookInclusionDesired);
    }

    function cancelOrder_(
        address[7] memory addrs,
        uint256[9] memory uints,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        Market.HowToCall howToCall,
        bytes calldata callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        uint8 v,
        bytes32[2] memory rs
    )
        public
    {
        return cancelOrder(
          Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, callData, replacementPattern, addrs[5], staticExtradata, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]),
          Market.Sig(v, rs[0], rs[1])
        );
    }

    function calculateCurrentPrice_(
        address[7] memory addrs,
        uint256[9] memory uints,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        Market.HowToCall howToCall,
        bytes calldata callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata
    )
        public
        view
        returns (uint256)
    {
        return calculateCurrentPrice(
          Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, callData, replacementPattern, addrs[5], staticExtradata, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8])
        );
    }

    function ordersCanMatch_(
        address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell
    )
        public
        view
        returns (bool)
    {
        Market.Order memory buy = Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], Market.FeeMethod(feeMethodsSidesKindsHowToCalls[0]), Market.Side(feeMethodsSidesKindsHowToCalls[1]), Market.SaleKind(feeMethodsSidesKindsHowToCalls[2]), addrs[4], Market.HowToCall(feeMethodsSidesKindsHowToCalls[3]), calldataBuy, replacementPatternBuy, addrs[5], staticExtradataBuy, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]);
        Market.Order memory sell = Market.Order(addrs[7], addrs[8], addrs[9], uints[9], uints[10], uints[11], uints[12], addrs[10], Market.FeeMethod(feeMethodsSidesKindsHowToCalls[4]), Market.Side(feeMethodsSidesKindsHowToCalls[5]), Market.SaleKind(feeMethodsSidesKindsHowToCalls[6]), addrs[11], Market.HowToCall(feeMethodsSidesKindsHowToCalls[7]), calldataSell, replacementPatternSell, addrs[12], staticExtradataSell, addrs[13], uints[13], uints[14], uints[15], uints[16], uints[17]);
        return ordersCanMatch(
          buy,
          sell
        );
    }

    function orderCalldataCanMatch(
        bytes memory buyCalldata,
        bytes memory buyReplacementPattern,
        bytes memory sellCalldata,
        bytes memory sellReplacementPattern
    )
        public
        pure
        returns (bool)
    {
        if (buyReplacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(buyCalldata, sellCalldata, buyReplacementPattern);
        }
        if (sellReplacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(sellCalldata, buyCalldata, sellReplacementPattern);
        }
        return ArrayUtils.arrayEq(buyCalldata, sellCalldata);
    }

    function calculateMatchPrice_(
        address[14] memory addrs,
        uint256[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell
    )
        public
        view
        returns (uint256)
    {
        Market.Order memory buy = Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], Market.FeeMethod(feeMethodsSidesKindsHowToCalls[0]), Market.Side(feeMethodsSidesKindsHowToCalls[1]), Market.SaleKind(feeMethodsSidesKindsHowToCalls[2]), addrs[4], Market.HowToCall(feeMethodsSidesKindsHowToCalls[3]), calldataBuy, replacementPatternBuy, addrs[5], staticExtradataBuy, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]);
        Market.Order memory sell = Market.Order(addrs[7], addrs[8], addrs[9], uints[9], uints[10], uints[11], uints[12], addrs[10], Market.FeeMethod(feeMethodsSidesKindsHowToCalls[4]), Market.Side(feeMethodsSidesKindsHowToCalls[5]), Market.SaleKind(feeMethodsSidesKindsHowToCalls[6]), addrs[11], Market.HowToCall(feeMethodsSidesKindsHowToCalls[7]), calldataSell, replacementPatternSell, addrs[12], staticExtradataSell, addrs[13], uints[13], uints[14], uints[15], uints[16], uints[17]);
        return calculateMatchPrice(
          buy,
          sell
        );
    }

    /**
     * @dev Call atomicMatch - only accept transaction when buy order matching with sell order
     */
    function atomicMatch_(
        address[14] memory addrs,
        uint256[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    ) public payable {
        return
            atomicMatch(
                Market.Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[3],
                    Market.FeeMethod(feeMethodsSidesKindsHowToCalls[0]),
                    Market.Side(feeMethodsSidesKindsHowToCalls[1]),
                    Market.SaleKind(feeMethodsSidesKindsHowToCalls[2]),
                    addrs[4],
                    Market.HowToCall(feeMethodsSidesKindsHowToCalls[3]),
                    calldataBuy,
                    replacementPatternBuy,
                    addrs[5],
                    staticExtradataBuy,
                    addrs[6],
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                ),
                Market.Sig(vs[0], rssMetadata[0], rssMetadata[1]),
                Market.Order(
                    addrs[7],
                    addrs[8],
                    addrs[9],
                    uints[9],
                    uints[10],
                    uints[11],
                    uints[12],
                    addrs[10],
                    Market.FeeMethod(feeMethodsSidesKindsHowToCalls[4]),
                    Market.Side(feeMethodsSidesKindsHowToCalls[5]),
                    Market.SaleKind(feeMethodsSidesKindsHowToCalls[6]),
                    addrs[11],
                    Market.HowToCall(feeMethodsSidesKindsHowToCalls[7]),
                    calldataSell,
                    replacementPatternSell,
                    addrs[12],
                    staticExtradataSell,
                    addrs[13],
                    uints[13],
                    uints[14],
                    uints[15],
                    uints[16],
                    uints[17]
                ),
                Market.Sig(vs[1], rssMetadata[2], rssMetadata[3]),
                rssMetadata[4]
            );
    }
}