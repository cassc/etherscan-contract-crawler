// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./interfaces/ITK.sol";

contract TKClaim {
    
		address public killersCollection = 0x0A29F80099E7c7bf9a87C329D687686645fEd073;
		address public wolvesCollection;
		address public dollsCollection;
		address public owner;
		bool public claimsOpen;

    constructor() {
				owner = msg.sender;
    }

		// claims all nfts that weren't claimed yet
		function claim() external {
				uint256[] memory tokens = claimableIds(msg.sender);
				require(tokens.length > 0, "Nothing to claim");
				ITK(wolvesCollection).claim(msg.sender, tokens);
				ITK(dollsCollection).claim(msg.sender, tokens);
		}

		// returns number of claimable nfts in a user's wallet
		function claimableNumber(address user) external view returns(uint256 canClaim) {
				uint256 amountOwned = IERC721(killersCollection).balanceOf(user);
				uint256 i;
				uint256 token;
				for (i ; i < amountOwned ; ){
					token = IERC721Enumerable(killersCollection).tokenOfOwnerByIndex(user, i);
					if (!ITK(wolvesCollection).claims(token)){
						unchecked { ++canClaim; }
					}
					unchecked { ++i; }
				}
		}

		// returns Ids of claimable nfts in a user's wallet
		function claimableIds(address user) public view returns(uint256[] memory) {
				uint256 amountOwned = IERC721(killersCollection).balanceOf(user);
				uint256 i;
				uint256 idx;
				uint256 token;
				uint256[] memory tokens = new uint256[](amountOwned);
				for (i ; i < amountOwned ; ){
					token = IERC721Enumerable(killersCollection).tokenOfOwnerByIndex(user, i);
					if (!ITK(wolvesCollection).claims(token)){
						tokens[idx] = token;
						unchecked { ++idx; }
					}
					unchecked { ++i; }
				}
				assembly {                                                                                                                                                                
      			mstore(tokens, idx)                                                                          
    		}
				return tokens;
		}

		function setClaimsOpen() external {
				require(msg.sender == owner, "Not allowed");
				claimsOpen = true;
		}

		function setCollections(address _wolvesCollection, address _dollsCollection) external {
				require(msg.sender == owner, "Not allowed");
				require(wolvesCollection == address(0)); // can only set this once
				wolvesCollection = _wolvesCollection;
				dollsCollection = _dollsCollection;
		}

}