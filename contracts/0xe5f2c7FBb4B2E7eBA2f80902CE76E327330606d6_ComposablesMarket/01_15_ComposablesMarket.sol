// SPDX-License-Identifier: GPL-3.0

/// @title The Composables Market

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { IComposablesMarket } from './interfaces/IComposablesMarket.sol';

import { IComposableItem } from '../items/interfaces/IComposableItem.sol';

contract ComposablesMarket is IComposablesMarket, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {

    //All listings
    mapping(uint256 => Listing) public listings;

    // Track the listings per each assets on the market
    mapping(address => mapping(uint256 => uint256[])) public tokenListings;

	//Running counter for per address max
    mapping(uint256 => mapping(address => uint64)) public perAddressCount;    

	//platform balances, by seller
    mapping(address => uint256) public balances;

    // The internal listing ID tracker
    uint256 private _currentListingId;

	//marketplace fee, basis points
    uint256 public listingFee = 0;

    /**
     * @notice Initialize the market and base contracts,
     * @dev This function can only be called once.
     */
    function initialize(
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    function getTokenListings(address tokenAddress, uint256 tokenId) external view returns (uint256[] memory) {
        return tokenListings[tokenAddress][tokenId];
    }

    function createListing(address tokenAddress, uint256 tokenId, uint256 price, uint64 quantity, uint64 maxPerAddress) external nonReentrant returns (uint256) {
		return _createListing(tokenAddress, tokenId, price, quantity, maxPerAddress);
	}

    function createListingBatch(address[] calldata tokenAddresses, uint256[] calldata tokenIds, uint256[] calldata prices, uint64[] calldata quantities, uint64[] calldata maxPerAddresses) external nonReentrant returns (uint256) {
		uint256 len = tokenAddresses.length;
		uint256 lastListingId;
		
        for (uint256 i = 0; i < len;) {
			lastListingId = _createListing(tokenAddresses[i], tokenIds[i], prices[i], quantities[i], maxPerAddresses[i]);
			
			unchecked {
            	i++;
        	}
        }

		return lastListingId;
	}

    function _createListing(address tokenAddress, uint256 tokenId, uint256 price, uint64 quantity, uint64 maxPerAddress) internal returns (uint256) {
        require(IComposableItem(tokenAddress).owner() == _msgSender(), "ComposablesMarket: caller must be collection owner");
        require(IComposableItem(tokenAddress).minter() == address(this), "ComposablesMarket: contract must be collection minter");

        uint256[] memory _tokenListings = tokenListings[tokenAddress][tokenId];
        
		//check if there is an active listing associated to this asset
        if (_tokenListings.length > 0) {
        	require(listings[_tokenListings[_tokenListings.length - 1]].deleted == true, "ComposablesMarket: listing already associated to this asset");
        }

        uint256 listingId = _currentListingId;
        listings[listingId] = Listing(_msgSender(), 
        	tokenAddress, tokenId, 
        	price,
        	quantity, 0,
        	maxPerAddress,
        	false, false);

		//add to the token listings list
		tokenListings[tokenAddress][tokenId].push(listingId);

        emit ListingCreated(listingId, _msgSender(), 
        	tokenAddress, tokenId, 
        	price,
        	quantity, maxPerAddress);
        
        _currentListingId++;

        return listingId;
    }

    function getListing(uint256 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }

    function deleteListing(uint256 listingId) external {
    	_deleteListing(listingId);
    }

    function deleteListingBatch(uint256[] calldata listingIds) external {
		uint256 len = listingIds.length;
		
        for (uint256 i = 0; i < len;) {
			_deleteListing(listingIds[i]);
			
			unchecked {
            	i++;
        	}
        }
    }

    function _deleteListing(uint256 listingId) internal {
    	Listing memory listing = listings[listingId];

        require(IComposableItem(listing.tokenAddress).owner() == _msgSender(), "ComposablesMarket: caller must be collection owner");
        require(IComposableItem(listing.tokenAddress).minter() == address(this), "ComposablesMarket: contract must be collection minter");
        require(listing.deleted == false, "ComposablesMarket: listing already deleted");
        
        listings[listingId].deleted = true;

        emit ListingDeleted(listingId, listing.tokenAddress, listing.tokenId);
    }

    function fillListing(uint256 listingId, uint64 quantity) external payable nonReentrant whenNotPaused {
    	_fillListing(listingId, quantity);
    }

	function fillListingBatch(uint256[] calldata listingIds, uint64[] calldata quantities) external payable nonReentrant whenNotPaused {
		uint256 len = listingIds.length;
		
        for (uint256 i = 0; i < len;) {
			_fillListing(listingIds[i], quantities[i]);
			
			unchecked {
            	i++;
        	}
        }		
	}

    function _fillListing(uint256 listingId, uint64 quantity) internal {
    	//check to make sure not greater than current counter
    	//
    	
    	Listing memory listing = listings[listingId];
    	
        require(msg.value == listing.price * quantity, "ComposablesMarket: insufficient funds");
        require(listing.deleted == false, "ComposablesMarket: listing has been removed");
        require(listing.completed == false, "ComposablesMarket: listing has been completed");

		//check for per address limits
		if (listing.maxPerAddress > 0) {
			require(quantity + perAddressCount[listingId][_msgSender()] <= listing.maxPerAddress, "ComposablesMarket: quantity greater than remaining max per address");
			perAddressCount[listingId][_msgSender()] += quantity;
		}

		//check for quantity, account for open editions
		if (listing.quantity > 0) {
	        uint256 remaining = listing.quantity - listing.filled;
	        require(quantity <= remaining, "ComposablesMarket: quantity greater than remaining supply");			

	        if((remaining - quantity) == 0) {
	            listings[listingId].completed = true;
	        }
		}
		
		//update the listing filled counters
		listings[listingId].filled += quantity;

		uint256 sellerAmount = 0;
		uint256 feeAmount = 0;
		//update the seller balances
		if (listing.price > 0) {
	        sellerAmount = ((listing.price * quantity) * (10000 - listingFee)) / 10000;
	        feeAmount = ((listing.price * quantity) * listingFee) / 10000;
	
			balances[listing.seller] += sellerAmount;
			balances[owner()] += feeAmount;
		}

		//transfer the assets		        
        IComposableItem(listing.tokenAddress).mint(_msgSender(), listing.tokenId, quantity, "");

		//emit event
        emit ListingFilled(
        	listingId,
        	_msgSender(),
        	listing.tokenAddress, listing.tokenId,
        	listing.seller,
        	listing.price,
        	quantity,
        	sellerAmount,
        	feeAmount
        );
    }
    
    function withdraw(address to, uint256 amount) external nonReentrant whenNotPaused {
    	require(amount <= balances[_msgSender()], "ComposablesMarket: amount greater than balance");
    	
    	balances[_msgSender()] -= amount;

        payable(to).transfer(amount);
        
        emit Withdrawal(to, amount);
    }
    
    /**
     * @notice Set the listing fee basis points.
     * @dev Only callable by the owner.
     */
    function setListingFee(uint256 _listingFee) external override onlyOwner {
        listingFee = _listingFee;

        emit ListingFeeUpdated(_listingFee);
    }
    

    /**
     * @notice Pause the market
     * @dev This function can only be called by the owner
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the market
     * @dev This function can only be called by the owner
     */
    function unpause() external override onlyOwner {
        _unpause();
    }
}