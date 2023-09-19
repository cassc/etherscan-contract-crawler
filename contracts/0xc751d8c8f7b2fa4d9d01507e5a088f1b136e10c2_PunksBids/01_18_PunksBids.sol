// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./lib/EIP712.sol";
import "./lib/Errors.sol";
import "./lib/StringUtils.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IPunksBids.sol";
import "./interfaces/ICryptoPunksMarket.sol";
import "./interfaces/ICryptoPunksData.sol";

import {Input, Bid} from "./lib/BidStructs.sol";

/**
 * @title PunksBids
 * @author 0xd0s.eth
 * @notice Allows bidding with WETH on specific CryptoPunks or attributes
 * @dev Lot of lines of code were taken from the Blur Marketplace, as a source of trust and good architecture example
 */
contract PunksBids is IPunksBids, EIP712, Pausable, Ownable2Step {
    using StringUtils for *;

    function unpause() external override onlyOwner {
        _unpause();
    }

    function pause() external override onlyOwner {
        _pause();
    }

    /* Constants */
    string private constant NAME = "PunksBids";
    string private constant VERSION = "1.0";
    uint256 private constant INVERSE_BASIS_POINT = 1_000; // Fees
    uint256 private constant MAX_FEE_RATE = 100;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant CRYPTOPUNKS_MARKETPLACE = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    address private constant CRYPTOPUNKS_DATA = 0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2;
    string private constant ATTRIBUTES_SEPARATOR = ", ";

    /* Storage */
    mapping(bytes32 => bool) public cancelledOrFilled;
    mapping(address => uint256) public nonces;

    /**
     * @dev feeRate is applied when a Punk wasn't directly offered to PunksBids
     * @dev localFeeRate is applied when a Punk was directly offered to PunksBids
     */
    uint256 public feeRate = 10;
    uint256 public localFeeRate = 5;

    /* Events */
    event BidMatched(address indexed maker, address indexed taker, Bid bid, uint256 price, bytes32 bidHash);

    event BidCancelled(bytes32 hash);
    event NonceIncremented(address indexed bidder, uint256 newNonce);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event FeeRateUpdated(uint256 feeRate);
    event LocalFeeRateUpdated(uint256 localFeeRate);

    constructor() {
        _domainSeparator = _hashDomain(
            EIP712Domain({name: NAME, version: VERSION, chainId: block.chainid, verifyingContract: address(this)})
        );
    }

    receive() external payable {}
    fallback() external payable {}

    /**
     * @dev Match a Bid with a Punk offered for sale, ensuring validity of the match, and execute all associated state transitions.
     * @param buy Buy input
     * @param punkIndex Index of the Punk to be buy on the CryptoPunks Marketplace
     */
    function executeMatch(Input calldata buy, uint256 punkIndex) external override whenNotPaused {
        bytes32 bidHash = _hashBid(buy.bid, nonces[buy.bid.bidder]);

        if (!_validateBidParameters(buy.bid, bidHash)) {
            revert InvalidBidParameters(buy.bid);
        }

        if (!_validateSignature(buy, bidHash)) {
            revert InvalidSignature(buy);
        }

        (uint256 price, uint256 punkPrice, address seller) = _canMatchBidAndPunk(buy.bid, punkIndex);

        cancelledOrFilled[bidHash] = true;

        _executeWETHTransfer(buy.bid.bidder, price);

        _executeBuyPunk(buy.bid.bidder, punkIndex, punkPrice);

        emit BidMatched(buy.bid.bidder, seller, buy.bid, price, bidHash);
    }

    /**
     * @dev Cancel a bid, preventing it from being matched. Must be called by the bidder
     * @param bid Bid to cancel
     */
    function cancelBid(Bid calldata bid) public override {
        if (msg.sender != bid.bidder) {
            revert SenderNotBidder(msg.sender, bid.bidder);
        }

        bytes32 hash = _hashBid(bid, nonces[bid.bidder]);

        if (cancelledOrFilled[hash]) {
            revert BidAlreadyCancelledOrFilled(bid);
        }

        cancelledOrFilled[hash] = true;
        emit BidCancelled(hash);
    }

    /**
     * @dev Cancel multiple bids
     * @param bids Bids to cancel
     */
    function cancelBids(Bid[] calldata bids) external override {
        for (uint256 i = 0; i < bids.length; i++) {
            cancelBid(bids[i]);
        }
    }

    /**
     * @dev Cancel all current bids for a user, preventing them from being matched. Must be called by the bidder
     */
    function incrementNonce() external override {
        emit NonceIncremented(msg.sender, ++nonces[msg.sender]);
    }

    /**
     * @dev Sets a new fee rate
     * @param _feeRate The new fee rate
     */
    function setFeeRate(uint256 _feeRate) external onlyOwner {
        if (_feeRate > MAX_FEE_RATE) {
            revert FeeRateTooHigh(_feeRate);
        }

        feeRate = _feeRate;

        emit FeeRateUpdated(feeRate);
    }

    /**
     * @dev Sets a new local fee rate
     * @param _localFeeRate The new fee rate
     */
    function setLocalFeeRate(uint256 _localFeeRate) external onlyOwner {
        if (_localFeeRate > MAX_FEE_RATE) {
            revert FeeRateTooHigh(_localFeeRate);
        }
        
        localFeeRate = _localFeeRate;

        emit LocalFeeRateUpdated(localFeeRate);
    }

    /**
     * @dev Withdraw accumulated ETH fees
     * @param recipient The recipient of the fees
     */
    function withdrawFees(address recipient) external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = recipient.call{value: amount}("");
        if (!success) {
            revert ETHTransferFailed(recipient);
        }

        emit FeesWithdrawn(recipient, amount);
    }

    /* Internal Functions */

    /**
     * @dev Verify the validity of the bid parameters
     * @param bid Bid
     * @param bidHash Hash of bid
     * @return True if Bid parameters are valid
     */
    function _validateBidParameters(Bid calldata bid, bytes32 bidHash) internal view returns (bool) {
        return bid.bidder != address(0) && !cancelledOrFilled[bidHash] && bid.listingTime < block.timestamp
            && block.timestamp < bid.expirationTime;
    }

    /**
     * @dev Verify the validity of the signature
     * @param input Signed Bid
     * @param bidHash Hash of bid
     * @return True if signature matches with Bid or if the msg.sender is the bidder
     */
    function _validateSignature(Input calldata input, bytes32 bidHash) internal view returns (bool) {
        return
            input.bid.bidder == msg.sender || input.bid.bidder == ECDSA.recover(_hashToSign(bidHash), input.v, input.r, input.s);
    }

    /**
     * @dev Checks that the Punk and the Bid can be matched and get sale parameters
     * @param bid Bid
     * @param punkIndex Punk index
     * @return price Price to be paid by the bidder
     * @return punkPrice Minimum value to be paid to buy the Punk on the official marketplace
     * @return seller Punk Owner
     */
    function _canMatchBidAndPunk(Bid calldata bid, uint256 punkIndex)
        internal
        view
        returns (uint256 price, uint256 punkPrice, address seller)
    {
        (price, punkPrice, seller) = _canBuyPunk(bid, punkIndex);

        if (!_validatePunkIndex(bid, uint16(punkIndex))) {
            revert InvalidPunkIndex(punkIndex);
        }

        /* Retrieve Punk attributes */
        string memory punkAttributesString = ICryptoPunksData(CRYPTOPUNKS_DATA).punkAttributes(uint16(punkIndex));
        StringUtils.Slice[] memory punkAttributes = _getAttributesStringToSliceArray(punkAttributesString);

        /* Checks Punk base type. */
        if (bytes(bid.baseType).length != 0) {
            if (!punkAttributes[0].contains(bid.baseType.toSlice())) {
                revert InvalidPunkBaseType();
            }
        }

        /* Checks attributes count. */
        if (bid.attributesCountEnabled) {
            /* -1 to take account of base type. */
            uint8 punkAttributesCount = uint8(punkAttributes.length - 1);
            if (punkAttributesCount != bid.attributesCount) {
                revert InvalidPunkAttributesCount(punkAttributesCount, bid.attributesCount);
            }
        }

        /* Compare Bid attributes with Punk attributes. */
        if (bytes(bid.attributes).length != 0) {
            StringUtils.Slice memory currentBidAttribute = "".toSlice();
            StringUtils.Slice memory currentPunkAttribute = "".toSlice();
            StringUtils.Slice[] memory bidAttributes = _getAttributesStringToSliceArray(bid.attributes);
            uint256 attributeOffset = 1; // We skip base type

            for (uint256 i; i < bidAttributes.length; i++) {
                bool hasAttribute = false;
                currentBidAttribute = bidAttributes[i];

                for (uint256 j = attributeOffset; j < punkAttributes.length; j++) {
                    currentPunkAttribute = punkAttributes[j];
                    if (currentBidAttribute.equals(currentPunkAttribute)) {
                        hasAttribute = true;
                        attributeOffset = j + 1;
                        break;
                    }
                }

                if (!hasAttribute) {
                    revert PunkMissingAttributes();
                }
            }
        }
    }

    /**
     * @dev Checks that the Punk can be bought and get sale parameters
     * @param bid Bid
     * @param punkIndex Punk index
     * @return price Price to be paid by the bidder
     * @return punkPrice Minimum value to be paid to buy the Punk on the official marketplace
     * @return seller Punk Owner
     */
    function _canBuyPunk(Bid calldata bid, uint256 punkIndex)
        internal
        view
        returns (uint256 price, uint256 punkPrice, address seller)
    {
        (bool isForSale,, address owner, uint256 minValue, address onlySellTo) =
            ICryptoPunksMarket(CRYPTOPUNKS_MARKETPLACE).punksOfferedForSale(punkIndex);

        if (!isForSale) {
            revert PunkNotForSale(punkIndex);
        }
        if (onlySellTo != address(0) && onlySellTo != address(this)) {
            revert PunkNotGloballyForSale(punkIndex, onlySellTo);
        }

        seller = owner;
        punkPrice = minValue;

        uint256 currentFeeRate = onlySellTo == address(this) ? localFeeRate : feeRate;
        price = INVERSE_BASIS_POINT * punkPrice / (INVERSE_BASIS_POINT - currentFeeRate);

        if (price > bid.amount) {
            revert BidAmountTooLow(price, bid.amount);
        }
    }

    /**
     * @dev Verify the validity of the Punk index
     * @param bid Bid
     * @param punkIndex Punk index
     * @return True if Punk index matches with Bid parameters
     */
    function _validatePunkIndex(Bid calldata bid, uint16 punkIndex) internal pure returns (bool) {
        /* If there is an index list, only checks that punkIndex is in this list. */
        if (bid.indexes.length != 0) {
            for (uint256 i; i < bid.indexes.length; i++) {
                if (punkIndex == bid.indexes[i]) {
                    return true;
                }
            }
            revert PunkNotSelected(punkIndex);
        }

        if (bid.excludedIndexes.length != 0) {
            for (uint256 i; i < bid.excludedIndexes.length; i++) {
                if (punkIndex == bid.excludedIndexes[i]) {
                    revert PunkExcluded(punkIndex);
                }
            }
        }

        return (bid.maxIndex == 0 || punkIndex <= bid.maxIndex) && (bid.modulo == 0 || punkIndex % bid.modulo == 0);
    }

    /**
     * @dev Execute WETH transfer and withdraw for ETH
     * @param bidder Bidder
     * @param price Price to be paid by the bidder
     */
    function _executeWETHTransfer(address bidder, uint256 price) internal {
        IWETH(WETH).transferFrom(bidder, address(this), price);

        IWETH(WETH).withdraw(price);
    }

    /**
     * @dev Execute Buy of the Punk
     * @param bidder Bidder
     * @param punkIndex Punk index
     * @param punkPrice Punk price
     */
    function _executeBuyPunk(address bidder, uint256 punkIndex, uint256 punkPrice) internal {
        try ICryptoPunksMarket(CRYPTOPUNKS_MARKETPLACE).buyPunk{value: punkPrice}(punkIndex) {}
        catch {
            revert BuyPunkFailed(punkIndex);
        }

        try ICryptoPunksMarket(CRYPTOPUNKS_MARKETPLACE).transferPunk(bidder, punkIndex) {}
        catch {
            revert TransferPunkFailed(punkIndex);
        }
    }

    /**
     * @dev Split a string to an array of StringUtils.Slice
     * @param arrayString Array as a string
     * @return Array of StringUtils.Slice for each attributes in arrayString
     */
    function _getAttributesStringToSliceArray(string memory arrayString)
        internal
        pure
        returns (StringUtils.Slice[] memory)
    {
        StringUtils.Slice memory s = arrayString.toSlice();
        StringUtils.Slice memory delim = ATTRIBUTES_SEPARATOR.toSlice();
        StringUtils.Slice[] memory parts = new StringUtils.Slice[](s.count(delim) + 1);
        for (uint256 i; i < parts.length; i++) {
            parts[i] = s.split(delim);
        }
        return parts;
    }
}