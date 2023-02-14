// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../extension/ERC721Envious.sol";
import "../interfaces/IERC721EnviousDynamic.sol";
import "../openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "../openzeppelin/token/ERC20/IERC20.sol";
import "../openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../openzeppelin/utils/Address.sol";
import "../openzeppelin/utils/Strings.sol";
import "../openzeppelin/utils/Counters.sol";

/**
 * @title ERC721 Collateralization Dynamic Mock
 * This mock shows an implementation of ERC721Envious with dynamic URI.
 * It will change on every collateral modification. Handmade `totalSupply` 
 * function will be used in order to be used in {_disperse} function.
 *
 * @author 5Tr3TcH @ghostchain
 * @author 571nkY @ghostchain
 */
contract ERC721EnviousDynamicPreset is IERC721EnviousDynamic, ERC721Enumerable, ERC721Envious {

	using SafeERC20 for IERC20;
	using Address for address;
	using Strings for uint256;
	using Counters for Counters.Counter;

	string private _baseTokenURI;
	Counters.Counter private _tokenTracker;

	// token that will be used for dynamic measurment
	address public measurmentTokenAddress;

	// edges within which redistribution of URI will take place
	Edge[] public edges;

	// solhint-disable-next-line
	string private constant ZERO_ADDRESS = "zero address found";
	
	constructor(
		string memory tokenName,
		string memory tokenSymbol,
		string memory baseTokenURI,
		uint256[] memory edgeValues,
		uint256[] memory edgeOffsets,
		uint256[] memory edgeRanges,
		address tokenMeasurment
	) ERC721(tokenName, tokenSymbol) {
		require(tokenMeasurment != address(0), ZERO_ADDRESS);
		require(
			edgeValues.length == edgeOffsets.length && 
			edgeValues.length == edgeRanges.length,
			ZERO_ADDRESS
		);

		measurmentTokenAddress = tokenMeasurment;
		_changeBaseURI(baseTokenURI);

		for (uint256 i = 0; i < edgeValues.length; i++) {
			edges.push(Edge({
				value: edgeValues[i], 
				offset: edgeOffsets[i], 
				range: edgeRanges[i]
			}));
		}
	}

	receive() external payable {
		_disperseTokenCollateral(msg.value, address(0));
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(IERC165, ERC721Enumerable, ERC721Envious)
		returns (bool)
	{
		return interfaceId == type(IERC721EnviousDynamic).interfaceId ||
			ERC721Enumerable.supportsInterface(interfaceId) ||
			ERC721Envious.supportsInterface(interfaceId);
	}

	/**
	 * @dev See {_baseURI}.
	 */
	function baseURI() external view virtual returns (string memory) {
		return _baseURI();
	}

	/**
	 * @dev Getter function for each token URI.
	 *
	 * Requirements:
	 * - `tokenId` must exist.
	 *
	 * @param tokenId unique identifier of token
	 * @return token URI string
	 */
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		_requireMinted(tokenId);
		
		string memory currentURI = _baseURI();
		uint256 tokenPointer = getTokenPointer(tokenId);
		return string(abi.encodePacked(currentURI, tokenPointer.toString(), ".json"));
	}

	/**
	 * @dev Get `tokenURI` for specific token based on predefined `edges`.
	 *
	 * @param tokenId unique identifier for token
	 */
	function getTokenPointer(uint256 tokenId) public view virtual override returns (uint256) {
		uint256 collateral = collateralBalances[tokenId][measurmentTokenAddress];
		uint256 totalDisperse = disperseBalance[measurmentTokenAddress] / totalSupply();
		uint256	takenDisperse = disperseTaken[tokenId][measurmentTokenAddress];
		uint256 value = collateral + totalDisperse - takenDisperse;

		uint256 range = 1;
		uint256 offset = 0;

		for (uint256 i = edges.length; i > 0; i--) {
			if (value >= edges[i-1].value) {
				range = edges[i-1].range;
				offset = edges[i-1].offset;
				break;
			}
		}

		uint256 seed = uint256(keccak256(abi.encodePacked(tokenId, collateral, totalDisperse))) % range;
		return seed + offset;
	}

	/**
	 * @dev Set ghost related addresses.
	 *
	 * Requirements:
	 * - `ghostAddress` must be non-zero address
	 * - `ghostBonding` must be non-zero address
	 *
	 * @param ghostToken non-rebasing wrapping token address
	 * @param ghostBonding bonding contract address
	 */
	function setGhostAddresses(
		address ghostToken, 
		address ghostBonding
	) public virtual {
		require(
			ghostToken != address(0) && ghostBonding != address(0),
			ZERO_ADDRESS
		);
		_changeGhostAddresses(ghostToken, ghostBonding);
	}

	/**
	 * @dev See {IERC721Envious-_changeCommunityAddresses}.
	 */
	function changeCommunityAddresses(address newTokenAddress, address newBlackHole) public virtual {
		require(newTokenAddress != address(0), ZERO_ADDRESS);
		_changeCommunityAddresses(newTokenAddress, newBlackHole);
	}

	/**
	 * @dev See {ERC721EnviousDynamic-mint}
	 */
	function mint(address to) public virtual override {
		_tokenTracker.increment();
		_safeMint(to, _tokenTracker.current());
	}

	/**
	 * @dev See {ERC721-_burn}
	 */
	function burn(uint256 tokenId) public virtual {
		_burn(tokenId);
	}

	/**
	 * @dev See {ERC721Envious-_disperse}
	 */
	function _disperse(address tokenAddress, uint256 tokenId) internal virtual override {
		uint256 balance = disperseBalance[tokenAddress] / totalSupply();

		if (disperseTotalTaken[tokenAddress] + balance > disperseBalance[tokenAddress]) {
			balance = disperseBalance[tokenAddress] - disperseTotalTaken[tokenAddress];
		}

		if (balance > disperseTaken[tokenId][tokenAddress]) {
			uint256 amount = balance - disperseTaken[tokenId][tokenAddress];
			disperseTaken[tokenId][tokenAddress] += amount;

			(bool shouldAppend,) = _arrayContains(tokenAddress, collateralTokens[tokenId]);
			if (shouldAppend) {
				collateralTokens[tokenId].push(tokenAddress);
			}
			
			collateralBalances[tokenId][tokenAddress] += amount;
			disperseTotalTaken[tokenAddress] += amount;
		}
	}

	/**
	 * @dev Getter function for `_baseTokenURI`.
	 *
	 * @return base URI string
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}

	/**
	 * @dev Ability to change URI for the collection.
	 */
	function _changeBaseURI(string memory newBaseURI) internal virtual {
		_baseTokenURI = newBaseURI;
	}

	/**
	 * @dev See {ERC721-_beforeTokenTransfer}.
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 firstTokenId,
		uint256 batchSize
	) internal virtual override(ERC721, ERC721Enumerable) {
		ERC721Enumerable._beforeTokenTransfer(from, to, firstTokenId, batchSize);
	}
}