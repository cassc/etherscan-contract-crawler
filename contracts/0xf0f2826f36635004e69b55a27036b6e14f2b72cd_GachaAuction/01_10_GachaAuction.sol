// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IERC2981.sol";

contract GachaAuction is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    struct Drop {
        address tokenAddress;
        uint256 price;
        address paymentReceiver;
        uint64 notBefore;
        uint64 deadline;
        uint256[] tokenIds;
    }

    event DropCreated(address indexed seller, uint256 dropId);
    event DropUpdated(address indexed seller, uint256 dropId);
    event RoyaltyWithheld(address royaltyRecipient, uint256 royaltyAmount);
    event Sale(uint256 indexed dropId, uint256 tokenId, address buyer);

    Counters.Counter private _dropIdCounter;
    mapping(uint256 => Drop) private drops;
    mapping(uint256 => address) public dropSellers;

    address private _auctionFeeRecipient;
    uint256 private _auctionFeeBps;

    constructor(uint256 auctionFeeBps_, address auctionFeeRecipient_) Ownable() Pausable() ReentrancyGuard() {
        _auctionFeeBps = auctionFeeBps_;
        _auctionFeeRecipient = auctionFeeRecipient_;
    }

    /// @notice Given a drop struct, kicks off a new drop
    function setup(Drop calldata drop_) external whenNotPaused returns (uint256) {
        uint256 dropId = _dropIdCounter.current();
        drops[dropId] = drop_;
        dropSellers[dropId] = msg.sender;
        emit DropCreated(msg.sender, dropId);

        _dropIdCounter.increment();
        return dropId;
    }

    /// @dev Allows the seller to update drop start and end time.
    function updateDropTimeline(
        uint256 dropId_,
        uint64 notBefore_,
        uint64 deadline_
    ) external {
        require(dropSellers[dropId_] == msg.sender, "gacha: unauthorized");
        drops[dropId_].notBefore = notBefore_;
        drops[dropId_].deadline = deadline_;

        emit DropUpdated(msg.sender, dropId_);
    }

    /// @notice Allow anyone to remove a token that has been transferred away by the seller.
    function removeDropToken(uint256 dropId_, uint256 tokenIdx_) external {
        Drop storage drop = drops[dropId_];

        require(drop.tokenAddress != address(0), "gacha: not found");

        uint256 tokenId = drop.tokenIds[tokenIdx_];

        // Remove the token first, run the check after
        drop.tokenIds[tokenIdx_] = drop.tokenIds[drop.tokenIds.length - 1];
        drop.tokenIds.pop();

        require(IERC721(drop.tokenAddress).ownerOf(tokenId) != dropSellers[dropId_], "gacha: token still with seller");

        emit DropUpdated(msg.sender, dropId_);
    }

    function deleteDrop(uint256 dropId_) external {
        require(dropSellers[dropId_] == msg.sender || owner() == msg.sender, "gacha: unauthorized");
        delete drops[dropId_];

        emit DropUpdated(msg.sender, dropId_);
    }

    /// @notice Returns the next drop ID
    function nextDropId() public view returns (uint256) {
        return _dropIdCounter.current();
    }

    function peek(uint256 dropId) public view returns (Drop memory) {
        return drops[dropId];
    }

    /// @notice Buyer's interface, delivers to the caller
    function buy(uint256 dropId_) external payable whenNotPaused nonReentrant {
        _buy(dropId_, msg.sender);
    }

    /// @notice Buyer's interface, delivers to a specified address
    function buy(uint256 dropId_, address deliverTo_) external payable whenNotPaused nonReentrant {
        _buy(dropId_, deliverTo_);
    }

    function _buy(uint256 dropId_, address deliverTo_) private {
        // CHECKS
        Drop storage drop = drops[dropId_];

        require(drop.tokenAddress != address(0), "gacha: not found");
        require(drop.tokenIds.length > 0, "gacha: sold out");
        require(drop.notBefore <= block.timestamp, "gacha: auction not yet started");
        require(drop.deadline == 0 || drop.deadline >= block.timestamp, "gacha: auction already ended");

        require(msg.value == drop.price, "gacha: incorrect amount sent");

        // EFFECTS
        // Select token at (semi-)random
        uint256 tokenIdx = uint256(keccak256(abi.encodePacked(block.timestamp))) % drop.tokenIds.length;
        uint256 tokenId = drop.tokenIds[tokenIdx];

        // Remove the token from the drop tokens list
        drop.tokenIds[tokenIdx] = drop.tokenIds[drop.tokenIds.length - 1];
        drop.tokenIds.pop();

        address paymentReceiver = drop.paymentReceiver != address(0) ? drop.paymentReceiver : dropSellers[dropId_];

        (
            uint256 auctionFeeAmount,
            address royaltyReceiver,
            uint256 royaltyAmount,
            uint256 sellerShare
        ) = _getProceedsDistribution(paymentReceiver, drop.tokenAddress, tokenId, drop.price);

        // INTERACTIONS
        // Transfer the token and ensure delivery of the token
        IERC721(drop.tokenAddress).safeTransferFrom(dropSellers[dropId_], deliverTo_, tokenId);
        require(IERC721(drop.tokenAddress).ownerOf(tokenId) == deliverTo_, "gacha: token transfer failed"); // ensure delivery

        bool paymentSent;
        // Ensure delivery of the payment

        // solhint-disable-next-line avoid-low-level-calls
        (paymentSent, ) = paymentReceiver.call{value: sellerShare}("");
        require(paymentSent, "gacha: seller share transfer failed");

        // Pay out the royalty
        if (royaltyAmount > 0 && royaltyReceiver != address(0)) {
            // solhint-disable-next-line avoid-low-level-calls
            (paymentSent, ) = royaltyReceiver.call{value: royaltyAmount}("");
            require(paymentSent, "gacha: royalty payment failed");
        }

        // Transfer the auction fee
        if (auctionFeeAmount > 0 && _auctionFeeRecipient != address(0)) {
            // solhint-disable-next-line avoid-low-level-calls
            (paymentSent, ) = _auctionFeeRecipient.call{value: auctionFeeAmount}("");
            require(paymentSent, "gacha: auction fee transfer failed");
        }

        emit Sale(dropId_, tokenId, msg.sender);

        // Clean up the drop after all items have been sold
        if (drop.tokenIds.length == 0) {
            delete drops[dropId_];
        }
    }

    function _getProceedsDistribution(
        address paymentReceiver_,
        address tokenAddress_,
        uint256 tokenId_,
        uint256 price_
    )
        private
        view
        returns (
            uint256 auctionFeeAmount,
            address royaltyReceiver,
            uint256 royaltyAmount,
            uint256 sellerShare
        )
    {
        // Auction fee
        auctionFeeAmount = (price_ * _auctionFeeBps) / 10000;

        // EIP-2981 royalty split
        (royaltyReceiver, royaltyAmount) = _getRoyaltyInfo(tokenAddress_, tokenId_, price_ - auctionFeeAmount);
        // No royalty address, or royalty goes to the seller
        if (royaltyReceiver == address(0) || royaltyReceiver == paymentReceiver_) {
            royaltyAmount = 0;
        }

        // Seller's share
        sellerShare = price_ - (auctionFeeAmount + royaltyAmount);

        // Internal consistency check
        assert(sellerShare + auctionFeeAmount + royaltyAmount <= price_);
    }

    function _getRoyaltyInfo(
        address tokenAddress_,
        uint256 tokenId_,
        uint256 price_
    ) private view returns (address, uint256) {
        try IERC2981(tokenAddress_).royaltyInfo(tokenId_, price_) returns (
            address royaltyReceiver,
            uint256 royaltyAmount
        ) {
            return (royaltyReceiver, royaltyAmount);
        } catch (bytes memory reason) {
            // EIP 2981's `royaltyInfo()` function is not implemented
            // treatment the same as here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.1/contracts/token/ERC721/ERC721.sol#L379
            if (reason.length == 0) {
                return (address(0), 0);
            } else {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    ///
    /// @dev Auction fee setters and getters
    ///

    function auctionFeeBps() public view returns (uint256) {
        return _auctionFeeBps;
    }

    function setAuctionFeeBps(uint256 newAuctionFeeBps_) public onlyOwner {
        _auctionFeeBps = newAuctionFeeBps_;
    }

    function auctionFeeRecipient() public view returns (address) {
        return _auctionFeeRecipient;
    }

    function setAuctionFeeRecipient(address auctionFeeRecipient_) public onlyOwner {
        _auctionFeeRecipient = auctionFeeRecipient_;
    }

    /// @dev Allows the owner to withdraw any leftover funds
    function withdraw(address payable account_, uint256 amount_) public nonReentrant onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool paymentSent, ) = account_.call{value: amount_}("");
        require(paymentSent, "gacha: withdrawal failed");
    }

    ///
    /// @dev The following functions relate to pausing of the contract
    ///

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}