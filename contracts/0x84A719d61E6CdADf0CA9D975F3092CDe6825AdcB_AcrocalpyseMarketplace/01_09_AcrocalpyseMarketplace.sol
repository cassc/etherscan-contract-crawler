// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AcrocalpyseMarketplace is Ownable, Pausable {
    using SafeMath for uint256;

    // signer address for verification
    address public signerAddress;

    // paper token address
    IERC20 public paperToken;

    event ItemBought(address purchaser, uint256 itemId, uint256 quantity, uint256 timestamp);
    event AuctionBid(address bidder, uint256 itemId, uint256 bidAmount, uint256 timestamp);
    event ReclaimedBids(address bidder, uint256[] itemIds, uint256 timestamp);

    struct Bidder {
        uint256 bidAmount;
        bool isRefunded;
        uint256 bidTimestamp;
    }

    struct Auction {
        uint256 highestBid;
        mapping(address => Bidder) bidders;
    }

    // Mapping to store all the bidders for an auction
    mapping(uint256 => Auction) private auctions;

    // Mapping to store total sold for buy & raffle types
    mapping(uint256 => uint256) private itemsSold;

    constructor(IERC20 _paperTokenAddress) {
        signerAddress = _msgSender();

        if (address(_paperTokenAddress) != address(0)) {
            paperToken = IERC20(_paperTokenAddress);
        }
    }

    //external
    fallback() external payable {}

    receive() external payable {} // solhint-disable-line no-empty-blocks

    modifier callerIsUser() {
        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == _msgSender(), "Cannot be called by a contract");
        _;
    }

    function buy(
        bytes memory signature,
        uint256 itemId,
        uint256 quantity,
        uint256 paperTokensCost,
        uint256 ethCost,
        uint256 maxAllowedQuantity
    ) external payable whenNotPaused callerIsUser {
        require(paperTokensCost > 0 || ethCost > 0, "Invalid amount");

        // verifying the signature
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(_msgSender(), itemId, quantity, paperTokensCost, ethCost, maxAllowedQuantity))
        );
        require(ECDSA.recover(hash, signature) == signerAddress, "Invalid Access");

        if (ethCost > 0) {
            require(msg.value >= ethCost, "Invalid amount transferred");
        }

        // validating max allowed quantity per item
        uint256 totalSold = itemsSold[itemId];
        if (maxAllowedQuantity > 0) {
            require(totalSold + quantity <= maxAllowedQuantity, "Max sell limit reached");
        }
        itemsSold[itemId] = totalSold + quantity;

        if (paperTokensCost > 0) {
            // checking the $PAPER Token balance
            require(paperToken.balanceOf(_msgSender()) >= paperTokensCost, "Insufficient $PAPER balance");

            // Transfer $PAPER Token from Account to the Contract
            bool transferSuccess = paperToken.transferFrom(_msgSender(), address(this), paperTokensCost);
            require(transferSuccess, "$PAPER transfer failed");
        }

        emit ItemBought(_msgSender(), itemId, quantity, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    function bid(
        bytes memory signature,
        uint256 itemId,
        uint256 bidAmount
    ) external whenNotPaused callerIsUser {
        require(bidAmount > 0, "Invalid bid amount");

        // verifying the signature
        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_msgSender(), itemId, bidAmount)));
        require(ECDSA.recover(hash, signature) == signerAddress, "Invalid Access");

        uint256 currentHighestBid = auctions[itemId].highestBid;
        uint256 previousBid = auctions[itemId].bidders[_msgSender()].bidAmount;

        require(bidAmount > previousBid, "Bid less than previous bid");

        // checking the $PAPER Token balance
        require(paperToken.balanceOf(_msgSender()) >= bidAmount, "Insufficient $PAPER balance");

        // Transfer $PAPER Token from Account to the Contract
        bool transferSuccess = paperToken.transferFrom(_msgSender(), address(this), bidAmount - previousBid);
        require(transferSuccess, "$PAPER transfer failed");

        auctions[itemId].bidders[_msgSender()] = Bidder({
            bidAmount: bidAmount,
            isRefunded: false,
            bidTimestamp: block.timestamp // solhint-disable-line not-rely-on-time
        });

        if (currentHighestBid < bidAmount) {
            auctions[itemId].highestBid = bidAmount;
        }

        emit AuctionBid(_msgSender(), itemId, bidAmount, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    function reclaimBids(bytes memory signature, uint256[] memory itemIds) external whenNotPaused callerIsUser {
        // verifying the signature
        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_msgSender(), itemIds)));
        require(ECDSA.recover(hash, signature) == signerAddress, "Invalid Access");

        uint256 totalPaperToClaim = 0;

        for (uint256 i = 0; i < itemIds.length; i++) {
            Bidder memory bidder = auctions[itemIds[i]].bidders[_msgSender()];

            if (!bidder.isRefunded) {
                totalPaperToClaim += bidder.bidAmount;

                bidder.isRefunded = true;
                auctions[itemIds[i]].bidders[_msgSender()] = bidder;
            }
        }

        if (totalPaperToClaim > 0) {
            // Transfer $PAPER from Contract to the Account
            bool transferSuccess = paperToken.transfer(_msgSender(), totalPaperToClaim);
            require(transferSuccess, "Unable to transfer $PAPER");
        }

        emit ReclaimedBids(_msgSender(), itemIds, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    function getItemBidder(address bidder, uint256 itemId) external view returns (Bidder memory _bidder) {
        require(itemId > 0, "Invalid Item Id");

        return auctions[itemId].bidders[bidder];
    }

    function getItemHighestBid(uint256 itemId) external view returns (uint256 highestBid) {
        require(itemId > 0, "Invalid Item Id");

        return auctions[itemId].highestBid;
    }

    function getItemsSold(uint256 itemId) external view returns (uint256 itemsSoldCount) {
        require(itemId > 0, "Invalid Item Id");

        return itemsSold[itemId];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setSignerAddress(address newSignerAddress) external onlyOwner {
        if (address(newSignerAddress) != address(0)) {
            signerAddress = newSignerAddress;
        }
    }

    function setPaperToken(IERC20 newAddress) external onlyOwner {
        if (address(newAddress) != address(0)) {
            paperToken = IERC20(newAddress);
        }
    }

    function viewContractTokenBalance(IERC20 tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function withdrawTokens(IERC20 tokenAddress, uint256 percentageWithdrawl) external onlyOwner {
        uint256 balance = viewContractTokenBalance(tokenAddress);

        require(balance > 0, "No funds available");
        require(percentageWithdrawl > 0 && percentageWithdrawl <= 100, "Withdrawl percent invalid");

        bool success = IERC20(tokenAddress).transfer(owner(), balance.mul(percentageWithdrawl).div(100));

        require(success, "Withdrawl failed");
    }

    function withdraw(uint256 percentWithdrawl) external onlyOwner {
        require(address(this).balance > 0, "No funds available");
        require(percentWithdrawl > 0 && percentWithdrawl <= 100, "Invalid Withdrawl percent");

        Address.sendValue(payable(owner()), (address(this).balance * percentWithdrawl) / 100);
    }
}