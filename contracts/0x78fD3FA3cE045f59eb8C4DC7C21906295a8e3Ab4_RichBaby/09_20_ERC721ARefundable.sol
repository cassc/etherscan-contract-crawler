// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'erc721a/contracts/ERC721A.sol';

error RefundCallerNotOwner();
error RefundCallerNotInitialOwner();
error RefundExpired();
error WithdrawInRefundPeriod();
error NoRefundableValue();
error InvalidStartTokenId();

/**
 * Refundable ERC721 contract based on Azuki's ERC721A protocol.
 *
 * Assumes mint prices of each token are same in one batch,
 *  and minimal precision of token price are 1 gwei.
 *
 * Assumes max token price less than 2^48-1 = 281474.976710655 ETH.
 *
 * Assumes all ETH transferred are used only for minting in one transaction.
 *
 * Assume max token quantity of once minting no more than 2^8-1 = 255.
 *
 * Tokens become unrefundable after it been transferred.
 */
abstract contract ERC721ARefundable is ERC721A {
    uint256 private immutable refundPeriod;

    uint256 public latestRefundableMintTime;
    struct Refundability {
        uint40 mintTime;
        address mintAddress;
        uint48 value; // value in gwei, max of 281474.976710655 ETH
        uint8 quantity;
    }
    mapping(uint256 => Refundability) internal refundabilities;

    constructor(uint64 _refundPeriod) {
        refundPeriod = _refundPeriod;
        latestRefundableMintTime = block.timestamp;
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (from == address(0) && msg.value > 0) {
            // is mint
            refundabilities[startTokenId] = Refundability(
                uint40(block.timestamp),
                to,
                uint48(msg.value / quantity / 1 gwei),
                uint8(quantity)
            );
            latestRefundableMintTime = block.timestamp;
        }
    }

    function refund(uint256 tokenId) external {
        uint256 curr = tokenId;
        while (true) {
            Refundability memory refundability = refundabilities[curr];
            if (refundability.mintTime == 0) {
                if (curr <= _startTokenId()) {
                    break;
                }
                curr--;
                continue;
            }
            refundWithStartTokenId(tokenId, curr);
            return;
        }
        revert NoRefundableValue();
    }

    function refundWithStartTokenId(uint256 tokenId, uint256 startTokenId)
        public
    {
        if (msg.sender != ownerOf(tokenId)) {
            revert RefundCallerNotOwner();
        }
        if (tokenId < startTokenId) {
            revert InvalidStartTokenId();
        }
        Refundability memory refundability = refundabilities[startTokenId];
        if (
            msg.sender != refundability.mintAddress ||
            refundability.quantity <= tokenId - startTokenId
        ) {
            revert RefundCallerNotInitialOwner();
        }
        if (block.timestamp > refundability.mintTime + refundPeriod) {
            revert RefundExpired();
        }
        _burn(tokenId);
        payable(msg.sender).transfer(uint256(refundability.value) * 1 gwei);
        return;
    }

    modifier noWithdrawBeforePossibleRefund() {
        if (block.timestamp < latestRefundableMintTime + refundPeriod) {
            revert WithdrawInRefundPeriod();
        }
        _;
    }
}