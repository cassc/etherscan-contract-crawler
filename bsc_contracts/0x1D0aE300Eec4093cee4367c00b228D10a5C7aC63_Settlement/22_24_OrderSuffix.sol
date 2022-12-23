// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@1inch/limit-order-protocol-contract/contracts/OrderLib.sol";
import "./OrderSaltParser.sol";
import "./TakingFee.sol";

// Placed in the end of the order interactions data
// Last byte contains flags and lengths, can have up to 15 resolvers and 7 points
library OrderSuffix {
    using OrderSaltParser for uint256;

    // `Order.interactions` suffix structure:
    // M*(1 + 3 bytes)  - auction points coefficients with seconds delays
    // N*(4 + 20 bytes) - resolver with corresponding time limit
    // 4 bytes          - public time limit
    // 32 bytes         - taking fee (optional if flags has _HAS_TAKING_FEE_FLAG)
    // 1 bytes          - flags

    uint256 private constant _HAS_TAKING_FEE_FLAG = 0x80;
    uint256 private constant _RESOLVERS_LENGTH_MASK = 0x78;
    uint256 private constant _RESOLVERS_LENGTH_BIT_SHIFT = 3;
    uint256 private constant _POINTS_LENGTH_MASK = 0x07;
    uint256 private constant _POINTS_LENGTH_BIT_SHIFT = 0;

    uint256 private constant _TAKING_FEE_BYTES_SIZE = 32;

    uint256 private constant _PUBLIC_TIME_LIMIT_BYTES_SIZE = 4;
    uint256 private constant _PUBLIC_TIME_LIMIT_BIT_SHIFT = 224; // 256 - _PUBLIC_TIME_LIMIT_BYTES_SIZE * 8

    uint256 private constant _AUCTION_POINT_DELAY_BYTES_SIZE = 2;
    uint256 private constant _AUCTION_POINT_BUMP_BYTES_SIZE = 3;
    uint256 private constant _AUCTION_POINT_BYTES_SIZE = 5; // _AUCTION_POINT_DELAY_BYTES_SIZE + _AUCTION_POINT_BUMP_BYTES_SIZE;
    uint256 private constant _AUCTION_POINT_DELAY_BIT_SHIFT = 240; // 256 - _AUCTION_POINT_DELAY_BYTES_SIZE * 8;
    uint256 private constant _AUCTION_POINT_BUMP_BIT_SHIFT = 232; // 256 - _AUCTION_POINT_BUMP_BYTES_SIZE * 8;

    uint256 private constant _RESOLVER_TIME_LIMIT_BYTES_SIZE = 4;
    uint256 private constant _RESOLVER_ADDRESS_BYTES_SIZE = 20;
    uint256 private constant _RESOLVER_BYTES_SIZE = 24; // _RESOLVER_TIME_LIMIT_BYTES_SIZE + _RESOLVER_ADDRESS_BYTES_SIZE;
    uint256 private constant _RESOLVER_TIME_LIMIT_BIT_SHIFT = 224; // 256 - _RESOLVER_TIME_LIMIT_BYTES_SIZE * 8;
    uint256 private constant _RESOLVER_ADDRESS_BIT_SHIFT = 96; // 256 - _RESOLVER_ADDRESS_BYTES_SIZE * 8;

    function takingFee(OrderLib.Order calldata order) internal pure returns (TakingFee.Data ret) {
        bytes calldata interactions = order.interactions;
        assembly {
            let ptr := sub(add(interactions.offset, interactions.length), 1)
            if and(_HAS_TAKING_FEE_FLAG, byte(0, calldataload(ptr))) {
                ret := calldataload(sub(ptr, _TAKING_FEE_BYTES_SIZE))
            }
        }
    }

    function checkResolver(OrderLib.Order calldata order, address resolver) internal view returns (bool valid) {
        bytes calldata interactions = order.interactions;
        assembly {
            let ptr := sub(add(interactions.offset, interactions.length), 1)
            let flags := byte(0, calldataload(ptr))
            ptr := sub(ptr, _PUBLIC_TIME_LIMIT_BYTES_SIZE)
            if and(flags, _HAS_TAKING_FEE_FLAG) {
                ptr := sub(ptr, _TAKING_FEE_BYTES_SIZE)
            }

            let resolversCount := shr(_RESOLVERS_LENGTH_BIT_SHIFT, and(flags, _RESOLVERS_LENGTH_MASK))

            // Check public time limit
            let publicLimit := shr(_PUBLIC_TIME_LIMIT_BIT_SHIFT, calldataload(ptr))
            valid := gt(timestamp(), publicLimit)

            // Check resolvers and corresponding time limits
            if not(valid) {
                for { let end := sub(ptr, mul(_RESOLVER_BYTES_SIZE, resolversCount)) } gt(ptr, end) { } {
                    ptr := sub(ptr, _RESOLVER_ADDRESS_BYTES_SIZE)
                    let account := shr(_RESOLVER_ADDRESS_BIT_SHIFT, calldataload(ptr))
                    ptr := sub(ptr, _RESOLVER_TIME_LIMIT_BYTES_SIZE)
                    let limit := shr(_RESOLVER_TIME_LIMIT_BIT_SHIFT, calldataload(ptr))
                    if eq(account, resolver) {
                        valid := iszero(lt(timestamp(), limit))
                        break
                    }
                }
            }
        }
    }

    function rateBump(OrderLib.Order calldata order) internal view returns (uint256 bump) {
        uint256 startBump = order.salt.getInitialRateBump();
        uint256 cumulativeTime = order.salt.getStartTime();
        uint256 lastTime = cumulativeTime + order.salt.getDuration();
        if (block.timestamp <= cumulativeTime) {
            return startBump;
        } else if (block.timestamp >= lastTime) {
            return 0;
        }

        bytes calldata interactions = order.interactions;
        assembly {
            function linearInterpolation(t1, t2, v1, v2, t) -> v {
                v := div(
                    add(mul(sub(t, t1), v2), mul(sub(t2, t), v1)),
                    sub(t2, t1)
                )
            }

            let ptr := sub(add(interactions.offset, interactions.length), 1)

            // move ptr to the last point
            let pointsCount
            {  // stack too deep
                let flags := byte(0, calldataload(ptr))
                let resolversCount := shr(_RESOLVERS_LENGTH_BIT_SHIFT, and(flags, _RESOLVERS_LENGTH_MASK))
                pointsCount := and(flags, _POINTS_LENGTH_MASK)
                if and(flags, _HAS_TAKING_FEE_FLAG) {
                    ptr := sub(ptr, _TAKING_FEE_BYTES_SIZE)
                }
                ptr := sub(ptr, add(mul(_RESOLVER_BYTES_SIZE, resolversCount), _PUBLIC_TIME_LIMIT_BYTES_SIZE)) // 24 byte for each wl entry + 4 bytes for public time limit
            }

            // Check points sequentially
            let prevCoefficient := startBump
            let prevCumulativeTime := cumulativeTime
            for { let end := sub(ptr, mul(_AUCTION_POINT_BYTES_SIZE, pointsCount)) } gt(ptr, end) { } {
                ptr := sub(ptr, _AUCTION_POINT_BUMP_BYTES_SIZE)
                let coefficient := shr(_AUCTION_POINT_BUMP_BIT_SHIFT, calldataload(ptr))
                ptr := sub(ptr, _AUCTION_POINT_DELAY_BYTES_SIZE)
                let delay := shr(_AUCTION_POINT_DELAY_BIT_SHIFT, calldataload(ptr))
                cumulativeTime := add(cumulativeTime, delay)
                if gt(cumulativeTime, timestamp()) {
                    // prevCumulativeTime <passed> time <elapsed> cumulativeTime
                    // prevCoefficient    <passed>  X   <elapsed> coefficient
                    bump := linearInterpolation(
                        prevCumulativeTime,
                        cumulativeTime,
                        prevCoefficient,
                        coefficient,
                        timestamp()
                    )
                    break
                }
                prevCumulativeTime := cumulativeTime
                prevCoefficient := coefficient
            }

            if iszero(bump) {
                bump := linearInterpolation(
                    prevCumulativeTime,
                    lastTime,
                    prevCoefficient,
                    0,
                    timestamp()
                )
            }
        }
    }
}