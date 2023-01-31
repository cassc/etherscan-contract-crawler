// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IZtlDevils } from "./IZtlDevils.sol";
import { IZtlDevilsTreasury } from "./IZtlDevilsTreasury.sol";
import { IWETH } from "./weth/IWETH.sol";

/**
 * @title Zeitls Devil's Auction House
 * Contract is responsible for the initial token auction.
 * Every token will be generated after a successfully conducted auction.
 * The contract is responsible to make each auction fair.
 */
contract ZtlDevilsAuctionHouse is PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;

    event AuctionCreated(uint256 indexed tokenId, uint256 reservePrice);

    event AuctionStarted(uint256 indexed tokenId, uint40 startTime, uint40 endTime);

    event AuctionBid(uint256 indexed tokenId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed tokenId, uint256 endTime);

    event AuctionSettled(uint256 indexed tokenId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint40 timeBuffer);

    event AuctionMinBidIncrementPercentageUpdated(uint8 minBidIncrementPercentage);

    event AuctionWhitelistAddress(address indexed participant, bool state);

    struct Auction {
        // The minimum price for a token
        uint256 reservePrice;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint40 startTime;
        // The time that the auction is scheduled to end
        uint40 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
        // Limited and exclusive auction which is available only for whitelisted addresses
        bool limited;
    }

    // The Devil's token contract
    IZtlDevils public token;

    // Contract for holding auction released funds
    IZtlDevilsTreasury public treasury;

    // The Zeitls Key contract for participation in exlusive auction sales
    IERC721 public zeitls;

    // The address of the WETH contract
    address public weth;

    // The address of the signer for auction participation
    address public signer;

    // The minimum amount of time left in an auction after a new bid is created
    uint40 public timeBuffer;

    // The duration of a single auction
    uint40 public duration;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // Token ID to the auction
    mapping (uint => Auction) public auctions;

    // Addresses who can participate in exclusive auction sales
    mapping (address => bool) public whitelist;

    /**
     * @notice Initialize the auction and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        address _token,
        address _treasury,
        address _zeitls,
        address _signer,
        address _weth,
        uint40 _timeBuffer,
        uint40 _duration,
        uint8 _minBidIncrementPercentage
    ) external initializer {
        require(_token != address(0x0), "Token address can not be zero");
        require(_treasury != address(0x0), "Treasury address can not be zero");
        require(_zeitls != address(0x0), "Zeitls address can not be zero");
        require(_signer != address(0x0), "Signer address can not be zero");
        require(_weth != address(0x0), "WETH address can not be zero");

        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        token = IZtlDevils(_token);
        treasury = IZtlDevilsTreasury(_treasury);
        zeitls = IERC721(_zeitls);
        signer = _signer;
        weth = _weth;
        timeBuffer = _timeBuffer;
        duration = _duration;
        minBidIncrementPercentage = _minBidIncrementPercentage;
    }

    /**
     * @notice Pause the Devil's auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the Devil's auction house.
     * @dev This function can only be called by the owner when the contract is paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint40 _timeBuffer) external onlyOwner {
        timeBuffer = _timeBuffer;
        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;
        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    /**
     * @notice Create an auction.
     * @dev Only callable by the owner.
     */
    function createAuction(uint256 tokenId, uint256 price, bool limited) external onlyOwner whenNotPaused {
        _createAuction(tokenId, price, limited);
    }

    /**
     * @notice Create many auctions with a single invocation.
     * @dev Only callable by the owner.
     */
    function createAuctions(uint256[] calldata tokenIds, uint256[] calldata prices, bool[] calldata limited) external onlyOwner whenNotPaused {
        for (uint i = 0; i < tokenIds.length; i++) {
            _createAuction(tokenIds[i], prices[i], limited[i]);
        }
    }

    /**
     * @notice Return the following minimal amount for a bid.
     */
    function nextBidAmount(uint256 tokenId) external view returns (uint256) {
        Auction memory auction = auctions[tokenId];
        require(auction.reservePrice > 0, "Auction does not exist");
        return _nextBidAmount(auction.amount);
    }

    /**
     * @notice Create a bid for a token, with a given amount. Only permitted addresses with a signature may do a bid.
     * The first bid starts auction countdown and bidding allowed until sale ends.
     * @dev This contract only accepts payment in ETH.
     * The signature is provided by a service provider platform to trustworthy users.
     */
    function bid(uint256 tokenId, bytes calldata signature) external payable whenNotPaused nonReentrant {
        Auction storage auction = auctions[tokenId];
        uint40 time = uint40(block.timestamp);

        require(auction.reservePrice > 0, "Auction does not exist");
        require(!auction.limited || _isInWhitelist(_msgSender()), "Sender is not whitelisted");
        require(msg.value >= auction.reservePrice, "Must send at least reservePrice");
        require(auction.startTime == 0 || time < auction.endTime, "Auction expired");
        require(
            msg.value >= _nextBidAmount(auction.amount),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );

        // pad address 20 bytes into 32 bytes
        bytes32 hash = bytes32(uint256(uint160(_msgSender())) << 96).toEthSignedMessageHash();
        require(_verifySignature(hash, signature), "Wrong signature is provided");

        // the first bid on the auction, start the countdown
        if (auction.startTime == 0) {
            auction.startTime = time;
            auction.endTime = auction.startTime + duration;
            emit AuctionStarted(tokenId, auction.startTime, auction.endTime);
        }

        address payable lastBidder = auction.bidder;

        // refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, auction.amount);
        }

        auction.amount = msg.value;
        auction.bidder = payable(_msgSender());

        // extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = auction.endTime - time < timeBuffer;
        if (extended) {
            auction.endTime = time + timeBuffer;
        }

        emit AuctionBid(tokenId, _msgSender(), msg.value, extended);

        if (extended) {
            emit AuctionExtended(tokenId, auction.endTime);
        }
    }

    function settleAuction(uint256 tokenId) external {
        _settleAuction(tokenId);
    }

    /**
     * @notice Makes a token purchase with off-chain permission with a dedicated price.
     * The permission is time limited and valid until expire time.
     */
    function purchase(uint256 tokenId, uint256 price, uint40 expireTime, bytes calldata signature) external payable {
        require(block.timestamp <= expireTime, "Signature with a fixed price has been expired");
        require(msg.value >= price, "Insufficient funds for a purchase");
        require(auctions[tokenId].reservePrice == 0, "Token already listed");
        require(!token.exists(tokenId), "Token already exist");

        bytes32 hash = keccak256(
            abi.encodePacked(tokenId, price, expireTime)
        ).toEthSignedMessageHash();

        require(_verifySignature(hash, signature), "Wrong signature is provided");

        token.mint(_msgSender(), tokenId);

        treasury.keep{ value: msg.value }();

        emit AuctionSettled(tokenId, _msgSender(), msg.value);
    }

    /**
     * @notice Add addresses to the contract whitelist which allows participation in exclusive sales.
     */
    function addWhitelistAddress(address[] calldata addresses) external onlyOwner {
        require(addresses.length > 0, "Addresses cannot be empty");

        for (uint i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
            emit AuctionWhitelistAddress(addresses[i], true);
        }
    }

    /**
     * @notice Remove addresses from the contract whitelist and denies participation in exclusive sales.
     */
    function removeWhitelistAddress(address[] calldata addresses) external onlyOwner {
        require(addresses.length > 0, "Addresses cannot be empty");

        for (uint i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
            emit AuctionWhitelistAddress(addresses[i], false);
        }
    }

    /**
     * @notice Creates the auction for a token with a reserve price.
     */
    function _createAuction(uint tokenId, uint reservePrice, bool limited) internal {
        require(reservePrice > 0, "Reserve price must be defined");
        require(auctions[tokenId].reservePrice == 0, "Auction already exist");
        require(!token.exists(tokenId), "Token already exist");

        Auction memory auction = Auction({
            reservePrice: reservePrice,
            amount: 0,
            startTime: 0,
            endTime: 0,
            bidder: payable(0),
            settled: false,
            limited: limited
        });

        auctions[tokenId] = auction;

        emit AuctionCreated(tokenId, reservePrice);
    }

    /**
     * @notice Computes the next bid amount using the contract increment percentage.
     */
    function _nextBidAmount(uint256 amount) internal view returns (uint256) {
        return amount + ((amount * minBidIncrementPercentage) / 100);
    }

    /**
     * @notice Settles an auction, finalizing the bid and paying out to the owner.
     */
    function _settleAuction(uint256 tokenId) internal {
        Auction memory auction = auctions[tokenId];

        require(auction.startTime != 0, "Auction hasn't begun");
        require(!auction.settled, "Auction has already been settled");
        require(block.timestamp >= auction.endTime, "Auction hasn't completed");

        // settle auction and make them unavailable
        auctions[tokenId].settled = true;

        token.mint(auction.bidder, tokenId);

        if (auction.amount > 0) {
            treasury.keep{ value: auction.amount }();
        }

        emit AuctionSettled(tokenId, auction.bidder, auction.amount);
    }

    /**
     * @notice Checks do address has access to exclusive sales.
     * @dev Look into the contract whitelist first otherwise check for Zeitls Key.
     */
    function _isInWhitelist(address _address) internal view returns (bool) {
        return whitelist[_address] || zeitls.balanceOf(_msgSender()) > 0;
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    /**
    * @dev Verify provided signature, it must be signed by contract owner
    */
    function _verifySignature(bytes32 hash, bytes calldata signature) view internal returns (bool) {
        address recovered = hash.recover(signature);
        return recovered == signer;
    }
}