// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ExchangeCoreSwap.sol";

/**
 * @title Exchange
 * @author Project Wyvern Developers
 */
contract ExchangeSwap is ExchangeCoreSwap {
    constructor(
        string memory name,
        string memory version,
        uint256 chainId,
        bytes32 salt
    ) ExchangeCoreSwap(name, version, chainId, salt) {}

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
     * Test copy byte array
     *
     * @param arrToCopy Array to copy
     * @return byte array
     */
    function testCopy(bytes memory arrToCopy) public pure returns (bytes memory) {
        bytes memory arr = new bytes(arrToCopy.length);
        uint256 index;
        assembly {
            index := add(arr, 0x20)
        }
        ArrayUtils.unsafeWriteBytes(index, arrToCopy);
        return arr;
    }

    /**
     * Test write address to bytes
     *
     * @param addr Address to write
     * @return byte array
     */
    function testCopyAddress(address addr) public pure returns (bytes memory) {
        bytes memory arr = new bytes(0x14);
        uint256 index;
        assembly {
            index := add(arr, 0x20)
        }
        ArrayUtils.unsafeWriteAddress(index, addr);
        return arr;
    }

    function makeOrder(
        address[6] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns,
        bytes memory staticExtradata
    ) internal pure returns (Order memory) {
        return
            Order(
                addrs[0],  // exchange
                addrs[1],  // maker
                addrs[2],  // taker
                side,
                howToCall,
                addrs[3],  // maker erc20 token
                uints[0],  // maker erc20 amount
                addrs[4],  // taker erc20 addr
                uints[1],  // taker erc20 amount
                tokens[0],  // maker erc721 tokens
                datas[0],  // maker calldatas
                replacementPatterns[0],  // maker replacementPatterns
                tokens[1],  // taker erc721 tokens
                datas[1],  // taker calldatas
                replacementPatterns[1],  // taker replacementPatterns
                addrs[5],
                staticExtradata,
                uints[2],  // listingTime
                uints[3],  // expirationTime
                uints[4]   // salt
            );
    }

    /**
     * @dev Call hashOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashOrder_(
        address[6] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns,
        bytes memory staticExtradata
    ) public pure returns (bytes32) {
        return hashOrder(makeOrder(addrs, uints, side, howToCall, tokens, datas, replacementPatterns, staticExtradata));
    }

    /**
     * @dev Call hashToSign - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashToSign_(
        address[6] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns,
        bytes memory staticExtradata
    ) public view returns (bytes32) {
        return hashToSign(makeOrder(addrs, uints, side, howToCall, tokens, datas, replacementPatterns, staticExtradata));
    }

    /**
     * @dev Call validateOrderParameters - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrderParameters_(
        address[6] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns,
        bytes memory staticExtradata
    ) public view returns (bool) {
        return
            validateOrderParameters(
                makeOrder(addrs, uints, side, howToCall, tokens, datas, replacementPatterns, staticExtradata)
            );
    }

    /**
     * @dev Call validateOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrder_(
        address[6] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns,
        bytes memory staticExtradata,
        bytes memory signature
    ) public view returns (bool) {
        Order memory order = makeOrder(addrs, uints, side, howToCall, tokens, datas, replacementPatterns, staticExtradata);
        return validateOrder(hashToSign(order), order, signature);
    }

    /**
     * @dev Call approveOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function approveOrder_(
        address[6] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns,
        bytes memory staticExtradata,
        bool orderbookInclusionDesired
    ) public {
        return
            approveOrder(
                makeOrder(addrs, uints, side, howToCall, tokens, datas, replacementPatterns, staticExtradata),
                orderbookInclusionDesired
            );
    }

    /**
     * @dev Call cancelOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function cancelOrder_(
        address[6] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns,
        bytes memory staticExtradata,
        bytes memory signature
    ) public {
        return
            cancelOrder(
                makeOrder(addrs, uints, side, howToCall, tokens, datas, replacementPatterns, staticExtradata),
                signature
            );
    }

    /**
     * @dev Call ordersCanMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function ordersCanMatch_(
        address[12] memory addrs,
        uint256[10] memory uints,
        uint8[6] memory sidesKindsHowToCalls,
        address[][4] memory tokens,
        bytes[][4] memory datas,
        bytes[][4] memory replacementPatterns,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell
    ) public view returns (bool) {
        Order memory buy = Order(
            addrs[0],  // exchange
            addrs[1],  // maker
            addrs[2],  // taker
            SaleKindInterface.Side(sidesKindsHowToCalls[0]),  // side
            AuthenticatedProxy.HowToCall(sidesKindsHowToCalls[2]),  // how to call
            addrs[3],  // maker erc20 token
            uints[0],  // maker erc20 amount
            addrs[4],  // taker erc20 addr
            uints[1],  // taker erc20 amount
            tokens[0],  // maker erc721 tokens
            datas[0],  // maker calldatas
            replacementPatterns[0], // maker replacementPatterns
            tokens[1],  // taker erc721 tokens
            datas[1],  // taker calldatas
            replacementPatterns[1],  // taker replacementPatterns
            addrs[5],
            staticExtradataBuy,
            uints[2],  // listingTime
            uints[3],  // expirationTime
            uints[4]   // salt
        );
        Order memory sell = Order(
            addrs[6],  // exchange
            addrs[7],  // maker
            addrs[8],  // taker
            SaleKindInterface.Side(sidesKindsHowToCalls[3]),  // side
            AuthenticatedProxy.HowToCall(sidesKindsHowToCalls[5]),  // how to call
            addrs[9],  // maker erc20 token
            uints[5],  // maker erc20 amount
            addrs[10],  // taker erc20 addr
            uints[6],  // taker erc20 amount
            tokens[2],  // maker erc721 tokens
            datas[2],  // maker calldatas
            replacementPatterns[2], // maker replacementPatterns
            tokens[3],  // taker erc721 tokens
            datas[3],  // taker calldatas
            replacementPatterns[3],  // taker replacementPatterns
            addrs[11],
            staticExtradataSell,
            uints[7],  // listingTime
            uints[8],  // expirationTime
            uints[9]   // salt
        );
        return ordersCanMatch(buy, sell);
    }

    /**
     * @dev Return whether or not two orders' calldata specifications can match
     * @param buyCalldata Buy-side order calldata
     * @param buyReplacementPattern Buy-side order calldata replacement mask
     * @param sellCalldata Sell-side order calldata
     * @param sellReplacementPattern Sell-side order calldata replacement mask
     * @return Whether the orders' calldata can be matched
     */
    function orderCalldataCanMatch(
        bytes memory buyCalldata,
        bytes memory buyReplacementPattern,
        bytes memory sellCalldata,
        bytes memory sellReplacementPattern
    ) public pure returns (bool) {
        if (buyReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(buyCalldata, sellCalldata, buyReplacementPattern);
        }
        if (sellReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(sellCalldata, buyCalldata, sellReplacementPattern);
        }
        return ArrayUtils.arrayEq(buyCalldata, sellCalldata);
    }

    /**
     * @dev Call atomicMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function atomicMatch_(
        address[12] memory addrs,
        uint256[10] memory uints,
        uint8[4] memory sidesHowToCalls,
        address[][4] memory tokens,
        bytes[][4] memory datas,
        bytes[][4] memory replacementPatterns,
        bytes[4] memory staticExtraDataSigs,
        bytes32 metadata
    ) public payable {
        return
            atomicMatch(
                Order(
                    addrs[0],  // exchange
                    addrs[1],  // maker
                    addrs[2],  // taker
                    SaleKindInterface.Side(sidesHowToCalls[0]),  // side
                    AuthenticatedProxy.HowToCall(sidesHowToCalls[1]),  // how to call
                    addrs[3],  // maker erc20 token
                    uints[0],  // maker erc20 amount
                    addrs[4],  // taker erc20 addr
                    uints[1],  // taker erc20 amount
                    tokens[0],  // maker erc721 tokens
                    datas[0],  // maker calldatas
                    replacementPatterns[0],  // maker replacementPatterns
                    tokens[1],  // taker erc721 tokens
                    datas[1],  // taker calldatas
                    replacementPatterns[1],  // taker replacementPatterns
                    addrs[5],
                    staticExtraDataSigs[0],
                    uints[2],  // listingTime
                    uints[3],  // expirationTime
                    uints[4]   // salt
                ),
                staticExtraDataSigs[1],
                Order(
                    addrs[6],  // exchange
                    addrs[7],  // maker
                    addrs[8],  // taker
                    SaleKindInterface.Side(sidesHowToCalls[2]),  // side
                    AuthenticatedProxy.HowToCall(sidesHowToCalls[3]),  // how to call
                    addrs[9],  // maker erc20 token
                    uints[5],  // maker erc20 amount
                    addrs[10],  // taker erc20 addr
                    uints[6],  // taker erc20 amount
                    tokens[2],  // maker erc721 tokens
                    datas[2],  // maker calldatas
                    replacementPatterns[2],  // maker replacementPatterns
                    tokens[3],  // taker erc721 tokens
                    datas[3],  // taker calldatas
                    replacementPatterns[3],  // taker replacementPatterns
                    addrs[11],
                    staticExtraDataSigs[2],
                    uints[7],  // listingTime
                    uints[8],  // expirationTime
                    uints[9]   // salt
                ),
                staticExtraDataSigs[3],
                metadata
            );
    }
}