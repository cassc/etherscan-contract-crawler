// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MarsGenesisAuctionBase.sol";


/// @title MarsGenesis Auction Contract
/// @author MarsGenesis
/// @notice You can use this contract to buy, sell and bid on MarsGenesis lands
contract MarsGenesisAuction is MarsGenesisAuctionBase {

    /// @notice Inits the contract 
    /// @param _erc721Address The address of the main MarsGenesis contract
    /// @param _walletAddress The address of the wallet of MarsGenesis contract
    /// @param _cut The contract owner tax on sales
    constructor (address _erc721Address, address payable _walletAddress, uint256 _cut) MarsGenesisAuctionBase(_erc721Address, _walletAddress, _cut) {}

    /*** EXTERNAL ***/

    /// @notice Enters a bid for a specific land (payable)
    /// @dev If there was a previous (lower) bid, it removes it and adds its amount to pending withdrawals. 
    /// On success, it emits the LandBidEntered event.
    /// @param tokenId The id of the land to bet upon
    function enterBidForLand(uint tokenId) external payable {
        require(nonFungibleContract.ownerOf(tokenId) != address(0), "Land not yet owned");
        require(nonFungibleContract.ownerOf(tokenId) != msg.sender, "You already own the land");
        require(msg.value > 0, "Amount must be > 0");
        
        Bid memory existing = landIdToBids[tokenId];
        require(msg.value > existing.value, "Amount must be > than existing bid");

        if (existing.value > 0) {
            // Refund the previous bid
            addressToPendingWithdrawal[existing.bidder] += existing.value;
        }
        landIdToBids[tokenId] = Bid(true, tokenId, msg.sender, msg.value);
        emit LandBidEntered(tokenId, msg.value, msg.sender);
    }

    /// @notice Buys a land for a specific price (payable)
    /// @dev The land must be for sale before other user calls this method. If the same user had the higher bid before, it gets refunded into the pending withdrawals. On success, emits the LandBought event. Executes a ERC721 safeTransferFrom
    /// @param tokenId The id of the land to be bought
    function buyLand(uint tokenId) external payable {
        require(msg.sender != nonFungibleContract.ownerOf(tokenId), "You cant buy your own land");
        
        Offer memory offer = landIdToOfferForSale[tokenId];
        require(offer.isForSale, "Item is not for sale");
        require(offer.seller == nonFungibleContract.ownerOf(tokenId), "Seller is no longer the owner of the item");
        require(msg.value >= offer.minValue, "Not enough balance");

        address seller = offer.seller;

        nonFungibleContract.safeTransferFrom(seller, msg.sender, tokenId);

        uint taxAmount = msg.value * ownerCut / 100;
        uint netAmount = msg.value - taxAmount;

        addressToPendingWithdrawal[seller] += netAmount;

        // 80% of tax goes to first owner
        address firstOwner = nonFungibleContract.tokenIdToFirstOwner(tokenId);
        uint firstOwnerAmount = taxAmount * 80 / 100;
        
        addressToPendingWithdrawal[firstOwner] += firstOwnerAmount;
        ownerBalance += taxAmount - firstOwnerAmount;

        emit LandBought(tokenId, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = landIdToBids[tokenId];
        if (bid.bidder == msg.sender) {
            addressToPendingWithdrawal[msg.sender] += bid.value;
            landIdToBids[tokenId] = Bid(false, tokenId, address(0), 0);
        }
    }

    /// @notice Offers a land that ones own for sale for a min price
    /// @dev On success, emits the event LandOffered
    /// @param tokenId The id of the land to put for sale
    /// @param minSalePriceInWei The minimum price of the land (Wei)
    function offerLandForSale(uint tokenId, uint minSalePriceInWei) external {
        require(msg.sender == address(nonFungibleContract), "Use MarsContractBase:offerLandForSale instead");
        require(nonFungibleContract.ownerOf(tokenId) == msg.sender || nonFungibleContract.getApproved(tokenId) == address(this), "Only owner can add item from sale");

        landIdToOfferForSale[tokenId] = Offer(true, tokenId, nonFungibleContract.ownerOf(tokenId), minSalePriceInWei);

        emit LandOffered(tokenId, minSalePriceInWei, nonFungibleContract.ownerOf(tokenId));
    }

    /// @notice Sends free balance to the main wallet 
    /// @dev Only callable by the deployer
    function sendBalanceToWallet() external { 
        require(msg.sender == _deployerAddress, "INVALID_ROLE");
        require(ownerBalance > 0, "No Balance to send");
        uint amount = ownerBalance;
        ownerBalance = 0;
        
        (bool success,) = address(walletContract).call{value: amount}("");
        require(success);
    }

    /// @notice Users can withdraw their available balance
    /// @dev Avoids reentrancy
    function withdraw() external { 
        uint amount = addressToPendingWithdrawal[msg.sender];
        addressToPendingWithdrawal[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /// @notice Owner of a land can accept a bid for its land
    /// @dev Only callable by the main contract. On success, emits the event LandBought. Disccounts the contract tax (cut) from the final price. Executes a ERC721 safeTransferFrom
    /// @param tokenId The id of the land
    /// @param minPrice The minimum price of the land
    function acceptBidForLand(uint tokenId, uint minPrice) external {
        require(msg.sender == address(nonFungibleContract), "Use MarsContractBase:acceptBidForLand instead");
        require(nonFungibleContract.ownerOf(tokenId) == msg.sender || nonFungibleContract.getApproved(tokenId) == address(this), "Sender is not owner");
        
        address seller = nonFungibleContract.ownerOf(tokenId);
        Bid memory bid = landIdToBids[tokenId];

        require(bid.value > 0, "Value must be > 0");
        require(bid.value >= minPrice, "Value < minPrice");

        nonFungibleContract.safeTransferFrom(seller, bid.bidder, tokenId);

        uint amount = bid.value;
        landIdToBids[tokenId] = Bid(false, tokenId, address(0), 0);

        uint taxAmount = amount * ownerCut / 100;
        uint netAmount = amount - taxAmount;

        addressToPendingWithdrawal[seller] += netAmount;

        // 80% of tax goes to first owner
        address firstOwner = nonFungibleContract.tokenIdToFirstOwner(tokenId);
        uint firstOwnerAmount = taxAmount * 80 / 100;
        
        addressToPendingWithdrawal[firstOwner] += firstOwnerAmount;
        ownerBalance += taxAmount - firstOwnerAmount;

        emit LandBought(tokenId, bid.value, seller, bid.bidder);
    }

    /// @notice Users can withdraw their own bid for a specific land
    /// @dev The bid amount is automatically transfered back to the user. Emits LandBidWithdrawn event. Avoids reentrancy.
    /// @param tokenId The id of the land that had the bid on
    function withdrawBidForLand(uint tokenId) external {
        require(nonFungibleContract.ownerOf(tokenId) != address(0), "Sender cant be 0x0");
        require(nonFungibleContract.ownerOf(tokenId) != msg.sender, "Sender cant be the owner");
        
        Bid memory bid = landIdToBids[tokenId];
        require(bid.bidder == msg.sender, "Only bidder can withdraw their bid");

        uint amount = bid.value;

        landIdToBids[tokenId] = Bid(false, tokenId, address(0), 0);
        payable(msg.sender).transfer(amount);
        emit LandBidWithdrawn(tokenId, bid.value, msg.sender);
    }

    /// @notice Updates the wallet contract address    
    /// @param _address The address of the wallet contract
    /// @dev Only callable by deployer
    function setWalletAddress(address payable _address) external {
        require(msg.sender == _deployerAddress, "INVALID_ROLE");
        MarsGenesisWallet candidateContract = MarsGenesisWallet(_address);
        walletContract = candidateContract;
    }


    /*** PUBLIC ***/

    /// @notice Checks if a land is for sale
    /// @param tokenId The id of the land to check
    /// @return boolean, true if the land is for sale
    function landIdIsForSale(uint256 tokenId) public view returns(bool) {
        return landIdToOfferForSale[tokenId].isForSale;
    }

    /// @notice Puts a land no longer for sale
    /// @dev Callable only by the main contract or the owner of a land. Emits the event LandNoLongerForSale
    /// @param tokenId The id of the land
    function landNoLongerForSale(uint tokenId) public {
        require(nonFungibleContract.ownerOf(tokenId) == msg.sender || nonFungibleContract.getApproved(tokenId) == address(this), "Only owner can remove item from sale");
        landIdToOfferForSale[tokenId] = Offer(false, tokenId, msg.sender, 0);
        emit LandNoLongerForSale(tokenId, nonFungibleContract.ownerOf(tokenId));
    }
}