// SPDX-License-Identifier: MIT

// @title:     MOAR
// @desc:      "MOAR by Joan Cornellà is an unusual mansion in the metaverse proudly presented by FWENCLUB, where 5,555 creatures with their souls minted with the ERC721 blockchain as NFTs. Each of these "peacefully-living-together" humans, cyborgs or even zombies, is unique, hand-drawn by Spanish artist Joan Cornellà using over 200 unique attributes. You may even find shops, games, virtual exhibitions … and MOAR!"
// @twitter:   https://twitter.com/fwenclub
// @instagram: https://instagram.com/fwenclub
// @discord:   https://discord.gg/fwenclub
// @url:       https://www.fwenclub.com/

/*
* ███████╗░██╗░░░░░░░██╗███████╗███╗░░██╗░█████╗░██╗░░░░░██╗░░░██╗██████╗░
* ██╔════╝░██║░░██╗░░██║██╔════╝████╗░██║██╔══██╗██║░░░░░██║░░░██║██╔══██╗
* █████╗░░░╚██╗████╗██╔╝█████╗░░██╔██╗██║██║░░╚═╝██║░░░░░██║░░░██║██████╦╝
* ██╔══╝░░░░████╔═████║░██╔══╝░░██║╚████║██║░░██╗██║░░░░░██║░░░██║██╔══██╗
* ██║░░░░░░░╚██╔╝░╚██╔╝░███████╗██║░╚███║╚█████╔╝███████╗╚██████╔╝██████╦╝
* ╚═╝░░░░░░░░╚═╝░░░╚═╝░░╚══════╝╚═╝░░╚══╝░╚════╝░╚══════╝░╚═════╝░╚═════╝░
*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MoarBase.sol";

error InvalidSaleOn();
error InvalidTime();
error ContractBidder();
error ExceedMaxSupply();
error ExceedMaxTicket();
error ExceedAuctionSupply();
error ExceedDiamondHandSupply();
error InvalidPayment();
error InvalidSignature();
error WithdrawFailed();

contract Moar is MoarBase, ReentrancyGuard {
    // ===== Provenance ======
    bytes32 public provenance;

    // ================ Public Sales ================
    bool public saleOn;
    mapping(address => uint256) public publicMints;

    // ========= Public Mints =========
    struct Tier {
        uint256 startTime;
        uint256 duration;
        uint256 maxTicketNum;
        uint256 ticketPrice;
    }
    mapping(uint256 => Tier) public tiers;

    // =============================== Diamond Hand ================================
    uint256 public constant DIAMOND_HAND_ID = uint256(keccak256("DIAMOND_HAND_ID"));

    // ========================== Dutch Auction ===========================
    uint256 public constant DUTCH_AUCTION_MAX_TICKET = 2;
    uint256 public constant DUTCH_AUCTION_START_PRICE = 0.5 ether;
    uint256 public constant DUTCH_AUCTION_END_PRICE = 0.1 ether;
    uint256 public constant DUTCH_AUCTION_PRICE_CURVE_LENGTH = 180 minutes;
    uint256 public constant DUTCH_AUCTION_DROP_INTERVAL = 45 minutes;
    uint256 public constant DUTCH_AUCTION_DROP_PER_STEP = (DUTCH_AUCTION_START_PRICE - DUTCH_AUCTION_END_PRICE) / (DUTCH_AUCTION_PRICE_CURVE_LENGTH / DUTCH_AUCTION_DROP_INTERVAL);

    uint256 public dutchAuctionStartTime = 1649335500; // Apr 7, 2022, 2045 HKT

    // ==================== Supply ====================
    uint256 public constant maxSupply = 5555;
    uint256 public totalSupply;
    uint256 public constant diamondHandMaxSupply = 1644; // 40% of the dutch auction qty
    uint256 public constant DHDAMaxSupply = 4110; // 74% of the total qty - 1 (English Auction)
    uint256 public DHDATotalSupply;

    // ======== Roles =========
    address private _authority;

    // ========================= Refund ==========================
    event refundFailed(address indexed recipient, uint256 amount);

    /**
     * @dev Constructor function. Mints token #1 to `owner`, updates `totalSupply`
     * @param authority signature authority
     * @param admin admin role
     * @param royaltyAddress royalty fee receiver address
     */
    constructor(address authority, address admin, address royaltyAddress) MoarBase(admin, royaltyAddress) {
        _authority = authority;

        _mint(owner(), 1);
        totalSupply += 1;
    }

    /**
     * @dev Validates `saleOn`
     */    
    modifier isSaleOn(bool saleOn_) {
        if (saleOn != saleOn_) { revert InvalidSaleOn(); }
        _;
    }

    /**
     * @dev Validates time for tier
     * @param tierId Id of tier to validate
     */    
    modifier validTime(uint256 tierId) {
        uint256 startTime = tiers[tierId].startTime;
        uint256 endTime = startTime + tiers[tierId].duration * 1 seconds;
        if (block.timestamp < startTime || block.timestamp >= endTime) { revert InvalidTime(); }
        _;
    }

    /**
     * @dev Validates if caller is a contract
     */    
    modifier validateCaller() {
        if (tx.origin != msg.sender) { revert ContractBidder(); }
        _;
    }

    /**
     * @dev Sets the provenance.
     * @param provenance_ provenance of public mint token images
     *
     * Requirements:
     *
     * - the caller must be `owner`.
     */
    function setProvenance(bytes32 provenance_) external onlyAdmin {
        provenance = provenance_;
    }

    /**
     * @dev Toggles `saleOn`
     *
     * Requirements:
     *
     * - the caller must be `owner`.
     */
    function toggleFlag(uint256 flag) public override onlyAdmin {
        if (flag == uint256(keccak256("SALE")))
            saleOn = !saleOn;
        else
            super.toggleFlag(flag);
    }

    /**
     * @dev Sets `_authority` address
     * @param authority new authority address to set
     *
     * Requirements:
     *
     * - `saleOn` must be false,
     * - the caller must be `owner`.
     */
    function setAuthority( address authority) external isSaleOn(false) onlyOwner {
        _authority = authority;
    }

    /**
     * @dev Sets dutch auction start time
     * @param startTime start time to be set
     *
     * Requirements:
     *
     * - `saleOn` must be false,
     * - the caller must be `owner`.
     */
    function setDutchAuctionStartTime( uint256 startTime) external isSaleOn(false) onlyAdmin {
        dutchAuctionStartTime = startTime;
    }

    /**
     * @dev Configs sales
     * @param tierIds ids of sale tiers
     * @param tierStartTimes start times of sale tiers
     * @param tierDurations durations of sale tiers
     * @param tierMaxTicketNums max ticket numbers per user of sale tiers
     * @param tierTicketPrices ticket prices of sale tiers
     *
     * Requirements:
     *
     * - the caller must be `_admin`.
     */
    function configSales(
        uint256[] memory tierIds,
        uint256[] memory tierStartTimes,
        uint256[] memory tierDurations,
        uint256[] memory tierMaxTicketNums,
        uint256[] memory tierTicketPrices
    ) external onlyAdmin isSaleOn(false) {
        if (
            tierIds.length != tierStartTimes.length ||
            tierIds.length != tierDurations.length ||
            tierIds.length != tierMaxTicketNums.length ||
            tierIds.length != tierTicketPrices.length
        ) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < tierIds.length; i++) {
            tiers[tierIds[i]].startTime = tierStartTimes[i];
            tiers[tierIds[i]].duration = tierDurations[i];
            tiers[tierIds[i]].maxTicketNum = tierMaxTicketNums[i];
            tiers[tierIds[i]].ticketPrice = tierTicketPrices[i];
        }
    }

    /**
     * @dev Creates a new token for every address in `tos`. TokenIds will be automatically assigned
     * @param tos owners of new tokens
     *
     * Requirements:
     *
     * - `saleOn` must be false,
     * - the caller must be `_admin`.
     */
    function privateMint(address[] memory tos) external onlyAdmin isSaleOn(false) {
        for (uint256 i = 0; i < tos.length; i++) {
            _mint(tos[i], totalSupply + 1 + i);
        }
        totalSupply += tos.length;

        if (totalSupply > maxSupply) { revert ExceedMaxSupply(); }
    }

    /**
     * @dev Creates new tokens for public mint. TokenIds will be automatically assigned
     * 
     * @param maxNum  max ticket number per user 
     * @param ticketNum number of tokens to create
     * @param price price of each token
     */
    function _publicMint(uint256 maxNum, uint256 ticketNum, uint256 price, bool lock) private {
        // all public sales share same counter mapping, contract trusts that all signature addresses are unique
        if (publicMints[msg.sender] + ticketNum > maxNum) { revert ExceedMaxTicket(); }

        uint256 availableNum = Math.min(ticketNum, maxSupply - totalSupply );
        if (availableNum <= 0) { revert ExceedMaxSupply(); }
        publicMints[msg.sender] += availableNum;

        uint256 totalPrice = price * availableNum;
        if (msg.value < totalPrice) { revert InvalidPayment(); }

        if (availableNum > 1) {
            for (uint256 i = 0; i < availableNum; i++) {
                uint256 tokenId = totalSupply + 1 + i;
                _mint(msg.sender, tokenId);
                if (lock) transferLocks[tokenId] = LockStatus.LockByAdmin;
            }
        } else {
            uint256 tokenId = totalSupply + 1;
            _mint(msg.sender, tokenId);
            if (lock) transferLocks[tokenId] = LockStatus.LockByAdmin;
        }

        totalSupply += availableNum;
        if (totalSupply > maxSupply) { revert ExceedMaxSupply(); }

        if (msg.value > totalPrice) {
            uint256 refundAmount = msg.value - totalPrice;
            (bool refund, ) = msg.sender.call{value: refundAmount}("");
            if (!refund) {
                emit refundFailed(msg.sender, refundAmount);
            }
        }
    }

    /**
     * @dev Creates new token(s) for valid caller. TokenId(s) will be automatically assigned
     * 
     * @param tierId tier id of caller belonged to
     * @param ticketNum number of tokens to create
     * @param signature signature from `_authority`
     *
     * Requirements:
     *
     * - `saleOn` must be true,
     */
    function whitelistMint(uint256 tierId, uint256 ticketNum, bytes memory signature) external payable isSaleOn(true) validTime(tierId) {
        bytes32 data = keccak256(abi.encode(address(this), msg.sender, tierId));
        if (!SignatureChecker.isValidSignatureNow(_authority, data, signature)) { revert InvalidSignature(); }

        _publicMint(tiers[tierId].maxTicketNum, ticketNum, tiers[tierId].ticketPrice, false);
    }

    /**
     * @dev Creates new tokens for auction winner. TokenIds will be automatically assigned
     * @param ticketNum number of tokens to create
     * @param signature signature from `_authority`
     *
     * Requirements:
     *
     * - `saleOn` must be true,
     * - caller must not be a contract.
     */
    function dutchAuctionMint(uint256 ticketNum, bytes memory signature) external payable isSaleOn(true) validateCaller {
        if (block.timestamp < dutchAuctionStartTime) { revert InvalidTime(); }

        bytes32 data = keccak256(abi.encode(address(this), msg.sender, keccak256("DUTCH")));
        if (!SignatureChecker.isValidSignatureNow(_authority, data, signature)) { revert InvalidSignature(); }

        uint256 availableNum = Math.min(ticketNum, DHDAMaxSupply - DHDATotalSupply );
        if (availableNum <= 0) { revert ExceedAuctionSupply(); }
        DHDATotalSupply += availableNum;

        _publicMint(DUTCH_AUCTION_MAX_TICKET, availableNum, dutchAuctionPrice(), false);
    }

    /**
     * @dev Returns auction token price
     */
    function dutchAuctionPrice() public view returns (uint256){
        uint256 timestamp = block.timestamp;

        if (timestamp < dutchAuctionStartTime)
            return DUTCH_AUCTION_START_PRICE;

        if (timestamp - dutchAuctionStartTime >= DUTCH_AUCTION_PRICE_CURVE_LENGTH)
            return DUTCH_AUCTION_END_PRICE;

        uint256 steps = (timestamp - dutchAuctionStartTime) / DUTCH_AUCTION_DROP_INTERVAL;
        return DUTCH_AUCTION_START_PRICE - steps * DUTCH_AUCTION_DROP_PER_STEP;
    }

    /**
     * @dev Creates new tokens for auction winner. TokenIds will be automatically assigned
     * @param ticketNum number of tokens to create
     * @param signature signature from `_authority`
     *
     * Requirements:
     *
     * - `saleOn` must be true,
     * - caller must not be a contract.
     */
    function diamondHandMint(uint256 ticketNum, bytes memory signature) external payable isSaleOn(true) validateCaller validTime(DIAMOND_HAND_ID) {
        bytes32 data = keccak256(abi.encode(address(this), msg.sender, DIAMOND_HAND_ID));
        if (!SignatureChecker.isValidSignatureNow(_authority, data, signature)) { revert InvalidSignature(); }

        uint256 availableNum = Math.min(ticketNum, diamondHandMaxSupply - DHDATotalSupply );
        if (availableNum <= 0) { revert ExceedDiamondHandSupply(); }
        DHDATotalSupply += availableNum;

        _publicMint(DUTCH_AUCTION_MAX_TICKET, availableNum, tiers[DIAMOND_HAND_ID].ticketPrice, true);
    }

    /**
     * @dev Payouts contract balance
     * 
     * Requirements:
     *
     * - the caller must be `owner`.
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) { revert WithdrawFailed(); }
    }
}