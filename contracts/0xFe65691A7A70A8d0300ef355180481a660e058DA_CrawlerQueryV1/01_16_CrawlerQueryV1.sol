// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Query Utility v.1
/// @author Studio Avante
/// @notice Miscellaneous functions for fetching Endless Crawler data
/// @dev Depends on IERC721Enumerable (chambers), IERC1155 (cards) and ICardsStore
//
pragma solidity ^0.8.16;
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import { IERC721Metadata } from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import { IERC1155MetadataURI } from '@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';
import { ERC165Checker } from '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import { ICrawlerQuery } from './ICrawlerQuery.sol';
import { ICrawlerToken } from './ICrawlerToken.sol';
import { ICardsMinter } from './external/ICardsMinter.sol';
import { ICardsStore } from './external/ICardsStore.sol';
import { CrawlerContract } from './CrawlerContract.sol';

contract CrawlerQueryV1 is CrawlerContract, ICrawlerQuery {

	ICrawlerToken private _tokenContract;
	ICardsMinter private _cardsContract;
	ICardsStore private _storeContract;

	constructor(address tokenContract_, address cardsContract_, address storeContract_) {
		setupCrawlerContract('Query', 1, 1);
		_tokenContract = ICrawlerToken(tokenContract_);
		_cardsContract = ICardsMinter(cardsContract_);
		_storeContract = ICardsStore(storeContract_);
	}

	/// @notice Returns the Chambers contract
	/// @return result Contract address
  function getChambersContract() external view returns (ICrawlerToken) {
		return _tokenContract;
	}

	/// @notice Returns the Cards contract
	/// @return result Contract address
	function getCardsContract() external view returns (ICardsMinter) {
		return _cardsContract;
	}

	/// @notice Returns the CardsStore contract
	/// @return result Contract address
	function getStoreContract() external view returns (ICardsStore) {
		return _storeContract;
	}

	/// @notice Returns all Chambers owned by a player
	/// @param account Owner account
	/// @return result Array containing owned token ids, not guarantee to be in order
	function getOwnedChambers(address account) public view override returns (uint256[] memory result) {
		result = new uint256[](_tokenContract.balanceOf(account));
		for(uint256 i = 0 ; i < result.length ; i++) {
			result[i] = _tokenContract.tokenOfOwnerByIndex(account, i);
		}
		return result;
	}

	/// @notice Returns all Cards owned by a player
	/// @param account Owner account
	/// @param cardType Filter by card type
	/// @return result Array containing balances of all card ids, in order, startintg at id 1
	function getOwnedCards(address account, uint8 cardType) public view override returns (uint256[] memory result) {
		// TODO: next version will grant all cards to Founders, EXCEPT OTHER CLASS TOKENS
		result = new uint256[](_storeContract.getCardCount());
		for(uint256 i = 0 ; i < result.length ; i++) {
			uint256 id = i + 1;
			uint256 balance = _cardsContract.balanceOf(account, id);
			// TODO: next version will get card type from ICardsStore contract
			result[i] = (cardType == 0 || (cardType == 1 && id <= 4)) ? balance : 0;
		}
		return result;
	}

	/// @notice Check if an account owns a token (ERC-721 or ERC-1155)
	/// @param tokenContract the CrawlerToken contract address
	/// @param id the token id
	/// @param account owner account
	/// @return result True if account is owner
	/// @dev Never reverts, will return False if token does not exist or contract is not compatible
	function isOwner(address tokenContract, uint256 id, address account) public view override returns (bool) {
		if(ERC165Checker.supportsInterface(tokenContract, type(IERC721).interfaceId)) {
			try IERC721(tokenContract).ownerOf(id) returns (address owner) {
				return (owner == account);
			} catch Error(string memory) {
				return false;
			}
		} else if(ERC165Checker.supportsInterface(tokenContract, type(IERC1155).interfaceId)) {
			try IERC1155(tokenContract).balanceOf(account, id) returns (uint256 balance) {
				return (balance > 0);
			} catch Error(string memory) {
				return false;
			}
		}
		return false;
	}

	/// @notice Returns a token metadata (ERC-721 or ERC-1155)
	/// @param tokenContract the CrawlerToken contract address
	/// @param id the token id
	/// @return result Metadata
	/// @dev Reverts if contract is not compatible
	function getURI(address tokenContract, uint256 id) public view override returns (string memory) {
		if(ERC165Checker.supportsInterface(tokenContract, type(IERC721Metadata).interfaceId)) {
			return IERC721Metadata(tokenContract).tokenURI(id);
		}
		if(ERC165Checker.supportsInterface(tokenContract, type(IERC1155MetadataURI).interfaceId)) {
			return IERC1155MetadataURI(tokenContract).uri(id);
		}
		revert('Invalid contract (not ERC721 or ERC1155)');
	}

}