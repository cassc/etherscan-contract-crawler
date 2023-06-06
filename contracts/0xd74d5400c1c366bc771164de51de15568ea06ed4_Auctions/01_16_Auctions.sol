// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';

import {IWETH9} from './imports/IWETH9.sol';

struct ProvisionalBid {
    uint256 initialPrice;
    uint256 reservePrice;
    address guarantor;
    uint64 guarantorFeeMultiplier;
    uint8 auctionDuration;
    address nft;
    uint256 nftId;
    uint256 validUntil;
    bytes signature;
}

// 32 bytes per slot
struct Auction {
    // first slot
    address seller; // 20 bytes
    uint48 initialPrice; // 6 bytes
    uint48 reservePrice; // 6 bytes
    // second slot
    uint256 nftId; // 32 bytes
    // third slot
    address nft; // 20 bytes
    uint48 endTime; // 6 bytes
    uint48 startTime; // 6 bytes
    // fourth slot
    address payable guarantorFeeReceiver; // 20 bytes
    uint64 guarantorFeeMultiplier; // 8 bytes
    bool sold; // 1 byte
}

contract Auctions is Ownable, ERC721Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using SafeCast for uint256;

    mapping(bytes32 => Auction) public auctions;
    uint256 public protocolFeeMultiplier;

    uint256 public immutable TIME_BETWEEN_PRICE_UPDATES;
    address public immutable WETH_CONTRACT;

    uint256 internal constant ETH_VALUES_PRECISION = 1e10;
    uint256 internal constant MAX_AUCTION_DURATION = 14 days;
    uint256 internal constant MIN_AUCTION_DURATION = 3 days;

    event AuctionStarted(
        bytes32 indexed auctionId,
        address indexed nft,
        uint256 nftId,
        address indexed seller
    );
    event AuctionEnded(
        bytes32 indexed auctionId,
        address indexed buyer,
        uint256 amount
    );

    error AuctionAlreadyEnded();
    error AuctionAlreadySold();
    error AuctionDurationTooLong();
    error AuctionDurationTooShort();
    error AuctionNotFound();
    error AuctionNotYetEnded();
    error AuctionShouldBeGuarantor();
    error AuctionShouldBeSeller();
    error BidNotHighEnough();
    error InvalidSignature();
    error SignatureExpired();
    error SignatureShouldHaveReservePrice();

    constructor(
        IWETH9 _weth,
        uint256 _protocolFeeMultiplier,
        uint256 _timeBetweenPriceUpdates
    ) {
        WETH_CONTRACT = address(_weth);
        protocolFeeMultiplier = _protocolFeeMultiplier;
        TIME_BETWEEN_PRICE_UPDATES = _timeBetweenPriceUpdates;
    }

    receive() external payable {}

    function createAuction(
        ProvisionalBid calldata provisionalBid
    ) external payable nonReentrant returns (bytes32 auctionId) {
        isDataValid(provisionalBid);

        uint256 duration = (provisionalBid.auctionDuration * 1 days);

        if (duration > MAX_AUCTION_DURATION)
            revert AuctionDurationTooLong();

        if (duration < MIN_AUCTION_DURATION)
            revert AuctionDurationTooShort();

        Auction memory auction = Auction({
            seller: msg.sender,
            nft: provisionalBid.nft,
            nftId: provisionalBid.nftId,
            guarantorFeeReceiver: payable(provisionalBid.guarantor),
            guarantorFeeMultiplier: provisionalBid.guarantorFeeMultiplier,
            initialPrice: (provisionalBid.initialPrice / ETH_VALUES_PRECISION)
                .toUint48(),
            reservePrice: (provisionalBid.reservePrice /
                ETH_VALUES_PRECISION).toUint48(),
            startTime: block.timestamp.toUint48(),
            endTime: (block.timestamp + duration).toUint48(),
            sold: false
        });

        auctionId = createId(
            provisionalBid.nft,
            provisionalBid.nftId,
            auction.seller
        );
        auctions[auctionId] = auction;

        IERC721(provisionalBid.nft).safeTransferFrom(
            auction.seller,
            address(this),
            provisionalBid.nftId
        );

        // Pay the reserve price to the auction owner.
        if (provisionalBid.guarantor != auction.seller) {
            uint256 reservePrice = provisionalBid.reservePrice;
            IERC20(WETH_CONTRACT).safeTransferFrom(
                provisionalBid.guarantor,
                address(this),
                reservePrice
            );
            IWETH9(WETH_CONTRACT).withdraw(reservePrice);
            safeEthSend(auction.seller, reservePrice);
        }

        emit AuctionStarted(
            auctionId,
            auction.nft,
            auction.nftId,
            auction.seller
        );
    }

    function buy(bytes32 auctionId) external payable nonReentrant {
        Auction memory auction = auctions[auctionId];

        if (auction.seller == address(0)) revert AuctionNotFound();

        if (auction.sold) revert AuctionAlreadySold();

        // Revert the call if the bidding
        // period is over.
        if (block.timestamp > auction.endTime) revert AuctionAlreadyEnded();

        // If the bid is not higher, send the
        // money back (the revert statement
        // will revert all changes in this
        // function execution including
        // it having received the money).
        if (msg.value < getBidPrice(auction)) revert BidNotHighEnough();

        auctions[auctionId].sold = true;
        address buyer = msg.sender;
        uint256 amount = msg.value;

        // Pay the auction amounts.
        bool hasGuarantor = auction.guarantorFeeReceiver != auction.seller;
        uint256 reservePriceWei = uint256(auction.reservePrice) *
            ETH_VALUES_PRECISION;
        uint256 finalAmount = hasGuarantor ? amount - reservePriceWei : amount;
        uint256 protocolFeeAmount = (finalAmount * protocolFeeMultiplier) / 1 ether;
        uint256 guarantorFeeAmount;
        if (hasGuarantor) {
            guarantorFeeAmount = (finalAmount * auction.guarantorFeeMultiplier) / 1 ether;
        }

        safeEthSend(owner(), protocolFeeAmount);
        safeEthSend(
            auction.seller,
            finalAmount - protocolFeeAmount - guarantorFeeAmount
        );

        if (hasGuarantor) {
            uint256 guarantorAmount = guarantorFeeAmount + reservePriceWei;
            safeEthSend(WETH_CONTRACT, guarantorAmount);
            IERC20(WETH_CONTRACT).safeTransfer(
                auction.guarantorFeeReceiver,
                guarantorAmount
            );
        }

        // Pay the NFTs to the highest bidder.
        IERC721(auction.nft).safeTransferFrom(
            address(this),
            buyer,
            auction.nftId
        );
        emit AuctionEnded(auctionId, buyer, amount);
    }

    function finishAuction(bytes32 auctionId) external {
        Auction memory auction = auctions[auctionId];

        if (auction.seller == address(0)) revert AuctionNotFound();

        if (auction.sold) revert AuctionAlreadySold();

        if (block.timestamp < auction.endTime) revert AuctionNotYetEnded();

        // Pay the NFTs to the guarantor.
        IERC721(auction.nft).safeTransferFrom(
            address(this),
            auction.guarantorFeeReceiver,
            auction.nftId
        );

        uint256 reservePriceWei = uint256(auction.reservePrice) *
            ETH_VALUES_PRECISION;
        emit AuctionEnded(
            auctionId,
            auction.guarantorFeeReceiver,
            reservePriceWei
        );
    }

    function setProtocolFeeMultiplier(
        uint256 _protocolFeeMultiplier
    ) external onlyOwner {
        protocolFeeMultiplier = _protocolFeeMultiplier;
    }

    function getBidPrice(Auction memory auction) public view returns (uint256) {
        return getBidPriceIn(auction, block.timestamp - auction.startTime);
    }

    function getBidPriceIn(
        Auction memory auction,
        uint256 timePassed
    ) public view returns (uint256) {
        uint256 maxPrice = uint256(auction.initialPrice) * ETH_VALUES_PRECISION;
        uint256 minPrice = uint256(auction.reservePrice) * ETH_VALUES_PRECISION;

        uint256 priceChangePerInterval = ((maxPrice - minPrice) * TIME_BETWEEN_PRICE_UPDATES)
            / (auction.endTime - auction.startTime);
        uint256 subtraction = priceChangePerInterval *
            (timePassed / TIME_BETWEEN_PRICE_UPDATES);

        if (subtraction > maxPrice - minPrice) return minPrice;

        unchecked {
            return maxPrice - subtraction;
        }
    }

    function getNextBidPrice(Auction memory auction) public view returns (uint256) {
        return getBidPriceIn(
            auction,
            block.timestamp - auction.startTime + TIME_BETWEEN_PRICE_UPDATES
        );
    }

    function isDataValid(ProvisionalBid memory _provisionalBid) public view {
        // If the guarantor is the NFT seller, they are selling without a provisional bid
        if (_provisionalBid.guarantor == msg.sender) return;

        if (_provisionalBid.reservePrice == 0)
            revert SignatureShouldHaveReservePrice();

        if (block.timestamp > _provisionalBid.validUntil)
            revert SignatureExpired();

        bytes32 msgHash = keccak256(
            abi.encode(
                _provisionalBid.reservePrice,
                _provisionalBid.initialPrice,
                _provisionalBid.auctionDuration,
                _provisionalBid.guarantorFeeMultiplier,
                _provisionalBid.nft,
                _provisionalBid.nftId,
                _provisionalBid.validUntil
            )
        );

        if (
            !verifySignature(
                msgHash,
                _provisionalBid.signature,
                _provisionalBid.guarantor
            )
        ) revert InvalidSignature();
    }

    function safeEthSend(address recipient, uint256 howMuch) internal {
        (bool success, ) = payable(recipient).call{value: howMuch}('');
        require(success, 'Call with value failed');
    }

    function createId(
        address nft,
        uint256 nftId,
        address seller
    ) internal view returns (bytes32 blobId) {
        blobId = keccak256(abi.encode(nft, nftId, seller, block.number));
    }

    function verifySignature(
        bytes32 hash,
        bytes memory signature,
        address signer
    ) internal pure returns (bool) {
        return hash.toEthSignedMessageHash().recover(signature) == signer;
    }
}