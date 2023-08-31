// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@chocolate-factory/contracts/admin-manager/AdminManagerUpgradable.sol";
import "../interfaces/ITengriaToken.sol";

contract TengriaAuctionHouse is
    Initializable,
    EIP712Upgradeable,
    AdminManagerUpgradable,
    PausableUpgradeable
{
    address public signer;
    ITengriaToken public token;
    mapping(uint256 => Bid) public highestBids;
    uint256 public minimumBidIncrease;
    address public adminClaimsRecipient;

    struct Bid {
        address bidder;
        uint256 value;
    }

    struct ClaimRequest {
        address account;
        uint256 tokenId;
    }

    event BidCreated(uint256 indexed tokenId, address bidder, uint256 value);

    uint256 private constant AUCTIONS_START_TIME = 1690995000;
    uint256 private constant AUCTION_DURATION = 10 minutes;
    uint256 private constant FREE_CLAIMS_INTERVAL = 5;
    bytes32 private constant CLAIM_REQUEST_TYPE_HASH =
        keccak256("ClaimRequest(address account,uint256 tokenId)");

    function initialize(
        address signer_,
        address tokenAddress_,
        uint256 minimumBidIncrease_,
        address adminClaimsRecipient_
    ) external initializer {
        __AdminManager_init();
        __Pausable_init();
        signer = signer_;
        token = ITengriaToken(tokenAddress_);
        minimumBidIncrease = minimumBidIncrease_;
        adminClaimsRecipient = adminClaimsRecipient_;
    }

    function bid(uint256 tokenId_) external payable onlyEOA whenNotPaused {
        require(tokenId_ >= 1 && tokenId_ <= 5000, "Auction not found");
        require(tokenId_ % 5 != 0, "Auction not found");
        (uint256 startTime, uint256 endTime) = _getTimes(tokenId_);
        require(
            block.timestamp >= startTime && block.timestamp < endTime,
            "Auction not available"
        );
        Bid memory highestBid = highestBids[tokenId_];
        require(
            msg.value >= highestBid.value + minimumBidIncrease,
            "Invalid bid amount"
        );
        if (highestBid.bidder != address(0)) {
            _sendValue(highestBid.bidder, highestBid.value);
        }
        highestBids[tokenId_] = Bid(msg.sender, msg.value);
        emit BidCreated(tokenId_, msg.sender, msg.value);
    }

    function settle(uint256 tokenId_) external onlyEOA whenNotPaused {
        (, uint256 endTime) = _getTimes(tokenId_);
        require(block.timestamp >= endTime, "Settle not available");
        require(highestBids[tokenId_].bidder == msg.sender);
        token.mint(msg.sender, tokenId_);
    }

    function adminSettle(uint256 tokenId_) external onlyAdmin whenNotPaused {
        require(tokenId_ >= 1 && tokenId_ <= 5000, "Settle not available");
        (, uint256 endTime) = _getTimes(tokenId_);
        require(tokenId_ % 5 != 0, "Settle not available");
        require(block.timestamp >= endTime, "Settle not available");
        require(highestBids[tokenId_].value == 0, "Invalid settle");
        token.mint(adminClaimsRecipient, tokenId_);
    }

    function claim(
        ClaimRequest calldata request_,
        bytes calldata signature_
    ) external onlyEOA onlyAuthorized(request_, signature_) whenNotPaused {
        (, uint256 endTime) = _getTimes(request_.tokenId);
        require(block.timestamp >= endTime, "Claim not available");
        require(request_.account == msg.sender);
        token.mint(request_.account, request_.tokenId);
    }

    modifier onlyAuthorized(
        ClaimRequest calldata request_,
        bytes calldata signature_
    ) {
        bytes32 structHash = hashTypedData(request_);
        bytes32 digest = _hashTypedDataV4(structHash);
        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature_);
        require(recoveredSigner == signer, "Unauthorized claim request");
        _;
    }

    function hashTypedData(
        ClaimRequest calldata request_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIM_REQUEST_TYPE_HASH,
                    request_.account,
                    request_.tokenId
                )
            );
    }

    function setSigner(address signer_) public onlyAdmin {
        signer = signer_;
    }

    function setToken(address tokenAddress_) external onlyAdmin {
        token = ITengriaToken(tokenAddress_);
    }

    function setMinimumBidIncrease(
        uint256 minimumBidIncrease_
    ) public onlyAdmin {
        minimumBidIncrease = minimumBidIncrease_;
    }

    function setAdminClaimsRecipient(
        address adminClaimsRecipient_
    ) public onlyAdmin {
        adminClaimsRecipient = adminClaimsRecipient_;
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function withdraw() external onlyAdmin {
        _sendValue(payable(msg.sender), address(this).balance);
    }

    function _getTimes(
        uint256 tokenId_
    ) private pure returns (uint256, uint256) {
        uint256 startTime = AUCTIONS_START_TIME +
            tokenId_ *
            AUCTION_DURATION -
            (tokenId_ / FREE_CLAIMS_INTERVAL) *
            AUCTION_DURATION;
        uint256 endTime = startTime + AUCTION_DURATION;
        return (startTime, endTime);
    }

    function _sendValue(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Recipient may have reverted");
    }

    function _EIP712Name() internal pure override returns (string memory) {
        return "TENGRIA";
    }

    function _EIP712Version() internal pure override returns (string memory) {
        return "0.1.0";
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "No bots");
        _;
    }
}