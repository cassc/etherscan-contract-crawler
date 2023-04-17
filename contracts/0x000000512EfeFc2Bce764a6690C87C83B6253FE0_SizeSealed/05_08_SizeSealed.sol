// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {ECCMath} from "./util/ECCMath.sol";
import {ISizeSealed} from "./interfaces/ISizeSealed.sol";
import {CommonTokenMath} from "./util/CommonTokenMath.sol";

/// @title Size Sealed Auction
/// @author Size Market
contract SizeSealed is ISizeSealed {
    ///////////////////////////////
    ///          STATE          ///
    ///////////////////////////////

    uint256 public currentAuctionId;

    mapping(uint256 => Auction) public idToAuction;

    ///////////////////////////////////////////////////
    ///                  MODIFIERS                  ///
    ///////////////////////////////////////////////////

    modifier atState(Auction storage a, States _state) {
        if (block.timestamp < a.timings.startTimestamp) {
            if (_state != States.Created) revert InvalidState();
        } else if (block.timestamp < a.timings.endTimestamp) {
            if (_state != States.AcceptingBids) revert InvalidState();
        } else if (a.data.finalized) {
            if (_state != States.Finalized) revert InvalidState();
        } else if (block.timestamp <= a.timings.endTimestamp + 24 hours) {
            if (_state != States.RevealPeriod) revert InvalidState();
        } else if (block.timestamp > a.timings.endTimestamp + 24 hours) {
            if (_state != States.Voided) revert InvalidState();
        } else {
            revert();
        }
        _;
    }

    ///////////////////////////////////////////////////////////////////////
    ///                          AUCTION LOGIC                          ///
    ///////////////////////////////////////////////////////////////////////

    /// @notice Creates a new sealed auction
    /// @dev Transfers the `baseToken` from `msg.sender` to the contract
    /// @return `auctionId` unique to that auction
    /// @param auctionParams Parameters used during the auction
    /// @param timings The timestamps at which the auction starts/ends
    /// @param encryptedSellerPrivKey Encrypted seller's ephemeral private key
    function createAuction(
        AuctionParameters calldata auctionParams,
        Timings calldata timings,
        bytes calldata encryptedSellerPrivKey
    ) external returns (uint256) {
        if (timings.endTimestamp <= block.timestamp) {
            revert InvalidTimestamp();
        }
        if (timings.startTimestamp >= timings.endTimestamp) {
            revert InvalidTimestamp();
        }
        if (timings.endTimestamp > timings.vestingStartTimestamp) {
            revert InvalidTimestamp();
        }
        if (timings.vestingStartTimestamp > timings.vestingEndTimestamp) {
            revert InvalidTimestamp();
        }
        if (timings.cliffPercent > 1e18) {
            revert InvalidCliffPercent();
        }
        // Revert if the min bid is more than the total reserve of the auction
        if (
            FixedPointMathLib.mulDivDown(
                auctionParams.minimumBidQuote, type(uint128).max, auctionParams.totalBaseAmount
            ) > auctionParams.reserveQuotePerBase
        ) {
            revert InvalidReserve();
        }
        // Passes https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol#L9
        if (auctionParams.quoteToken.code.length == 0 || auctionParams.baseToken.code.length == 0) {
            revert TokenDoesNotExist();
        }

        uint256 auctionId = ++currentAuctionId;

        Auction storage a = idToAuction[auctionId];
        a.timings = timings;

        a.data.seller = msg.sender;

        a.params = auctionParams;

        // Transfer base tokens from the seller
        transferWithTaxCheck(auctionParams.baseToken, msg.sender, auctionParams.totalBaseAmount);

        emit AuctionCreated(auctionId, msg.sender, auctionParams, timings, encryptedSellerPrivKey);

        return auctionId;
    }

    /// @dev Transfers `amount` from msg.sender, and checks that the amount transferred matches the expected
    function transferWithTaxCheck(address token, address from, uint256 amount) internal {
        uint256 balanceBeforeTransfer = ERC20(token).balanceOf(address(this));

        SafeTransferLib.safeTransferFrom(ERC20(token), from, address(this), amount);

        uint256 balanceAfterTransfer = ERC20(token).balanceOf(address(this));
        if (balanceAfterTransfer - balanceBeforeTransfer != amount) {
            revert UnexpectedBalanceChange();
        }
    }

    /// @notice Bid on a runnning auction
    /// @dev Transfers `quoteAmount` of `quoteToken` from bidder to contract
    /// @return Index of the bid
    /// @param auctionId Id of the auction to bid on
    /// @param quoteAmount Amount of `quoteTokens` bidding on a committed amount of `baseTokens`
    /// @param commitment Hash commitment of the `baseAmount`
    /// @param pubKey Public key used to encrypt `baseAmount`
    /// @param encryptedMessage `baseAmount` encrypted to the seller's public key
    /// @param encryptedPrivateKey Encrypted private key for on-chain storage
    /// @param proof Merkle proof that checks seller against `merkleRoot` if there is a whitelist
    function bid(
        uint256 auctionId,
        uint128 quoteAmount,
        bytes32 commitment,
        ECCMath.Point calldata pubKey,
        bytes32 encryptedMessage,
        bytes calldata encryptedPrivateKey,
        bytes32[] calldata proof
    ) external atState(idToAuction[auctionId], States.AcceptingBids) returns (uint256) {
        Auction storage a = idToAuction[auctionId];

        if (a.params.merkleRoot != bytes32(0)) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProofLib.verify(proof, a.params.merkleRoot, leaf)) {
                revert InvalidProof();
            }
        }

        // Seller cannot bid on their own auction
        if (msg.sender == a.data.seller) {
            revert UnauthorizedCaller();
        }

        if (quoteAmount == 0 || quoteAmount < a.params.minimumBidQuote) {
            revert InvalidBidAmount();
        }

        uint256 bidIndex = a.bids.length;
        // Max of 1000 bids on an auction to prevent DOS
        if (bidIndex >= 1000) {
            revert InvalidState();
        }

        EncryptedBid memory ebid;
        ebid.sender = msg.sender;
        ebid.quoteAmount = quoteAmount;
        ebid.initialIndex = uint128(bidIndex);
        ebid.commitment = commitment;
        ebid.pubKey = pubKey;
        ebid.encryptedMessage = encryptedMessage;

        a.bids.push(ebid);

        // Transfer the quote tokens from the bidder
        transferWithTaxCheck(a.params.quoteToken, msg.sender, quoteAmount);

        emit Bid(
            msg.sender, auctionId, bidIndex, quoteAmount, commitment, pubKey, encryptedMessage, encryptedPrivateKey
        );

        return bidIndex;
    }

    /// @notice Reveals the private key of the seller
    /// @dev All valid bids are decrypted after this
    ///      finalizeBidIndices should be empty if seller does not wish to finalize in this tx
    /// @param privateKey Private key corresponding to the auctions public key
    /// @param finalizeBidIndices Bid indices that will be sent to finalize()
    function reveal(uint256 auctionId, uint256 privateKey, uint256[] calldata finalizeBidIndices)
        external
        atState(idToAuction[auctionId], States.RevealPeriod)
    {
        Auction storage a = idToAuction[auctionId];
        if (a.data.privKey != 0) {
            revert InvalidState();
        }

        ECCMath.Point memory pubKey = ECCMath.publicKey(privateKey);
        if (pubKey.x != a.params.pubKey.x || pubKey.y != a.params.pubKey.y || (pubKey.x == 1 && pubKey.y == 1)) {
            revert InvalidPrivateKey();
        }

        a.data.privKey = privateKey;

        emit RevealedKey(auctionId, privateKey);

        if (finalizeBidIndices.length != 0) {
            finalize(auctionId, finalizeBidIndices);
        }
    }

    // Used to get around stack too deep errors -- even with viaIr
    struct FinalizeData {
        uint256 reserveQuotePerBase;
        uint256 totalBaseAmount;
        uint256 previousIndex;
        uint256 previousQuote;
        uint256 previousBase;
        uint256 filledBase;
    }

    /// @notice Finalises an auction by revealing all bids
    /// @dev Calculates the minimum `quotePerBase` and marks successful bids
    /// @param auctionId `auctionId` of the auction to bid on
    /// @param bidIndices Bids sorted by price descending
    function finalize(uint256 auctionId, uint256[] memory bidIndices)
        public
        atState(idToAuction[auctionId], States.RevealPeriod)
    {
        Auction storage a = idToAuction[auctionId];
        uint256 sellerPriv = a.data.privKey;
        if (sellerPriv == 0) {
            revert InvalidPrivateKey();
        }

        if (bidIndices.length != a.bids.length) {
            revert InvalidCalldata();
        }

        FinalizeData memory data;
        data.reserveQuotePerBase = a.params.reserveQuotePerBase;
        data.totalBaseAmount = a.params.totalBaseAmount;
        data.previousQuote = type(uint128).max;
        data.previousBase = 1;

        // Bitmap of all the bid indices that have been processed
        uint256[] memory seenBidMap = new uint256[]((bidIndices.length/256)+1);

        // Fill orders from highest price to lowest price
        for (uint256 i; i < bidIndices.length; i++) {
            uint256 bidIndex = bidIndices[i];
            EncryptedBid storage b = a.bids[bidIndex];

            {
                // Verify this bid index hasn't been seen before
                uint256 bitmapIndex = bidIndex / 256;
                uint256 bitMap = seenBidMap[bitmapIndex];
                uint256 indexBit = 1 << (bidIndex % 256);
                if (bitMap & indexBit == indexBit) revert IncorrectBidIndices();
                seenBidMap[bitmapIndex] = bitMap | indexBit;
            }

            // k1*(G*k2) == k2*(G*k1)
            ECCMath.Point memory sharedPoint = ECCMath.ecMul(b.pubKey, sellerPriv);
            // If the bidder public key isn't on the bn128 curve
            if (sharedPoint.x == 1 && sharedPoint.y == 1) continue;

            bytes32 decryptedMessage = ECCMath.decryptMessage(sharedPoint, b.encryptedMessage);
            // If the bidder didn't faithfully submit commitment or pubkey
            if (computeCommitment(decryptedMessage) != b.commitment) continue;

            // Most significant 128 bits are the base amount
            uint256 baseAmount = uint256(decryptedMessage >> 128);
            uint256 quoteAmount = b.quoteAmount;
            uint256 initialIndex = b.initialIndex;

            if (baseAmount == 0) continue;

            {
                // Verify that bids are sorted by price-time priority
                uint256 currentMult = quoteAmount * data.previousBase;
                uint256 previousMult = data.previousQuote * baseAmount;

                if (currentMult >= previousMult) {
                    // If last bid was the same price, make sure we filled the earliest bid first
                    if (currentMult == previousMult) {
                        if (data.previousIndex > initialIndex) revert InvalidSorting();
                    } else {
                        revert InvalidSorting();
                    }
                }
            }

            // Only fill if above reserve price
            if (FixedPointMathLib.mulDivDown(quoteAmount, type(uint128).max, baseAmount) < data.reserveQuotePerBase) {
                continue;
            }

            // Auction has been fully filled
            if (data.filledBase == data.totalBaseAmount) continue;

            data.previousBase = baseAmount;
            data.previousQuote = quoteAmount;
            data.previousIndex = initialIndex;

            // Fill the remaining unfilled base amount
            if (data.filledBase + baseAmount > data.totalBaseAmount) {
                baseAmount = data.totalBaseAmount - data.filledBase;
            }

            b.filledBaseAmount = uint128(baseAmount);
            data.filledBase += baseAmount;
        }

        a.data.clearingQuote = uint128(data.previousQuote);
        a.data.clearingBase = uint128(data.previousBase);
        a.data.finalized = true;

        // seenBidMap[0:len-1] should be full
        for (uint256 i; i < seenBidMap.length - 1; i++) {
            if (seenBidMap[i] != type(uint256).max) {
                revert IncorrectBidIndices();
            }
        }

        // seenBidMap[-1] should only have the last N bits set
        if (seenBidMap[seenBidMap.length - 1] != (1 << (bidIndices.length % 256)) - 1) {
            revert IncorrectBidIndices();
        }

        // Sanity check that we didn't overfill the auction
        if (data.filledBase > data.totalBaseAmount) {
            revert OverfilledAuction();
        }

        // Transfer the unsold baseToken
        if (data.totalBaseAmount > data.filledBase) {
            uint256 unsoldBase = data.totalBaseAmount - data.filledBase;
            a.params.totalBaseAmount = uint128(data.filledBase);
            safeTransferOut(a.params.baseToken, a.data.seller, unsoldBase);
        }

        // Calculate quote amount based on clearing price
        uint256 filledQuote = FixedPointMathLib.mulDivDown(data.previousQuote, data.filledBase, data.previousBase);

        safeTransferOut(a.params.quoteToken, a.data.seller, filledQuote);

        emit AuctionFinalized(auctionId, bidIndices, data.filledBase, filledQuote);
    }

    /// @notice Called after finalize for unsuccessful bidders to return funds
    /// @dev Returns all `quoteToken` to the original bidder
    /// @param auctionId `auctionId` of the auction to bid on
    /// @param bidIndex Index of the failed bid to be refunded
    function refund(uint256 auctionId, uint256 bidIndex) external atState(idToAuction[auctionId], States.Finalized) {
        Auction storage a = idToAuction[auctionId];
        EncryptedBid storage b = a.bids[bidIndex];
        if (msg.sender != b.sender) {
            revert UnauthorizedCaller();
        }

        if (b.filledBaseAmount != 0) {
            revert InvalidState();
        }

        b.sender = address(0);

        emit BidRefund(auctionId, bidIndex);

        SafeTransferLib.safeTransfer(ERC20(a.params.quoteToken), msg.sender, b.quoteAmount);
    }

    /// @notice Called after finalize for successful bidders
    /// @dev Returns won `baseToken` & any unfilled `quoteToken` to the bidder
    /// @param auctionId `auctionId` of the auction bid on
    /// @param bidIndex Index of the successful bid
    function withdraw(uint256 auctionId, uint256 bidIndex) external atState(idToAuction[auctionId], States.Finalized) {
        Auction storage a = idToAuction[auctionId];
        EncryptedBid storage b = a.bids[bidIndex];
        if (msg.sender != b.sender) {
            revert UnauthorizedCaller();
        }

        uint128 baseAmount = b.filledBaseAmount;
        if (baseAmount == 0) {
            revert InvalidState();
        }

        uint128 baseTokensAvailable = tokensAvailableForWithdrawal(auctionId, baseAmount);
        baseTokensAvailable = baseTokensAvailable - b.baseWithdrawn;

        b.baseWithdrawn += baseTokensAvailable;

        // Refund unfilled quoteAmount on first withdraw
        if (b.quoteAmount != 0) {
            uint256 quoteBought = FixedPointMathLib.mulDivUp(baseAmount, a.data.clearingQuote, a.data.clearingBase);
            // refund = min(quoteAmount, quoteBought)
            uint256 refundedQuote = b.quoteAmount;
            if (refundedQuote >= quoteBought) refundedQuote -= quoteBought;
            else refundedQuote = 0;
            b.quoteAmount = 0;

            safeTransferOut(a.params.quoteToken, msg.sender, refundedQuote);
        }

        safeTransferOut(a.params.baseToken, msg.sender, baseTokensAvailable);

        emit Withdrawal(auctionId, bidIndex, baseTokensAvailable, baseAmount - b.baseWithdrawn);
    }

    /// @dev Transfer amount of token, but cap the amount at the current balance to prevent reverts
    function safeTransferOut(address token, address to, uint256 amount) internal {
        uint256 balance = ERC20(token).balanceOf(address(this));
        if (balance < amount) amount = balance;
        if (amount == 0) return;

        SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }

    /// @dev Transfers `baseToken` back to seller and will enable withdraws for bidders
    /// @param auctionId `auctionId` of the auction to be canceled
    function cancelAuction(uint256 auctionId) external {
        Auction storage a = idToAuction[auctionId];
        if (msg.sender != a.data.seller) {
            revert UnauthorizedCaller();
        }
        // Only allow cancellations before finalization
        // Equivalent to atState(idToAuction[auctionId], ~STATE_FINALIZED)
        if (a.data.finalized) {
            revert InvalidState();
        }

        // Allowing bidders to cancel bids (withdraw quote)
        // Auction considered forever States.AcceptingBids but nobody can finalize
        a.data.seller = address(0);
        a.timings.endTimestamp = type(uint32).max;

        emit AuctionCanceled(auctionId);

        SafeTransferLib.safeTransfer(ERC20(a.params.baseToken), msg.sender, a.params.totalBaseAmount);
    }

    /// @dev Transfers `quoteToken` back to bidder and prevents bid from being finalised
    /// @param auctionId `auctionId` of the auction to be canceled
    /// @param bidIndex Index of the bid to be canceled
    function cancelBid(uint256 auctionId, uint256 bidIndex) external {
        Auction storage a = idToAuction[auctionId];
        EncryptedBid storage b = a.bids[bidIndex];
        if (msg.sender != b.sender) {
            revert UnauthorizedCaller();
        }

        // Only allow bid cancellations while not finalized or in the reveal period
        if (block.timestamp >= a.timings.endTimestamp) {
            if (a.data.finalized || block.timestamp <= a.timings.endTimestamp + 24 hours) {
                revert InvalidState();
            }
        }
        uint256 refundAmount = b.quoteAmount;

        // Delete the canceled bid, and replace it with the most recent bid
        a.bids[bidIndex] = a.bids[a.bids.length - 1];
        a.bids.pop();

        emit BidCanceled(auctionId, bidIndex);

        SafeTransferLib.safeTransfer(ERC20(a.params.quoteToken), msg.sender, refundAmount);
    }

    ////////////////////////////////////////////////////////////////////////////
    ///                            UTIL FUNCTIONS                            ///
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Calculates available unlocked tokens for an auction
    /// @dev Uses vesting parameters to account for cliff & linearity
    /// @return tokensAvailable Amount of unlocked `baseToken` at the current time
    /// @param auctionId `auctionId` of the auction bid on
    /// @param baseAmount Amount of total vested `baseToken`
    function tokensAvailableForWithdrawal(uint256 auctionId, uint128 baseAmount)
        public
        view
        returns (uint128 tokensAvailable)
    {
        Auction storage a = idToAuction[auctionId];
        return CommonTokenMath.tokensAvailableAtTime(
            a.timings.vestingStartTimestamp,
            a.timings.vestingEndTimestamp,
            uint32(block.timestamp),
            a.timings.cliffPercent,
            baseAmount
        );
    }

    function computeCommitment(bytes32 message) public pure returns (bytes32) {
        return keccak256(abi.encode(message));
    }

    function computeMessage(uint128 baseAmount, bytes16 salt) external pure returns (bytes32) {
        return bytes32(abi.encodePacked(baseAmount, salt));
    }

    function getTimings(uint256 auctionId) external view returns (Timings memory) {
        return idToAuction[auctionId].timings;
    }

    function getAuctionData(uint256 auctionId) external view returns (AuctionData memory) {
        return idToAuction[auctionId].data;
    }

    function getBid(uint256 auctionId, uint256 bidIndex) external view returns (EncryptedBid memory) {
        return idToAuction[auctionId].bids[bidIndex];
    }
}