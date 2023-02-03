// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../utils/fromOZ/ECDSA.sol";
import "./LibExchange.sol";

library LibAtomic {
    using ECDSA for bytes32;

    struct LockOrder {
        address sender;
        uint64 expiration;
        address asset;
        uint64 amount;
        uint24 targetChainId;
        bytes32 secretHash;
    }

    struct LockInfo {
        address sender;
        uint64 expiration;
        bool used;
        address asset;
        uint64 amount;
        uint24 targetChainId;
    }

    struct ClaimOrder {
        address receiver;
        bytes32 secretHash;
    }

    struct RedeemOrder {
        address sender;
        address receiver;
        address claimReceiver;
        address asset;
        uint64 amount;
        uint64 expiration;
        bytes32 secretHash;
        bytes signature;
    }

    function doLockAtomic(LockOrder memory swap,
        mapping(bytes32 => LockInfo) storage atomicSwaps,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public {
        require(swap.expiration/1000 >= block.timestamp, "E17E");
        require(atomicSwaps[swap.secretHash].sender == address(0), "E17R");

        int remaining = swap.amount;
        if (msg.value > 0) {
            require(swap.asset == address(0), "E17ETH");
            uint112 eth_sent = uint112(LibUnitConverter.baseUnitToDecimal(address(0), msg.value));
            if (eth_sent < swap.amount) {
                remaining = int(swap.amount) - eth_sent;
            } else {
                swap.amount = uint64(eth_sent);
                remaining = 0;
            }
        }

        if (remaining > 0) {
            LibExchange._updateBalance(msg.sender, swap.asset, -1*remaining, assetBalances, liabilities);
            require(assetBalances[msg.sender][swap.asset] >= 0, "E1A");
        }

        atomicSwaps[swap.secretHash] = LockInfo(swap.sender, swap.expiration, false, swap.asset, swap.amount, swap.targetChainId);
    }

    function doRedeemAtomic(
        LibAtomic.RedeemOrder calldata order,
        bytes calldata secret,
        mapping(bytes32 => bool) storage secrets,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public {
        require(!secrets[order.secretHash], "E17R");
        require(getEthSignedAtomicOrderHash(order).recover(order.signature) == order.sender, "E2");
        require(order.expiration/1000 >= block.timestamp, "E4A");
        require(order.secretHash == keccak256(secret), "E17");

        LibExchange._updateBalance(order.sender, order.asset, -1*int(order.amount), assetBalances, liabilities);

        LibExchange._updateBalance(order.receiver, order.asset, order.amount, assetBalances, liabilities);
        secrets[order.secretHash] = true;
    }

    function doClaimAtomic(
        address receiver,
        bytes calldata secret,
        bytes calldata matcherSignature,
        address allowedMatcher,
        mapping(bytes32 => LockInfo) storage atomicSwaps,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public returns (LockInfo storage swap) {
        bytes32 secretHash = keccak256(secret);
        bytes32 coHash = getEthSignedClaimOrderHash(ClaimOrder(receiver, secretHash));
        require(coHash.recover(matcherSignature) == allowedMatcher, "E2");

        swap = atomicSwaps[secretHash];
        require(swap.sender != address(0), "E17NF");
        //  require(swap.expiration/1000 >= block.timestamp, "E17E");
        require(!swap.used, "E17U");

        swap.used = true;
        LibExchange._updateBalance(receiver, swap.asset, swap.amount, assetBalances, liabilities);
    }

    function doRefundAtomic(
        bytes32 secretHash,
        mapping(bytes32 => LockInfo) storage atomicSwaps,
        mapping(address => mapping(address => int192)) storage assetBalances,
        mapping(address => MarginalFunctionality.Liability[]) storage liabilities
    ) public returns(LockInfo storage swap) {
        swap = atomicSwaps[secretHash];
        require(swap.sender != address(0x0), "E17NF");
        require(swap.expiration/1000 < block.timestamp, "E17NE");
        require(!swap.used, "E17U");

        swap.used = true;
        LibExchange._updateBalance(swap.sender, swap.asset, int(swap.amount), assetBalances, liabilities);
    }

    function getEthSignedAtomicOrderHash(RedeemOrder calldata _order) internal view returns (bytes32) {
        uint256 chId;
        assembly {
            chId := chainid()
        }
        return keccak256(
            abi.encodePacked(
                "atomicOrder",
                chId,
                _order.sender,
                _order.receiver,
                _order.claimReceiver,
                _order.asset,
                _order.amount,
                _order.expiration,
                _order.secretHash
            )
        ).toEthSignedMessageHash();
    }

    function getEthSignedClaimOrderHash(ClaimOrder memory _order) internal pure returns (bytes32) {
        uint256 chId;
        assembly {
            chId := chainid()
        }
        return keccak256(
            abi.encodePacked(
                "claimOrder",
                chId,
                _order.receiver,
                _order.secretHash
            )
        ).toEthSignedMessageHash();
    }
}