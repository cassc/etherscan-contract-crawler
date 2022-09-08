// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ExchangeCoreBatch.sol";

contract ExchangeBatch is ExchangeCoreBatch {
    /**
     * @dev Call guardedArrayReplace - library function exposed for testing.
     */
    function guardedArrayReplace(
        bytes memory array,
        bytes memory desired,
        bytes memory mask
    ) public pure returns (bytes memory) {
        ArrayUtils.guardedArrayReplace(array, desired, mask);
        return array;
    }

    /**
     * @dev Call calculateFinalPrice - library function exposed for testing.
     */
    function calculateFinalPrice(
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    ) public view returns (uint256) {
        return SaleKindInterface.calculateFinalPrice(side, saleKind, basePrice, extra, listingTime, expirationTime);
    }

    /**
     * @dev Call hashOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashOrder_(
        address[7] memory addrs,
        uint256[9] memory uints,
        OrderType orderType,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[] memory tokens
    ) public pure returns (bytes32) {
        return
            hashOrder(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    addrs[3],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[4],
                    orderType,
                    feeMethod,
                    side,
                    saleKind,
                    addrs[5],
                    howToCall,
                    addrs[6],
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                ),
                tokens
            );
    }

    /**
     * @dev Call hashToSign - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashToSign_(
        address[7] memory addrs,
        uint256[9] memory uints,
        OrderType orderType,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[] memory tokens
    ) public pure returns (bytes32) {
        return
            hashToSign(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    addrs[3],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[4],
                    orderType,
                    feeMethod,
                    side,
                    saleKind,
                    addrs[5],
                    howToCall,
                    addrs[6],
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                ),
                tokens
            );
    }

    /**
     * @dev Call validateOrderParameters - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrderParameters_(
        address[7] memory addrs,
        uint256[9] memory uints,
        OrderType orderType,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall
    ) public view returns (bool) {
        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            addrs[3],
            uints[0],
            uints[1],
            uints[2],
            uints[3],
            addrs[4],
            orderType,
            feeMethod,
            side,
            saleKind,
            addrs[5],
            howToCall,
            addrs[6],
            uints[4],
            uints[5],
            uints[6],
            uints[7],
            uints[8]
        );
        return validateOrderParameters(order);
    }

    /**
     * @dev Call validateOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrder_(
        address[7] memory addrs,
        uint256[9] memory uints,
        OrderType orderType,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[] memory tokens
    ) public view returns (bool) {
        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            addrs[3],
            uints[0],
            uints[1],
            uints[2],
            uints[3],
            addrs[4],
            orderType,
            feeMethod,
            side,
            saleKind,
            addrs[5],
            howToCall,
            addrs[6],
            uints[4],
            uints[5],
            uints[6],
            uints[7],
            uints[8]
        );
        return validateOrder(hashToSign(order, tokens), order);
    }

    /**
     * @dev Call approveOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function approveOrder_(
        address[7] memory addrs,
        uint256[9] memory uints,
        OrderType orderType,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[] memory tokens
    ) public {
        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            addrs[3],
            uints[0],
            uints[1],
            uints[2],
            uints[3],
            addrs[4],
            orderType,
            feeMethod,
            side,
            saleKind,
            addrs[5],
            howToCall,
            addrs[6],
            uints[4],
            uints[5],
            uints[6],
            uints[7],
            uints[8]
        );
        return approveOrder(order, tokens);
    }

    /**
     * @dev Call cancelOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function cancelOrder_(
        address[7] memory addrs,
        uint256[9] memory uints,
        OrderType orderType,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[] memory tokens
    ) public {
        return
            cancelOrder(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    addrs[3],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[4],
                    orderType,
                    feeMethod,
                    side,
                    saleKind,
                    addrs[5],
                    howToCall,
                    addrs[6],
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                ),
                tokens
            );
    }

    /**
     * @dev Call calculateCurrentPrice - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function calculateCurrentPrice_(
        address[7] memory addrs,
        uint256[9] memory uints,
        OrderType orderType,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall
    ) public view returns (uint256) {
        return
            calculateCurrentPrice(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    addrs[3],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[4],
                    orderType,
                    feeMethod,
                    side,
                    saleKind,
                    addrs[5],
                    howToCall,
                    addrs[6],
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                )
            );
    }

    /**
     * @dev Call ordersCanMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function ordersCanMatch_(
        address[14] memory addrs,
        uint256[18] memory uints,
        uint8[10] memory orderTypeFeeMethodsSidesKindsHowToCalls
    ) public view returns (bool) {
        Order memory buy = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            addrs[3],
            uints[0],
            uints[1],
            uints[2],
            uints[3],
            addrs[4],
            OrderType(orderTypeFeeMethodsSidesKindsHowToCalls[0]),
            FeeMethod(orderTypeFeeMethodsSidesKindsHowToCalls[1]),
            SaleKindInterface.Side(orderTypeFeeMethodsSidesKindsHowToCalls[2]),
            SaleKindInterface.SaleKind(orderTypeFeeMethodsSidesKindsHowToCalls[3]),
            addrs[5],
            AuthenticatedProxy.HowToCall(orderTypeFeeMethodsSidesKindsHowToCalls[4]),
            addrs[6],
            uints[4],
            uints[5],
            uints[6],
            uints[7],
            uints[8]
        );
        Order memory sell = Order(
            addrs[7],
            addrs[8],
            addrs[9],
            addrs[10],
            uints[9],
            uints[10],
            uints[11],
            uints[12],
            addrs[11],
            OrderType(orderTypeFeeMethodsSidesKindsHowToCalls[5]),
            FeeMethod(orderTypeFeeMethodsSidesKindsHowToCalls[6]),
            SaleKindInterface.Side(orderTypeFeeMethodsSidesKindsHowToCalls[7]),
            SaleKindInterface.SaleKind(orderTypeFeeMethodsSidesKindsHowToCalls[8]),
            addrs[12],
            AuthenticatedProxy.HowToCall(orderTypeFeeMethodsSidesKindsHowToCalls[9]),
            addrs[13],
            uints[13],
            uints[14],
            uints[15],
            uints[16],
            uints[17]
        );
        return ordersCanMatch(buy, sell);
    }

    /**
     * @dev Call calculateMatchPrice - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function calculateMatchPrice_(
        address[14] memory addrs,
        uint256[18] memory uints,
        uint8[10] memory orderTypeFeeMethodsSidesKindsHowToCalls
    ) public view returns (uint256) {
        Order memory buy = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            addrs[3],
            uints[0],
            uints[1],
            uints[2],
            uints[3],
            addrs[4],
            OrderType(orderTypeFeeMethodsSidesKindsHowToCalls[0]),
            FeeMethod(orderTypeFeeMethodsSidesKindsHowToCalls[1]),
            SaleKindInterface.Side(orderTypeFeeMethodsSidesKindsHowToCalls[2]),
            SaleKindInterface.SaleKind(orderTypeFeeMethodsSidesKindsHowToCalls[3]),
            addrs[5],
            AuthenticatedProxy.HowToCall(orderTypeFeeMethodsSidesKindsHowToCalls[4]),
            addrs[6],
            uints[4],
            uints[5],
            uints[6],
            uints[7],
            uints[8]
        );
        Order memory sell = Order(
            addrs[7],
            addrs[8],
            addrs[9],
            addrs[10],
            uints[9],
            uints[10],
            uints[11],
            uints[12],
            addrs[11],
            OrderType(orderTypeFeeMethodsSidesKindsHowToCalls[5]),
            FeeMethod(orderTypeFeeMethodsSidesKindsHowToCalls[6]),
            SaleKindInterface.Side(orderTypeFeeMethodsSidesKindsHowToCalls[7]),
            SaleKindInterface.SaleKind(orderTypeFeeMethodsSidesKindsHowToCalls[8]),
            addrs[12],
            AuthenticatedProxy.HowToCall(orderTypeFeeMethodsSidesKindsHowToCalls[9]),
            addrs[13],
            uints[13],
            uints[14],
            uints[15],
            uints[16],
            uints[17]
        );
        return calculateMatchPrice(buy, sell);
    }

    function atomicMatch_(
        address[14] memory addrs,
        uint256[18] memory uints,
        uint8[10] memory orderTypeFeeMethodsSidesKindsHowToCalls,
        uint256[] memory tokens
    ) public payable {
        return
            atomicMatch(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    addrs[3],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[4],
                    OrderType(orderTypeFeeMethodsSidesKindsHowToCalls[0]),
                    FeeMethod(orderTypeFeeMethodsSidesKindsHowToCalls[1]),
                    SaleKindInterface.Side(orderTypeFeeMethodsSidesKindsHowToCalls[2]),
                    SaleKindInterface.SaleKind(orderTypeFeeMethodsSidesKindsHowToCalls[3]),
                    addrs[5],
                    AuthenticatedProxy.HowToCall(orderTypeFeeMethodsSidesKindsHowToCalls[4]),
                    addrs[6],
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                ),
                Order(
                    addrs[7],
                    addrs[8],
                    addrs[9],
                    addrs[10],
                    uints[9],
                    uints[10],
                    uints[11],
                    uints[12],
                    addrs[11],
                    OrderType(orderTypeFeeMethodsSidesKindsHowToCalls[5]),
                    FeeMethod(orderTypeFeeMethodsSidesKindsHowToCalls[6]),
                    SaleKindInterface.Side(orderTypeFeeMethodsSidesKindsHowToCalls[7]),
                    SaleKindInterface.SaleKind(orderTypeFeeMethodsSidesKindsHowToCalls[8]),
                    addrs[12],
                    AuthenticatedProxy.HowToCall(orderTypeFeeMethodsSidesKindsHowToCalls[9]),
                    addrs[13],
                    uints[13],
                    uints[14],
                    uints[15],
                    uints[16],
                    uints[17]
                ),
                tokens
            );
    }

    function atomicMatch2_(
        address[14] memory addrs,
        uint256[18] memory uints,
        uint8[10] memory orderTypeFeeMethodsSidesKindsHowToCalls,
        uint256[] memory tokens,
        uint256 tokenId
    ) public payable {
        require(tokens.length == 0, "PlaExchange: tokens size must be zero");
        require(
            OrderType(orderTypeFeeMethodsSidesKindsHowToCalls[0]) == OrderType.Only,
            "PlaExchange: OrderType must be only"
        );
        return
            atomicMatch2(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    addrs[3],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[4],
                    OrderType(orderTypeFeeMethodsSidesKindsHowToCalls[0]),
                    FeeMethod(orderTypeFeeMethodsSidesKindsHowToCalls[1]),
                    SaleKindInterface.Side(orderTypeFeeMethodsSidesKindsHowToCalls[2]),
                    SaleKindInterface.SaleKind(orderTypeFeeMethodsSidesKindsHowToCalls[3]),
                    addrs[5],
                    AuthenticatedProxy.HowToCall(orderTypeFeeMethodsSidesKindsHowToCalls[4]),
                    addrs[6],
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                ),
                Order(
                    addrs[7],
                    addrs[8],
                    addrs[9],
                    addrs[10],
                    uints[9],
                    uints[10],
                    uints[11],
                    uints[12],
                    addrs[11],
                    OrderType(orderTypeFeeMethodsSidesKindsHowToCalls[5]),
                    FeeMethod(orderTypeFeeMethodsSidesKindsHowToCalls[6]),
                    SaleKindInterface.Side(orderTypeFeeMethodsSidesKindsHowToCalls[7]),
                    SaleKindInterface.SaleKind(orderTypeFeeMethodsSidesKindsHowToCalls[8]),
                    addrs[12],
                    AuthenticatedProxy.HowToCall(orderTypeFeeMethodsSidesKindsHowToCalls[9]),
                    addrs[13],
                    uints[13],
                    uints[14],
                    uints[15],
                    uints[16],
                    uints[17]
                ),
                tokens,
                tokenId
            );
    }
}