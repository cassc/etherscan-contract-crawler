// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAggregator.sol";
import "./libs/FixinTokenSpender.sol";
import "./libs/ReentrancyGuard.sol";


abstract contract Aggregator is IAggregator, ReentrancyGuard, FixinTokenSpender {

    uint256 private constant SEAPORT_MARKET_ID = 1;
    address private constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

    uint256 private constant ELEMENT_MARKET_ID = 2;
    address private constant ELEMENT = 0x20F780A973856B93f63670377900C1d2a50a77c4;

    uint256 private constant WETH_MARKET_ID = 999;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // markets.slot == 0
    // markets.data.slot == keccak256(markets.slot) == 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
    uint256 private constant MARKETS_DATA_SLOT = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;

    // 168 bits(ethValue)
    uint256 private constant ETH_VALUE_MASK = (1 << 168) - 1;
    // 160 bits(proxy)
    uint256 private constant PROXY_MASK = (1 << 160) - 1;

    function batchBuyWithETH(bytes calldata tradeBytes) external override payable {
        uint256 ethBalanceBefore;
        assembly { ethBalanceBefore := sub(selfbalance(), callvalue()) }

        // trade
        _trade(tradeBytes);

        // return remaining ETH (if any)
        assembly {
            if eq(selfbalance(), ethBalanceBefore) {
                return(0, 0)
            }
            if gt(selfbalance(), ethBalanceBefore) {
                let success := call(gas(), caller(), sub(selfbalance(), ethBalanceBefore), 0, 0, 0, 0)
                return(0, 0)
            }
        }
        revert("Failed to return ETH.");
    }

    function batchBuyWithERC20s(
        ERC20Pair[] calldata erc20Pairs,
        bytes calldata tradeBytes,
        address[] calldata dustTokens
    ) external override payable nonReentrant {
        // transfer ERC20 tokens from the sender to this contract
        _transferERC20Pairs(erc20Pairs);

        // trade
        _trade(tradeBytes);

        // return dust tokens (if any)
        _returnDust(dustTokens);

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let success := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
            }
        }
    }

    function _trade(bytes calldata tradeBytes) internal {
        assembly {
            let anySuccess
            let itemLength
            let end := add(tradeBytes.offset, tradeBytes.length)
            let ptr := mload(0x40) // free memory pointer

            // nextOffset == offset + 28bytes[2 + 1 + 21 + 4] + itemLength
            for { let offset := tradeBytes.offset } lt(offset, end) { offset := add(add(offset, 28), itemLength) } {
                // head == [2 bytes(marketId) + 1 bytes(continueIfFailed) + 21 bytes(ethValue) + 4 bytes(itemLength) + 4 bytes(item)]
                // head == [16 bits(marketId) + 8 bits(continueIfFailed) + 168 bits(ethValue) + 32 bits(itemLength) + 32 bits(item)]
                let head := calldataload(offset)

                // itemLength = (head >> 32) & 0xffffffff
                itemLength := and(shr(32, head), 0xffffffff)

                // itemOffset == offset + 28
                // copy item.data to memory ptr
                calldatacopy(ptr, add(offset, 28), itemLength)

                // marketId = head >> (8 + 168 + 32 + 32) = head >> 240
                let marketId := shr(240, head)

                // Seaport
                if eq(marketId, SEAPORT_MARKET_ID) {
                    // ethValue = (head >> 64) & ETH_VALUE_MASK
                    // SEAPORT.call{value: ethValue}(item)
                    if iszero(call(gas(), SEAPORT, and(shr(64, head), ETH_VALUE_MASK), ptr, itemLength, 0, 0)) {
                        _revertOrContinue(head)
                        continue
                    }
                    anySuccess := 1
                    continue
                }

                // ElementEx
                if eq(marketId, ELEMENT_MARKET_ID) {
                    // ethValue = (head >> 64) & ETH_VALUE_MASK
                    // ELEMENT.call{value: ethValue}(item)
                    if iszero(call(gas(), ELEMENT, and(shr(64, head), ETH_VALUE_MASK), ptr, itemLength, 0, 0)) {
                        _revertOrContinue(head)
                        continue
                    }
                    anySuccess := 1
                    continue
                }

                // WETH
                if eq(marketId, WETH_MARKET_ID) {
                    let methodId := and(head, 0xffffffff)

                    // WETH.deposit();
                    if eq(methodId, 0xd0e30db0) {
                        if iszero(call(gas(), WETH, and(shr(64, head), ETH_VALUE_MASK), ptr, itemLength, 0, 0)) {
                            _revertOrContinue(head)
                            continue
                        }
                        anySuccess := 1
                        continue
                    }

                    // WETH.withdraw();
                    if eq(methodId, 0x2e1a7d4d) {
                        if iszero(call(gas(), WETH, 0, ptr, itemLength, 0, 0)) {
                            _revertOrContinue(head)
                            continue
                        }
                        anySuccess := 1
                        continue
                    }

                    // Do not support other methods.
                    _revertOrContinue(head)
                    continue
                }

                // Others
                // struct Market {
                //        address proxy;
                //        bool isLibrary;
                //        bool isActive;
                //  }
                // [80 bits(unused) + 8 bits(isActive) + 8 bits(isLibrary) + 160 bits(proxy)]
                // [10 bytes(unused) + 1 bytes(isActive) + 1 bytes(isLibrary) + 20 bytes(proxy)]

                // market.slot = markets.data.slot + marketId
                // market = sload(market.slot)
                let market := sload(add(MARKETS_DATA_SLOT, marketId))

                // if (!market.isActive)
                if iszero(byte(10, market)) {
                    // if (!continueIfFailed)
                    if iszero(byte(2, head)) {
                         // revert("Inactive market.")
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(0x40, 0x00000010496e616374697665206d61726b65742e000000000000000000000000)
                        mstore(0x60, 0)
                        revert(0, 0x64)
                    }
                    continue
                }

                // if (!market.isLibrary)
                if iszero(byte(11, market)) {
                    // ethValue = (head >> 64) & ETH_VALUE_MASK
                    // market.proxy.call{value: ethValue}(item)
                    if iszero(call(gas(), and(market, PROXY_MASK), and(shr(64, head), ETH_VALUE_MASK), ptr, itemLength, 0, 0)) {
                        _revertOrContinue(head)
                        continue
                    }
                    anySuccess := 1
                    continue
                }

                // market.proxy.delegatecall(item)
                if iszero(delegatecall(gas(), and(market, PROXY_MASK), ptr, itemLength, 0, 0)) {
                    _revertOrContinue(head)
                    continue
                }
                anySuccess := 1
            }

            // if (!anySuccess)
            if iszero(anySuccess) {
                if gt(tradeBytes.length, 0) {
                    if iszero(returndatasize()) {
                        // revert("No order succeeded.")
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(0x40, 0x000000134e6f206f72646572207375636365656465642e000000000000000000)
                        mstore(0x60, 0)
                        revert(0, 0x64)
                    }
                    // revert(returnData)
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

            function _revertOrContinue(head) {
                // head == [2 bytes(marketId) + 1 bytes(continueIfFailed) + 21 bytes(ethValue) + 4 bytes(itemLength) + 4 bytes(item)]
                // if (!continueIfFailed)
                if iszero(byte(2, head)) {
                    if iszero(returndatasize()) {
                        mstore(0, head)
                        revert(0, 0x20)
                    }
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    function _transferERC20Pairs(ERC20Pair[] calldata erc20Pairs) internal {
        // transfer ERC20 tokens from the sender to this contract
        if (erc20Pairs.length > 0) {
            assembly {
                let ptr := mload(0x40)
                let end := add(erc20Pairs.offset, mul(erc20Pairs.length, 0x40))

                // selector for transferFrom(address,address,uint256)
                mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), address())
                for { let offset := erc20Pairs.offset } lt(offset, end) { offset := add(offset, 0x40) } {
                    let amount := calldataload(add(offset, 0x20))
                    if gt(amount, 0) {
                        mstore(add(ptr, 0x44), amount)
                        let success := call(gas(), calldataload(offset), 0, ptr, 0x64, 0, 0)
                    }
                }
            }
        }
    }

    function _returnDust(address[] calldata tokens) internal {
        // return remaining tokens (if any)
        for (uint256 i; i < tokens.length; ) {
            _transferERC20WithoutCheck(tokens[i], msg.sender, IERC20(tokens[i]).balanceOf(address(this)));
            unchecked { ++i; }
        }
    }
}