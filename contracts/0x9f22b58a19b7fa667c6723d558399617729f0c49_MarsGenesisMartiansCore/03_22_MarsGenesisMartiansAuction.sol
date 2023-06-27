// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MarsGenesisMartiansAuctionBase.sol";


/// @title MarsGenesis Martians Auction Contract
/// @author MarsGenesis
/// @notice You can use this contract to buy, sell and bid on MarsGenesis martians
contract MarsGenesisMartiansAuction is MarsGenesisMartiansAuctionBase {

    /// @dev Address of the tax wallet
    address private _taxWallet;

    /// @notice Inits the contract 
    /// @param _erc721Address The address of the main MarsGenesis contract
    /// @param _walletAddress The address of the wallet of MarsGenesis contract
    /// @param _cut The contract owner tax on sales
    /// @param taxWallet The address for the tax on sales
    constructor (address _erc721Address, address payable _walletAddress, uint256 _cut, address taxWallet) MarsGenesisMartiansAuctionBase(_erc721Address, _walletAddress, _cut) {
        _taxWallet = taxWallet;
    }

    /*** EXTERNAL ***/

    /// @notice Enters a bid for a specific martian (payable)
    /// @dev If there was a previous (lower) bid, it removes it and adds its amount to pending withdrawals. 
    /// On success, it emits the MartianBidEntered event.
    /// @param tokenId The id of the martian to bet upon
    function enterBidForMartian(uint tokenId) external payable {
        require(nonFungibleContract.ownerOf(tokenId) != address(0), "Martian not yet owned");
        require(nonFungibleContract.ownerOf(tokenId) != msg.sender, "You already own the martian");
        require(msg.value > 0, "Amount must be > 0");
        
        Bid memory existing = martianIdToBids[tokenId];
        require(msg.value > existing.value, "Amount must be > than existing bid");

        if (existing.value > 0) {
            // Refund the previous bid
            addressToPendingWithdrawal[existing.bidder] += existing.value;
        }
        martianIdToBids[tokenId] = Bid(true, tokenId, msg.sender, msg.value);
        emit MartianBidEntered(tokenId, msg.value, msg.sender);
    }

    /// @notice Buys a martian for a specific price (payable)
    /// @dev The martian must be for sale before other user calls this method. If the same user had the higher bid before, it gets refunded into the pending withdrawals. On success, emits the MartianBought event. Executes a ERC721 safeTransferFrom
    /// @param tokenId The id of the martian to be bought
    function buyMartian(uint tokenId) external payable {
        require(msg.sender != nonFungibleContract.ownerOf(tokenId), "You cant buy your own martian");
        
        Offer memory offer = martianIdToOfferForSale[tokenId];
        require(offer.isForSale, "Item is not for sale");
        require(offer.seller == nonFungibleContract.ownerOf(tokenId), "Seller is no longer the owner of the item");
        require(msg.value >= offer.minValue, "Not enough balance");

        address seller = offer.seller;

        nonFungibleContract.safeTransferFrom(seller, msg.sender, tokenId);

        // 5% tax
        uint taxAmount = msg.value * ownerCut / 100;
        uint netAmount = msg.value - taxAmount;

        addressToPendingWithdrawal[seller] += netAmount;
        addressToPendingWithdrawal[_taxWallet] += taxAmount;
        
        emit MartianBought(tokenId, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = martianIdToBids[tokenId];
        if (bid.bidder == msg.sender) {
            addressToPendingWithdrawal[msg.sender] += bid.value;
            martianIdToBids[tokenId] = Bid(false, tokenId, address(0), 0);
        }
    }

    /// @notice Offers a martian that ones own for sale for a min price
    /// @dev On success, emits the event MartianOffered
    /// @param tokenId The id of the martian to put for sale
    /// @param minSalePriceInWei The minimum price of the martian (Wei)
    function offerMartianForSale(uint tokenId, uint minSalePriceInWei) external {
        require(msg.sender == address(nonFungibleContract), "Use MarsContractBase:offerMartianForSale instead");
        require(nonFungibleContract.ownerOf(tokenId) == msg.sender || nonFungibleContract.getApproved(tokenId) == address(this), "Only owner can add item from sale");

        martianIdToOfferForSale[tokenId] = Offer(true, tokenId, nonFungibleContract.ownerOf(tokenId), minSalePriceInWei);

        emit MartianOffered(tokenId, minSalePriceInWei, nonFungibleContract.ownerOf(tokenId));
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

    /// @notice Sets the wallet for the design %
    /// @dev Only callable by the deployer
    function setTaxWallet(address taxWallet) external { 
        require(msg.sender == _deployerAddress, "INVALID_ROLE");
        _taxWallet = taxWallet;
    }

    /// @notice Owner of a martian can accept a bid for its martian
    /// @dev Only callable by the main contract. On success, emits the event MartianBought. Disccounts the contract tax (cut) from the final price. Executes a ERC721 safeTransferFrom
    /// @param tokenId The id of the martian
    /// @param minPrice The minimum price of the martian
    function acceptBidForMartian(uint tokenId, uint minPrice) external {
        require(msg.sender == address(nonFungibleContract), "Use MarsContractBase:acceptBidForMartian instead");
        require(nonFungibleContract.ownerOf(tokenId) == msg.sender || nonFungibleContract.getApproved(tokenId) == address(this), "Sender is not owner");
        
        address seller = nonFungibleContract.ownerOf(tokenId);
        Bid memory bid = martianIdToBids[tokenId];

        require(bid.value > 0, "Value must be > 0");
        require(bid.value >= minPrice, "Value < minPrice");

        nonFungibleContract.safeTransferFrom(seller, bid.bidder, tokenId);

        uint amount = bid.value;
        martianIdToBids[tokenId] = Bid(false, tokenId, address(0), 0);

        // 5% tax
        uint taxAmount = amount * ownerCut / 100;
        uint netAmount = amount - taxAmount;

        addressToPendingWithdrawal[seller] += netAmount;
        addressToPendingWithdrawal[_taxWallet] += taxAmount;

        emit MartianBought(tokenId, bid.value, seller, bid.bidder);
    }

    /// @notice Users can withdraw their own bid for a specific martian
    /// @dev The bid amount is automatically transfered back to the user. Emits MartianBidWithdrawn event. Avoids reentrancy.
    /// @param tokenId The id of the martian that had the bid on
    function withdrawBidForMartian(uint tokenId) external {
        require(nonFungibleContract.ownerOf(tokenId) != address(0), "Sender cant be 0x0");
        require(nonFungibleContract.ownerOf(tokenId) != msg.sender, "Sender cant be the owner");
        
        Bid memory bid = martianIdToBids[tokenId];
        require(bid.bidder == msg.sender, "Only bidder can withdraw their bid");

        uint amount = bid.value;

        martianIdToBids[tokenId] = Bid(false, tokenId, address(0), 0);
        payable(msg.sender).transfer(amount);
        emit MartianBidWithdrawn(tokenId, bid.value, msg.sender);
    }

    /// @notice Updates the wallet contract address    
    /// @param _address The address of the wallet contract
    /// @dev Only callable by deployer
    function setWalletAddress(address payable _address) external {
        require(msg.sender == _deployerAddress, "INVALID_ROLE");
        MarsGenesisMartiansWallet candidateContract = MarsGenesisMartiansWallet(_address);
        walletContract = candidateContract;
    }


    /*** PUBLIC ***/

    /// @notice Checks if a martian is for sale
    /// @param tokenId The id of the martian to check
    /// @return boolean, true if the martian is for sale
    function martianIdIsForSale(uint256 tokenId) public view returns(bool) {
        return martianIdToOfferForSale[tokenId].isForSale;
    }

    /// @notice Puts a martian no longer for sale
    /// @dev Callable only by the main contract or the owner of a martian. Emits the event MartianNoLongerForSale
    /// @param tokenId The id of the martian
    function martianNoLongerForSale(uint tokenId) public {
        require(nonFungibleContract.ownerOf(tokenId) == msg.sender || nonFungibleContract.getApproved(tokenId) == address(this), "Only owner can remove item from sale");
        martianIdToOfferForSale[tokenId] = Offer(false, tokenId, msg.sender, 0);
        emit MartianNoLongerForSale(tokenId, nonFungibleContract.ownerOf(tokenId));
    }
}