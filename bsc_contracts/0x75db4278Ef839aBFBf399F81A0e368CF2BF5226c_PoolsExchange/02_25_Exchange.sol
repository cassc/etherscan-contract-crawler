// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ArrayUtils.sol";
import "../libraries/SaleKindInterface.sol";
import "../libraries/ReentrancyGuarded.sol";
import "../registry/ProxyRegistry.sol";
import "../modules/PoolsTransferProxy.sol";
import "../registry/AuthenticatedProxy.sol";
import "./ExchangeMain.sol";

contract Exchange is ExchangeMain {
    /**
     * @dev Call calculateFinalPrice - library function exposed for testing.
     */
    function calculateFinalPrice(
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 amount
    ) public view returns (uint256) {
        return
            SaleKindInterface.calculateFinalPrice(
                side,
                saleKind,
                basePrice,
                extra,
                listingTime,
                expirationTime,
                amount
            );
    }

    /**
     * @dev Call hashOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashOrder_(
        address[7] memory addrs,
        uint256[7] memory uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata
    ) public pure returns (bytes32) {
        return
            hashOrder(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    addrs[3],
                    feeMethod,
                    side,
                    saleKind,
                    addrs[4],
                    howToCall,
                    callData,
                    replacementPattern,
                    addrs[5],
                    staticExtradata,
                    addrs[6],
                    uints[2],
                    uints[3],
                    uints[4],
                    uints[5],
                    uints[6]
                )
            );
    }

    /**
     * @dev Call hashToSign - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashToSign_(
        address[7] memory addrs,
        uint256[7] memory uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata
    ) public pure returns (bytes32) {
        return
            hashToSign(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    addrs[3],
                    feeMethod,
                    side,
                    saleKind,
                    addrs[4],
                    howToCall,
                    callData,
                    replacementPattern,
                    addrs[5],
                    staticExtradata,
                    addrs[6],
                    uints[2],
                    uints[3],
                    uints[4],
                    uints[5],
                    uints[6]
                )
            );
    }

    /**
     * @dev Call validateOrderParameters - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrderParameters_(
        address[7] memory addrs,
        uint256[7] memory uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata
    ) public view returns (bool) {
        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            addrs[3],
            feeMethod,
            side,
            saleKind,
            addrs[4],
            howToCall,
            callData,
            replacementPattern,
            addrs[5],
            staticExtradata,
            addrs[6],
            uints[2],
            uints[3],
            uints[4],
            uints[5],
            uints[6]
        );
        return validateOrderParameters(order);
    }

    /**
     * @dev Call validateOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrder_(
        address[7] memory addrs,
        uint256[7] memory uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            addrs[3],
            feeMethod,
            side,
            saleKind,
            addrs[4],
            howToCall,
            callData,
            replacementPattern,
            addrs[5],
            staticExtradata,
            addrs[6],
            uints[2],
            uints[3],
            uints[4],
            uints[5],
            uints[6]
        );
        return validateOrder(hashToSign(order), order, Sig(v, r, s));
    }

    /**
     * @dev Call approveOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function approveOrder_(
        address[7] memory addrs,
        uint256[7] memory uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        bool orderbookInclusionDesired
    ) public {
        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            addrs[3],
            feeMethod,
            side,
            saleKind,
            addrs[4],
            howToCall,
            callData,
            replacementPattern,
            addrs[5],
            staticExtradata,
            addrs[6],
            uints[2],
            uints[3],
            uints[4],
            uints[5],
            uints[6]
        );
        return approveOrder(order, orderbookInclusionDesired);
    }

    /**
     * @dev Call cancelOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function cancelOrder_(
        address[7] memory addrs,
        uint256[7] memory uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        return
            cancelOrder(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    addrs[3],
                    feeMethod,
                    side,
                    saleKind,
                    addrs[4],
                    howToCall,
                    callData,
                    replacementPattern,
                    addrs[5],
                    staticExtradata,
                    addrs[6],
                    uints[2],
                    uints[3],
                    uints[4],
                    uints[5],
                    uints[6]
                ),
                Sig(v, r, s)
            );
    }

    /**
     * @dev Call calculateCurrentPrice - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function calculateCurrentPrice_(
        address[7] memory addrs,
        uint256[7] memory uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes memory callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        uint256 amount
    ) public view returns (uint256) {
        return
            calculateCurrentPrice(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    addrs[3],
                    feeMethod,
                    side,
                    saleKind,
                    addrs[4],
                    howToCall,
                    callData,
                    replacementPattern,
                    addrs[5],
                    staticExtradata,
                    addrs[6],
                    uints[2],
                    uints[3],
                    uints[4],
                    uints[5],
                    uints[6]
                ),
                amount
            );
    }

    /**
     * @dev Call ordersCanMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function ordersCanMatch_(
        address[14] memory addrs,
        uint256[14] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell
    ) public view returns (bool) {
        Order memory buy = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            addrs[3],
            FeeMethod(feeMethodsSidesKindsHowToCalls[0]),
            SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[1]),
            SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[2]),
            addrs[4],
            AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[3]),
            calldataBuy,
            replacementPatternBuy,
            addrs[5],
            staticExtradataBuy,
            addrs[6],
            uints[2],
            uints[3],
            uints[4],
            uints[5],
            uints[6]
        );
        Order memory sell = Order(
            addrs[7],
            addrs[8],
            addrs[9],
            uints[7],
            uints[8],
            addrs[10],
            FeeMethod(feeMethodsSidesKindsHowToCalls[4]),
            SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[5]),
            SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[6]),
            addrs[11],
            AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[7]),
            calldataSell,
            replacementPatternSell,
            addrs[12],
            staticExtradataSell,
            addrs[13],
            uints[9],
            uints[10],
            uints[11],
            uints[12],
            uints[13]
        );
        return ordersCanMatch(buy, sell);
    }

    // /**
    //  * @dev Return whether or not two orders' calldata specifications can match
    //  * @param buyCalldata Buy-side order calldata
    //  * @param buyReplacementPattern Buy-side order calldata replacement mask
    //  * @param sellCalldata Sell-side order calldata
    //  * @param sellReplacementPattern Sell-side order calldata replacement mask
    //  * @return Whether the orders' calldata can be matched
    //  */
    // function orderCalldataCanMatch(
    //     bytes memory buyCalldata,
    //     bytes memory buyReplacementPattern,
    //     bytes memory sellCalldata,
    //     bytes memory sellReplacementPattern
    // ) public pure returns (bool) {
    //     if (buyReplacementPattern.length > 0) {
    //         ArrayUtils.guardedArrayReplace(
    //             buyCalldata,
    //             sellCalldata,
    //             buyReplacementPattern
    //         );
    //     }
    //     if (sellReplacementPattern.length > 0) {
    //         ArrayUtils.guardedArrayReplace(
    //             sellCalldata,
    //             buyCalldata,
    //             sellReplacementPattern
    //         );
    //     }
    //     return ArrayUtils.arrayEq(buyCalldata, sellCalldata);
    // }

    /**
     * @dev Call calculateMatchPrice - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function calculateMatchPrice_(
        address[14] memory addrs,
        uint256[14] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint256 amount
    ) public view returns (uint256) {
        Order memory buy = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            addrs[3],
            FeeMethod(feeMethodsSidesKindsHowToCalls[0]),
            SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[1]),
            SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[2]),
            addrs[4],
            AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[3]),
            calldataBuy,
            replacementPatternBuy,
            addrs[5],
            staticExtradataBuy,
            addrs[6],
            uints[2],
            uints[3],
            uints[4],
            uints[5],
            uints[6]
        );
        Order memory sell = Order(
            addrs[7],
            addrs[8],
            addrs[9],
            uints[7],
            uints[8],
            addrs[10],
            FeeMethod(feeMethodsSidesKindsHowToCalls[4]),
            SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[5]),
            SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[6]),
            addrs[11],
            AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[7]),
            calldataSell,
            replacementPatternSell,
            addrs[12],
            staticExtradataSell,
            addrs[13],
            uints[9],
            uints[10],
            uints[11],
            uints[12],
            uints[13]
        );
        return calculateMatchPrice(buy, sell, amount);
    }

    /**
     * @dev Call atomicMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function atomicMatch_(
        address[14] memory addrs,
        uint256[14] memory uints,
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
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    addrs[3],
                    FeeMethod(feeMethodsSidesKindsHowToCalls[0]),
                    SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[1]),
                    SaleKindInterface.SaleKind(
                        feeMethodsSidesKindsHowToCalls[2]
                    ),
                    addrs[4],
                    AuthenticatedProxy.HowToCall(
                        feeMethodsSidesKindsHowToCalls[3]
                    ),
                    calldataBuy,
                    replacementPatternBuy,
                    addrs[5],
                    staticExtradataBuy,
                    addrs[6],
                    uints[2],
                    uints[3],
                    uints[4],
                    uints[5],
                    uints[6]
                ),
                Sig(vs[0], rssMetadata[0], rssMetadata[1]),
                Order(
                    addrs[7],
                    addrs[8],
                    addrs[9],
                    uints[7],
                    uints[8],
                    addrs[10],
                    FeeMethod(feeMethodsSidesKindsHowToCalls[4]),
                    SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[5]),
                    SaleKindInterface.SaleKind(
                        feeMethodsSidesKindsHowToCalls[6]
                    ),
                    addrs[11],
                    AuthenticatedProxy.HowToCall(
                        feeMethodsSidesKindsHowToCalls[7]
                    ),
                    calldataSell,
                    replacementPatternSell,
                    addrs[12],
                    staticExtradataSell,
                    addrs[13],
                    uints[9],
                    uints[10],
                    uints[11],
                    uints[12],
                    uints[13]
                ),
                Sig(vs[1], rssMetadata[2], rssMetadata[3]),
                rssMetadata[4]
            );
    }
}