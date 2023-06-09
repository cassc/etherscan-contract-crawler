// SPDX-License-Identifier: MIT
//
//  ********  **     **    ******   **        **  *******  
// /**/////  /**    /**   **////** /**       /** /**////** 
// /**       /**    /**  **    //  /**       /** /**    /**
// /*******  /**    /** /**        /**       /** /**    /**
// /**////   /**    /** /**        /**       /** /**    /**
// /**       /**    /** //**    ** /**       /** /**    ** 
// /******** //*******   //******  /******** /** /*******  
// ////////   ///////     //////   ////////  //  ///////   
//
// by collect-code 2022
// https://collect-code.com/
//
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IParent is IERC721, IERC721Enumerable, IERC721Metadata {
}

struct WhitelistStorage {
	IParent parent;
	uint8 mintsPerSource;
	uint8 mintsPerBuilt;
	mapping(uint256 => uint8) mintsByTokenId;
}

library Whitelist {

	function setupContract(WhitelistStorage storage self, address contractAddress, uint8 newMintsPerSource, uint8 newMintsPerBuilt) public {
		self.parent = IParent(contractAddress);
		self.mintsPerSource = newMintsPerSource;
		self.mintsPerBuilt = newMintsPerBuilt;
	}

	function isTokenBuilt(WhitelistStorage storage self, uint256 tokenId) public view returns (bool) {
		bytes memory uri = bytes(self.parent.tokenURI(tokenId));
		return (uri[uri.length-1] != '=');
	}

	function calcAllowedMintsPerTokenId(WhitelistStorage storage self, uint256 tokenId) public view returns (uint8) {
		try self.parent.ownerOf(tokenId) returns (address /*owner*/) {
		} catch {
			return 0; // token does not exist
		}
		if(self.mintsPerBuilt > 0 && isTokenBuilt(self, tokenId)) {
			return self.mintsPerBuilt;
		}
		return self.mintsPerSource;
	}

	function calcAvailableMintsPerTokenId(WhitelistStorage storage self, uint256 tokenId) public view returns (uint8) {
		uint8 allowedMints = calcAllowedMintsPerTokenId(self, tokenId);
		if (self.mintsByTokenId[tokenId] >= allowedMints) { // avoid negative result
			return 0; // none available
		}
		return (allowedMints - self.mintsByTokenId[tokenId]);
	}

	function getAvailableMintsForUser(WhitelistStorage storage self, address to) public view returns (uint256[] memory, uint8[] memory) {
		uint256 balance = self.parent.balanceOf(to);
		uint256[] memory tokenIds = new uint256[](balance);
		uint8[] memory available = new uint8[](balance);
		for(uint256 i = 0 ; i < balance ; i++) {
			tokenIds[i] = self.parent.tokenOfOwnerByIndex(to, i);
			available[i] = calcAvailableMintsPerTokenId(self, tokenIds[i]);
		}
		return (tokenIds, available);
	}

	function claimTokenIds(WhitelistStorage storage self, uint256[] memory tokenIds) public returns (uint8 quantity) {
		for(uint256 i = 0 ; i < tokenIds.length ; i++) {
			require(self.parent.ownerOf(tokenIds[i]) == msg.sender, "Whitelist: Not Owner");
			uint8 available = calcAvailableMintsPerTokenId(self, tokenIds[i]);
			if(available > 0) {
				self.mintsByTokenId[tokenIds[i]] += available;
				quantity += available;
			}
		}
		require(quantity > 0, "Whitelist: None available");
	}
}