// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./ExchangeWithOrionPool.sol";
import "./interfaces/IERC20.sol";
import "./utils/fromOZ/ECDSA.sol";
import "./libs/LibAtomic.sol";

contract ExchangeWithAtomic is ExchangeWithOrionPool {
    mapping(bytes32 => LibAtomic.LockInfo) public atomicSwaps;
    mapping(bytes32 => bool) public secrets;

    event AtomicLocked(
        address sender,
        address asset,
        bytes32 secretHash
    );

    event AtomicRedeemed(
        address sender,
        address receiver,
        address asset,
        bytes secret
    );

    event AtomicClaimed(
        address receiver,
        address asset,
        bytes secret
    );

    event AtomicRefunded(
        address receiver,
        address asset,
        bytes32 secretHash
    );

    function lockAtomic(LibAtomic.LockOrder memory swap) payable public {
        LibAtomic.doLockAtomic(swap, atomicSwaps, assetBalances, liabilities);

        require(checkPosition(msg.sender), "E1PA");

        emit AtomicLocked(swap.sender, swap.asset, swap.secretHash);
    }

    function redeemAtomic(LibAtomic.RedeemOrder calldata order, bytes calldata secret) public {
        LibAtomic.doRedeemAtomic(order, secret, secrets, assetBalances, liabilities);
        require(checkPosition(order.sender), "E1PA");

        emit AtomicRedeemed(order.sender, order.receiver, order.asset, secret);
    }

    function redeem2Atomics(LibAtomic.RedeemOrder calldata order1, bytes calldata secret1, LibAtomic.RedeemOrder calldata order2, bytes calldata secret2) public {
        redeemAtomic(order1, secret1);
        redeemAtomic(order2, secret2);
    }

    function claimAtomic(address receiver, bytes calldata secret, bytes calldata matcherSignature) public {
        LibAtomic.LockInfo storage swap = LibAtomic.doClaimAtomic(
                receiver,
                secret,
                matcherSignature,
                _allowedMatcher,
                atomicSwaps,
                assetBalances,
                liabilities
        );

        emit AtomicClaimed(receiver, swap.asset, secret);
    }

    function refundAtomic(bytes32 secretHash) public {
        LibAtomic.LockInfo storage swap = LibAtomic.doRefundAtomic(secretHash, atomicSwaps, assetBalances, liabilities);

        emit AtomicRefunded(swap.sender, swap.asset, secretHash);
    }

    /* Error Codes
        E1: Insufficient Balance, flavor A - Atomic, PA - Position Atomic
        E17: Incorrect atomic secret, flavor: U - used, NF - not found, R - redeemed, E/NE - expired/not expired, ETH
   */
}