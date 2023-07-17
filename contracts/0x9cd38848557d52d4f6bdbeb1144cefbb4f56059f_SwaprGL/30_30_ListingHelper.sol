// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import {ILock} from "../interfaces/ILock.sol";
import {ISwaprWallet} from "../interfaces/ISwaprWallet.sol";

abstract contract ListingHelper {
    using ECDSAUpgradeable for bytes;

    uint256 constant EXP = 1e18;

    uint16 public timeOffset;
    address public theMarketplace;
    ISwaprWallet internal swaprWallet;

    error INV_ADDRS();
    error INV_SIG();

    /// @notice Struct type to encapsulate auction data
    /// @dev depositType is to detect the listing type as proposed listing type
    /// @dev activeDepositType is to check if asset is already listed as current listing type
    struct Auction {
        uint256 nftId; //tokenId owned by seller
        uint256 startingPrice; //starting price for auction
        uint256 buyNowPrice; //price to instantly buy asset from auction
        uint128 startTime; //auction starting time
        uint128 endTime; //auction ending time
        uint128 createdOn; //auction created time
        uint8 depositType; //proposed listing type
        uint8 activeDepositType; //current listing type
        bool toEOA; //either seller want funds to external account or within swapr wallet
        address lock; //address of lock proxy erc721
        address acceptedToken; //accepted token for payment
        address seller; //address of the seller
    }

    /// @notice Struct type to encapsulate order data
    /// @dev depositType is to detect the listing type as proposed listing type
    /// @dev activeDepositType is to check if asset is already listed as current listing type
    struct Order {
        uint256 nftId; //tokenId owned by seller
        uint256 fixedPrice; //price demand for asset
        uint256 maxTokenSell; //maximum percentage of nft a buyer can buy in one go if set to 1 means no splitting allowed
        uint128 maxBuyPerWallet; //maximum amount in percentage a wallet can buy from this listing
        uint128 remainingPart; //internal record to maintaing the remaining splitted asset
        uint128 createdOn; //order created time
        uint8 depositType; //proposed listing type
        uint8 activeDepositType; //current listing type
        bool toEOA; //either seller want funds to external account or within swapr wallet
        address lock; //address of lock proxy erc721
        address acceptedToken; //accepted token for payment
        address seller; //address of the seller
    }

    /// @notice Struct type to accept the specific bidding info
    struct Bid {
        uint256 nftId; //nftId the bid is being made for
        uint256 offerPrice; //bidder's offered price
        uint256 lockedBalance; //bidder's total locked balance within swapr wallet
        uint128 listingEndTime; //updated listing endtime (with added timeOffset) incase the bid was made in last minute
        address bidder; //address of bidder
        address lock; //lock address the bid is being validated for
    }

    /// @notice Struct type to encapsulate payment info
    struct PayNow {
        bool toEOA; //if the seller wants payment in Externally Owned Account it should be true
        address acceptedToken;
        address from; //address the payment is being made from
        address receiver; //the payment should be sent to
        uint256 fromBalance; //current balance of the buyer
        uint256 amount; //amount to be paid
    }

    /// @notice Validates provided listing data if its acceptable to be listed for sale
    /// @dev Can use this before calling createListing to quickly validate
    /// @param listingData must be provided with sellers signature
    /// @return isValid true if succeeds
    function isListableAuction(bytes memory listingData) external view returns (bool isValid) {
        Auction memory auction = _extractAuctionInfo(listingData);
        ILock lockContract = ILock(auction.lock);
        if (lockContract.ownerOf(auction.nftId) == auction.seller) {
            (isValid, , , , ) = _validateListing(auction.seller, auction.depositType, listingData);
        }
    }

    /// @notice Validates provided listing data if its acceptable to be listed for sale
    /// @dev Can use this before calling createListing to quickly validate
    /// @param listingData must be provided with sellers signature
    /// @return isValid true if succeeds
    function isListableOrder(bytes memory listingData) external view returns (bool isValid) {
        Order memory order = _extractOrderInfo(listingData);
        ILock lockContract = ILock(order.lock);
        if (lockContract.ownerOf(order.nftId) == order.seller) {
            (isValid, , , , ) = _validateListing(order.seller, order.depositType, listingData);
        }
    }

    /// @notice Validates the  proposedBid data against the currently activeBid bid
    /// @dev Only marketplace can call this function to provide security
    /// @dev once a bid is validated old bid must be disabled on front-end
    /// @param data must be provided with marketplace signature
    /// @dev isActiveBid => If set to false then only validates proposedBid
    /// @return isValid true means bid is valid to be registered
    /// @return validatedBid validated bid date with addtional time details for future validation
    function validateBid(bytes calldata data) external view returns (bool isValid, Bid memory validatedBid) {
        _checkSignature(theMarketplace, data);
        (bytes memory message, ) = _decodeBytesToBytesBytes(data);
        (bool isActiveBid, bytes memory listingData, bytes memory activeBidData, bytes memory proposedBidData) = abi
            .decode(message, (bool, bytes, bytes, bytes));

        Auction memory auction = _extractAuctionInfo(listingData);
        Bid memory proposedBid = _extractBid(proposedBidData);

        require(auction.depositType == 1, "INV_DEP_TYPE");
        _checkSignature(proposedBid.bidder, proposedBidData);
        if (!isActiveBid) {
            (isValid, proposedBid.listingEndTime) = _validateAsFirstBid(listingData, proposedBid);
        } else {
            Bid memory activeBid = _extractBid(activeBidData);
            (isValid, proposedBid.listingEndTime) = _validateAsLastBid(message, activeBid, proposedBid);
        }
        uint bidderTotalBalance = swaprWallet.getBalance(proposedBid.bidder, auction.acceptedToken);
        if (
            bidderTotalBalance < proposedBid.lockedBalance ||
            bidderTotalBalance - proposedBid.lockedBalance < proposedBid.offerPrice
        ) {
            return (false, validatedBid);
        }
        validatedBid = proposedBid;
    }

    /// @notice Validates provided listing data if its acceptable to claimed by claimant
    /// @dev Can use this before calling claim to quickly validate
    /// @param claimant address of the claimant
    /// @param listingData must be provided with sellers signature
    /// @param lastBid must be provided with bidders signature
    /// @return isValid true if succeeds
    /// @return res reason of failure
    function isClaimable(
        address claimant,
        bytes memory listingData,
        bytes memory lastBid
    ) external view returns (bool isValid, string memory res) {
        (isValid, res) = _validateClaim(claimant, listingData, lastBid);
    }

    /// @notice returns the signer of the provided data
    /// @param dataHash hash of the data
    /// @param signature signature of the data
    /// @return signer address of the signer
    function getSigner(bytes32 dataHash, bytes memory signature) external pure returns (address) {
        return ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(dataHash), signature);
    }

    /// @notice returns the hash of the provided message
    /// @param message message to be hashed
    /// @return messageHash hash of the message
    function toMessageHash(bytes memory message) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(message));
    }

    /// @notice Underlying actual implementation to validate listing
    /// @dev Can validate both the Auction type and Order type
    /// @param sender address of the seller
    /// @param listingType must be either 1 or 2 any other will not be accepted
    /// @param listingData must be provided with sellers signature
    /// @return isValid if true can proceed else get failure reason from res
    /// @return lock address of the lock
    /// @return nftId id of the nft being listed
    /// @return paymentToken address of the token being accepted
    /// @return sig signature of the seller
    function _validateListing(
        address sender,
        uint listingType,
        bytes memory listingData
    ) internal view returns (bool isValid, address lock, uint nftId, address paymentToken, bytes memory sig) {
        _checkSignature(sender, listingData);
        (, bytes memory _sig) = _decodeBytesToBytesBytes(listingData);
        sig = _sig;
        require(listingType == 1 || listingType == 2, "INV_LIST_TYPE");
        if (listingType == 1) {
            //Auction
            (isValid, lock, nftId, paymentToken) = _validateAuctionCapability(listingData);
        } else if (listingType == 2) {
            //Order
            (isValid, lock, nftId, paymentToken) = _validateOrderCapability(listingData);
        }
    }

    /// @notice Internal implementation for the claim validation wrapped to deal with msg.sender
    /// @dev Can use this before calling claim to quickly validate
    /// @param claimant is the user who's claim is being validated
    /// @param listingData must be provided with sellers signature
    /// @param bidData must be provided with bidders signature
    /// @return isValid true if succeeds
    /// @return res reason of failure
    function _validateClaim(
        address claimant,
        bytes memory listingData,
        bytes memory bidData
    ) internal view returns (bool isValid, string memory res) {
        Auction memory auction = _extractAuctionInfo(listingData);
        Bid memory lastBid = _extractBid(bidData);

        _checkSignature(auction.seller, listingData);
        _checkSignature(lastBid.bidder, bidData);
        if (block.timestamp < lastBid.listingEndTime) {
            revert("INV_DATA");
        }
        if (_verify(claimant, listingData)) {
            //for seller
            require(claimant == auction.seller, "INV_CLAIM");
            uint bidderTotalBalance = swaprWallet.getBalance(lastBid.bidder, auction.acceptedToken);
            if (bidderTotalBalance - lastBid.lockedBalance >= lastBid.offerPrice) {
                isValid = true;
            }
        } else if (_verify(claimant, bidData)) {
            //for bidder/buyer
            require(claimant == lastBid.bidder, "INV_CLAIM");
            if (swaprWallet.isNFTLocked(auction.lock, auction.nftId)) {
                isValid = true;
            }
        } else {
            res = "INV_CLAIM";
        }
    }

    /// @notice decodes the Auction type encoded data
    /// @param auctionData encoded auction data
    /// @return auction Auction type decoded data
    function _extractAuctionInfo(bytes memory auctionData) internal pure returns (Auction memory auction) {
        (bytes memory auctionInfo, ) = _decodeBytesToBytesBytes(auctionData);
        auction = abi.decode(auctionInfo, (Auction));
    }

    /// @notice decodes the Order type encoded data
    /// @param orderData encoded order data
    /// @return order Order type decoded data
    function _extractOrderInfo(bytes memory orderData) internal pure returns (Order memory order) {
        (bytes memory orderInfo, ) = _decodeBytesToBytesBytes(orderData);
        order = abi.decode(orderInfo, (Order));
    }

    /// @notice decodes the Bid type encoded data
    /// @param bidData encoded bid data
    /// @return bid Bid type decoded data
    function _extractBid(bytes memory bidData) internal pure returns (Bid memory bid) {
        (bytes memory bidInfo, ) = _decodeBytesToBytesBytes(bidData);
        bid = abi.decode(bidInfo, (Bid));
    }

    /// @notice verifies the signature of the signer
    /// @param signer address of the signer
    /// @param _data data that was signed
    /// @return true if signature is signed by the gived signer
    function _verify(address signer, bytes memory _data) internal view returns (bool) {
        (bytes memory message, bytes memory signature) = _decodeBytesToBytesBytes(_data);
        return
            SignatureCheckerUpgradeable.isValidSignatureNow(
                signer,
                ECDSAUpgradeable.toEthSignedMessageHash(toMessageHash(message)),
                signature
            );
    }

    /// @notice decodes one gived bytes into two bytes variables
    /// @param data bytes to be decoded
    /// @return first bytes variable
    /// @return second bytes variable
    function _decodeBytesToBytesBytes(bytes memory data) internal pure returns (bytes memory, bytes memory) {
        (bytes memory first, bytes memory second) = abi.decode(data, (bytes, bytes));
        return (first, second);
    }

    /// @notice Validates the proposed bid for the auction
    /// @param auction auction data
    /// @param activeBid active bid data
    /// @param proposedBid proposed bid data
    /// @return isValid true if proposed bid is valid
    /// @return proposedEndTime proposed end time for the auction
    function _bidsCrossValidate(
        Auction memory auction,
        Bid memory activeBid,
        Bid memory proposedBid
    ) private view returns (bool isValid, uint128 proposedEndTime) {
        if ((activeBid.listingEndTime < auction.endTime) || (activeBid.listingEndTime < block.timestamp)) {
            return (isValid, proposedEndTime);
        }
        if ((proposedBid.offerPrice < auction.startingPrice) || (activeBid.offerPrice >= proposedBid.offerPrice)) {
            return (isValid, proposedEndTime);
        }
        proposedEndTime = _getProposedEndTime(activeBid.listingEndTime);
        isValid = true;
    }

    /// @notice internal function to get proposed end time
    /// @param listingEndTime end time of the actual listing
    /// @return proposedEndTime proposed end time for the listing
    function _getProposedEndTime(uint128 listingEndTime) private view returns (uint128 proposedEndTime) {
        if (listingEndTime - block.timestamp <= 1 minutes) {
            proposedEndTime = listingEndTime + timeOffset;
        } else {
            proposedEndTime = listingEndTime;
        }
    }

    /// @notice internal implementation to validate only Auction type data
    /// @notice all inputs same as validateListing
    /// @param _listingData encoded listing data
    /// @return isValid true if succeeds
    /// @return lockAddr address of the lock
    /// @return tokenId id of the token
    /// @return paymentToken address of the payment token
    function _validateAuctionCapability(
        bytes memory _listingData
    ) private view returns (bool isValid, address lockAddr, uint tokenId, address paymentToken) {
        Auction memory auction = _extractAuctionInfo(_listingData);
        _checkAddress(auction.seller);
        _checkAddress(auction.lock);
        require(auction.startingPrice != 0 && auction.buyNowPrice > auction.startingPrice, "INV_PRICE");
        require(
            auction.startTime + timeOffset <= auction.endTime &&
                auction.endTime >= block.timestamp + timeOffset &&
                auction.createdOn <= block.timestamp,
            "INV_TIME"
        );
        if (swaprWallet.isNFTLocked(auction.lock, auction.nftId)) {
            require(auction.activeDepositType == 0 || auction.activeDepositType == 3, "ALRD_LISTD");
            isValid = true;
        } else {
            require(auction.depositType == 1, "INV_DEP_TYPE");
            isValid = true;
        }
        lockAddr = auction.lock;
        tokenId = auction.nftId;
        paymentToken = auction.acceptedToken;
    }

    /// @notice internal implementation to validate only Order type data
    /// @notice all inputs same as validateListing
    /// @param _orderData encoded order data
    /// @return isValid true if succeeds
    /// @return lockAddr address of the lock
    /// @return tokenId id of the token
    /// @return paymentToken address of the payment token
    function _validateOrderCapability(
        bytes memory _orderData
    ) private view returns (bool isValid, address lockAddr, uint tokenId, address paymentToken) {
        Order memory order = _extractOrderInfo(_orderData);

        require(
            order.maxTokenSell > 0 &&
                order.maxTokenSell <= EXP &&
                order.maxBuyPerWallet > 0 &&
                order.maxBuyPerWallet <= EXP &&
                order.remainingPart <= EXP &&
                order.fixedPrice != 0,
            "INV_DATA"
        );
        _checkAddress(order.seller);
        _checkAddress(order.lock);
        require(order.createdOn <= block.timestamp, "INV_TIME");
        if (swaprWallet.isNFTLocked(order.lock, order.nftId)) {
            require(order.activeDepositType == 0 || order.activeDepositType == 3, "ALR_LIST");
            isValid = true;
        } else {
            require(order.depositType == 2, "INV_DEP_TYPE");
            isValid = true;
        }
        lockAddr = order.lock;
        tokenId = order.nftId;
        paymentToken = order.acceptedToken;
    }

    /// @notice part of validateBid which validates only if the bid is being placed for the first time
    /// @param listingData encoded listing data
    /// @param bid bid data
    /// @return isValid true if succeeds
    /// @return proposedEndTime proposed end time for the listing
    function _validateAsFirstBid(
        bytes memory listingData,
        Bid memory bid
    ) private view returns (bool isValid, uint128 proposedEndTime) {
        (bytes memory listingInfo, ) = _decodeBytesToBytesBytes(listingData);
        Auction memory auction = _extractAuctionInfo(listingData);
        bytes memory _data = abi.encode(listingInfo, swaprWallet.getNFT(bid.lock, bid.nftId));
        if (!_verify(auction.seller, _data) || auction.endTime < block.timestamp) {
            return (isValid, proposedEndTime);
        }
        proposedEndTime = _getProposedEndTime(auction.endTime);
        if (bid.offerPrice < auction.startingPrice) {
            return (isValid, proposedEndTime);
        }
        isValid = true;
    }

    /// @notice part of validateBid which validates every time after the first bid is placed
    /// @param message encoded message
    /// @param activeBid active bid data
    /// @param proposedBid proposed bid data
    /// @return isValid true if succeeds
    /// @return proposedEndTime proposed end time for the listing
    function _validateAsLastBid(
        bytes memory message,
        Bid memory activeBid,
        Bid memory proposedBid
    ) private view returns (bool isValid, uint128 proposedEndTime) {
        (, bytes memory listingData, bytes memory activeBidData, ) = abi.decode(message, (bool, bytes, bytes, bytes));
        (bytes memory listingInfo, ) = _decodeBytesToBytesBytes(listingData);

        Auction memory auction = _extractAuctionInfo(listingData);
        bytes memory _data = abi.encode(listingInfo, swaprWallet.getNFT(activeBid.lock, activeBid.nftId));
        _checkSignature(auction.seller, _data);
        _checkSignature(activeBid.bidder, activeBidData);
        (isValid, proposedEndTime) = _bidsCrossValidate(auction, activeBid, proposedBid);
    }

    /// @notice internal function to validate if an address is not zero address
    /// @param addr address to validate
    function _checkAddress(address addr) internal pure {
        if (addr == address(0)) {
            revert INV_ADDRS();
        }
    }

    /// @notice internal function to validate if a signature is valid
    /// @param signer address of the signer
    /// @param _data encoded data
    function _checkSignature(address signer, bytes memory _data) internal view {
        if (!_verify(signer, _data)) {
            revert INV_SIG();
        }
    }
}