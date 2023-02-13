// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin/token/ERC721/ERC721.sol";
import "../openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../openzeppelin/token/ERC20/IERC20.sol";
import "../openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "../openzeppelin/utils/Address.sol";

import "../interfaces/IERC721Envious.sol";
import "../interfaces/IBondDepository.sol";
import "../interfaces/INoteKeeper.sol";

/**
 * @title ERC721 Collateralization
 *
 * @author F4T50 @ghostchain
 * @author 571nkY @ghostchain
 * @author 5Tr3TcH @ghostchain
 *
 * @dev This implements an optional extension of {ERC721} defined in the GhostEnvy lightpaper that
 * adds collateralization functionality for all tokens behind this smart contract as well as any
 * unique tokenId can have it's own floor price and/or estimated future price.
 */
abstract contract ERC721Envious is ERC721, IERC721Envious {
	using SafeERC20 for IERC20;

	/// @dev See {IERC721Envious-commissions}
	uint256[2] public override commissions;
	/// @dev See {IERC721Envious-blackHole}
	address public override blackHole;

	/// @dev See {IERC721Envious-ghostAddress}
	address public override ghostAddress;
	/// @dev See {IERC721Envious-ghostBondingAddress}
	address public override ghostBondingAddress;

	/// @dev See {IERC721Envious-communityToken}
	address public override communityToken;
	/// @dev See {IERC721Envious-communityPool}
	address[] public override communityPool;
	/// @dev See {IERC721Envious-communityBalance}
	mapping(address => uint256) public override communityBalance;

	/// @dev See {IERC721Envious-disperseTokens}
	address[] public override disperseTokens;
	/// @dev See {IERC721Envious-disperseBalance}
	mapping(address => uint256) public override disperseBalance;
	/// @dev See {IERC721Envious-disperseTotalTaken}
	mapping(address => uint256) public override disperseTotalTaken;
	/// @dev See {IERC721Envious-disperseTaken}
	mapping(uint256 => mapping(address => uint256)) public override disperseTaken;

	/// @dev See {IERC721Envious-bondPayouts}
	mapping(uint256 => uint256) public override bondPayouts;
	/// @dev See {IERC721Envious-bondIndexes}
	mapping(uint256 => uint256[]) public override bondIndexes;

	/// @dev See {IERC721Envious-collateralTokens}
	mapping(uint256 => address[]) public override collateralTokens;
	/// @dev See {IERC721Envious-collateralBalances}
	mapping(uint256 => mapping(address => uint256)) public override collateralBalances;

	// solhint-disable-next-line
	string private constant LENGTHS_NOT_MATCH = "ERC721Envious: lengths not match";
	// solhint-disable-next-line
	string private constant LOW_AMOUNT = "ERC721Envious: low amount";
	// solhint-disable-next-line
	string private constant EMPTY_GHOST = "ERC721Envious: ghost is empty";
	// solhint-disable-next-line
	string private constant NO_DECIMALS = "ERC721Envious: no decimals";
	// solhint-disable-next-line
	string private constant NOT_TOKEN_OWNER = "ERC721Envious: only for owner";
	// solhint-disable-next-line
	string private constant COMMISSION_TOO_HIGH = "ERC721Envious: commission is too high";

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId)
		public 
		view 
		virtual 
		override(IERC165, ERC721) 
		returns (bool) 
	{
		return interfaceId == type(IERC721Envious).interfaceId || ERC721.supportsInterface(interfaceId);
	}

	/**
	 * @dev See {IERC721Envious-harvest}.
	 */
	function harvest(
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external override virtual {
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);
		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			_harvest(amounts[i], tokenAddresses[i]);
		}
	}

	/**
	 * @dev See {IERC721Envious-collateralize}.
	 */
	function collateralize(
		uint256 tokenId,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external payable override virtual {
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);
		uint256 ethAmount = msg.value;
		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			if (tokenAddresses[i] == address(0)) {
				ethAmount -= amounts[i];
			}
			_addTokenCollateral(tokenId, amounts[i], tokenAddresses[i], false);
		}
		
		if (ethAmount > 0) {
			Address.sendValue(payable(_msgSender()), ethAmount);
		} 
	}

	/**
	 * @dev See {IERC721Envious-uncollateralize}.
	 */
	function uncollateralize(
		uint256 tokenId, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external override virtual {
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);
		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			_removeTokenCollateral(tokenId, amounts[i], tokenAddresses[i]);
		}
	}

	/**
	 * @dev See {IERC721Envious-disperse}.
	 */
	function disperse(
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external payable override virtual {
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);
		uint256 ethAmount = msg.value;
		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			if (tokenAddresses[i] == address(0)) {
				ethAmount -= amounts[i];
			}
			_disperseTokenCollateral(amounts[i], tokenAddresses[i]);
		}
		
		if (ethAmount > 0) {
			Address.sendValue(payable(_msgSender()), ethAmount);
		} 
	}

	/**
	 * @dev See {IERC721Envious-getDiscountedCollateral}.
	 */
	function getDiscountedCollateral(
		uint256 bondId,
		address quoteToken,
		uint256 tokenId,
		uint256 amount,
		uint256 maxPrice
	) external virtual override {
		// NOTE: this contract is temporary holder of `quoteToken` due to the need of
		// registration of bond inside. `amount` of `quoteToken`s should be empty in
		// the end of transaction.
		_requireMinted(tokenId);
		
		IERC20(quoteToken).safeTransferFrom(_msgSender(), address(this), amount);
		IERC20(quoteToken).safeApprove(ghostBondingAddress, amount);
		
		(uint256 payout,, uint256 index) = IBondDepository(ghostBondingAddress).deposit(
			bondId,
			amount,
			maxPrice,
			address(this),
			address(this)
		);
		
		if (payout > 0) {
			bondPayouts[tokenId] += payout;
			bondIndexes[tokenId].push(index);
		}
	}

	/**
	 * @dev See {IERC721Envious-claimDiscountedCollateral}.
	 */
	function claimDiscountedCollateral(
		uint256 tokenId,
		uint256[] memory indexes
	) external virtual override {
		require(ghostAddress != address(0), EMPTY_GHOST);
		
		for (uint256 i = 0; i < indexes.length; i++) {
			uint256 index = _arrayContains(indexes[i], bondIndexes[tokenId]);
			bondIndexes[tokenId][index] = bondIndexes[tokenId][bondIndexes[tokenId].length - 1];
			bondIndexes[tokenId].pop();
		}
		
		uint256 payout = INoteKeeper(ghostBondingAddress).redeem(address(this), indexes, true);
		
		if (payout > 0) {
			bondPayouts[tokenId] -= payout;
			_addTokenCollateral(tokenId, payout, ghostAddress, true);
		}
	}

	/**
	 * @dev See {IERC721Envious-getAmount}
     */
	function getAmount(
		uint256 amount,
		address tokenAddress
	) public view virtual override returns (uint256) {
		uint256 circulatingSupply = IERC20(communityToken).totalSupply() - IERC20(communityToken).balanceOf(blackHole);
		return amount * _scaledAmount(tokenAddress) / circulatingSupply;
	}

	/**
	 * @dev Loop over the array in order to find specific token address index.
	 *
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 * @param findFrom array of addresses in which search should happen
	 *
	 * @return shouldAppend whether address not found and should be added to array
	 * @return index in array, default to uint256 max value if not found
	 */
	function _arrayContains(
		address tokenAddress,
		address[] memory findFrom
	) internal pure virtual returns (bool shouldAppend, uint256 index) {
		shouldAppend = true;
		index = type(uint256).max;

		for (uint256 i = 0; i < findFrom.length; i++) {
			if (findFrom[i] == tokenAddress) {
				shouldAppend = false;
				index = i;
				break;
			}
		}
	}

	/**
	 * @dev Loop over the array in order to find specific note index.
	 *
	 * @param noteId index of note stored previously
	 * @param findFrom array of note indexes
	 *
	 * @return index in array, default to uint256 max value if not found
	 */
	function _arrayContains(
		uint256 noteId,
		uint256[] memory findFrom
	) internal pure virtual returns (uint256 index) {
		index = type(uint256).max;

		for (uint256 i = 0; i < findFrom.length; i++) {
			if (findFrom[i] == noteId) {
				index = i;
				break;
			}
		}
	}

	/**
	 * @dev Calculate amount to harvest with `communityToken` for the collected
	 * commission. Calculation should happen based on all available ERC20 in
	 * `communityPool`.
	 *
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 *
	 * @return maximum scaled proportion
	 */
	function _scaledAmount(address tokenAddress) internal view virtual returns (uint256) {
		uint256 totalValue = 0;
		uint256 scaled = 0;
		uint256 defaultDecimals = 10**IERC20Metadata(communityToken).decimals();

		for (uint256 i = 0; i < communityPool.length; i++) {
			uint256 innerDecimals = communityPool[i] == address(0) ? 10**18 : 10**IERC20Metadata(communityPool[i]).decimals();
			uint256 tempValue = communityBalance[communityPool[i]] * defaultDecimals / innerDecimals;
			
			totalValue += tempValue;

			if (communityPool[i] == tokenAddress) {
				scaled = tempValue;
			}
		}

		return communityBalance[tokenAddress] * totalValue / scaled;
	}

	/**
	 * @dev Function for `communityToken` owners if they want to redeem collected
	 * commission in exchange for `communityToken`, while tokens will be send to
	 * zero address in order to lock them forever.
	 *
	 * @param amount represents amount of `communityToken` to be send
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 */
	function _harvest(uint256 amount, address tokenAddress) internal virtual  {
		uint256 scaledAmount = getAmount(amount, tokenAddress);
		communityBalance[tokenAddress] -= scaledAmount;

		if (communityBalance[tokenAddress] == 0) {
			(, uint256 index) = _arrayContains(tokenAddress, communityPool);
			communityPool[index] = communityPool[communityPool.length - 1];
			communityPool.pop();
		}

		if (tokenAddress == address(0)) {
			Address.sendValue(payable(_msgSender()), scaledAmount);
		} else {
			IERC20(tokenAddress).safeTransfer(_msgSender(), scaledAmount);
		}

		// NOTE: not every token implements `burn` function, so that is a littl cheat
		IERC20(communityToken).safeTransferFrom(_msgSender(), blackHole, amount);

		emit Harvested(tokenAddress, amount, scaledAmount);
	}

	/**
	 * @dev Ability for any user to collateralize any existent ERC721 token with
	 * any ERC20 token.
	 *
	 * Requirements:
	 * - `tokenId` token must exist.
	 * - `amount` should be greater than zero.
	 *
	 * @param tokenId unique identifier of NFT inside current smart contract
	 * @param amount represents amount of ERC20 to be send
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 */
	function _addTokenCollateral(
		uint256 tokenId, 
		uint256 amount, 
		address tokenAddress,
		bool claim
	) internal virtual {
		require(amount > 0, LOW_AMOUNT);
		_requireMinted(tokenId);

		_disperse(tokenAddress, tokenId);

		(bool shouldAppend,) = _arrayContains(tokenAddress, collateralTokens[tokenId]);
		if (shouldAppend) {
			_checkValidity(tokenAddress);
			collateralTokens[tokenId].push(tokenAddress);
		}

		uint256 ownerBalance = _communityCommission(amount, commissions[0], tokenAddress);
		collateralBalances[tokenId][tokenAddress] += ownerBalance;

		if (tokenAddress != address(0) && !claim) {
			IERC20(tokenAddress).safeTransferFrom(_msgSender(), address(this), amount);
		}

		emit Collateralized(tokenId, amount, tokenAddress);
	}

	/**
	 * @dev Ability for ERC721 owner to withdraw ERC20 collateral that was
	 * previously pushed inside.
	 *
	 * Requirements:
	 * - `tokenId` token must exist.
	 * - `amount` must be less or equal than collateralized value.
	 *
	 * @param tokenId unique identifier of NFT inside current smart contract
	 * @param amount represents amount of ERC20 collateral to withdraw
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 */
	function _removeTokenCollateral(
		uint256 tokenId, 
		uint256 amount, 
		address tokenAddress
	) internal virtual {
		require(_ownerOf(tokenId) == _msgSender(), NOT_TOKEN_OWNER);
		_disperse(tokenAddress, tokenId);

		collateralBalances[tokenId][tokenAddress] -= amount;
		if (collateralBalances[tokenId][tokenAddress] == 0) {
			(, uint256 index) = _arrayContains(tokenAddress, collateralTokens[tokenId]);
			collateralTokens[tokenId][index] = collateralTokens[tokenId][collateralTokens[tokenId].length - 1];
			collateralTokens[tokenId].pop();
		}

		uint256 ownerBalance = _communityCommission(amount, commissions[1], tokenAddress);

		if (tokenAddress == address(0)) {
			Address.sendValue(payable(_msgSender()), ownerBalance);
		} else {
			IERC20(tokenAddress).safeTransfer(_msgSender(), ownerBalance);
		}

		emit Uncollateralized(tokenId, ownerBalance, tokenAddress);
	}

	/**
	 * @dev Disperse any input amount of tokens between all token owners in current
	 * smart contract. Balance will be stored inside `disperseBalance` after which
	 * any user can take it with help of {_disperse}.
	 *
	 * Requirements:
	 * - `amount` must be greater than zero.
	 *
	 * @param amount represents amount of ERC20 tokens to disperse
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 */
	function _disperseTokenCollateral(uint256 amount, address tokenAddress) internal virtual {
		require(amount > 0, LOW_AMOUNT);

		(bool shouldAppend,) = _arrayContains(tokenAddress, disperseTokens);
		if (shouldAppend) {
			_checkValidity(tokenAddress);
			disperseTokens.push(tokenAddress);
		}

		disperseBalance[tokenAddress] += amount;
		
		if (tokenAddress != address(0)) {
			IERC20(tokenAddress).safeTransferFrom(_msgSender(), address(this), amount);
		}

		emit Dispersed(tokenAddress, amount);
	}

	/**
	 * @dev Need to check if the token address has this function, because it will be used in
	 * scaledAmount later. Otherwise _scaledAmount will revert on every call.
	 *
	 * Requirements:
	 * - all addresses except zero address, because it is used for ETH
	 * - any check for decimals, the idea is to be reverted if function does not exist
	 *
	 * @param tokenAddress potential address of ERC20 token.
	 */
	function _checkValidity(address tokenAddress) internal virtual {
		if (tokenAddress != address(0)) {
			require(IERC20Metadata(tokenAddress).decimals() != type(uint8).max, NO_DECIMALS);
		}
	}

	/**
	 * @dev Function that calculates output amount after community commission taken.
	 *
	 * @param amount represents amount of ERC20 tokens or ETH to disperse
	 * @param percentage represents commission to be taken
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 *
	 * @return amount after commission
	 */
	function _communityCommission(
		uint256 amount,
		uint256 percentage,
		address tokenAddress
	) internal returns (uint256) {
		uint256 donation = amount * percentage / 1e5;

		(bool shouldAppend,) = _arrayContains(tokenAddress, communityPool);
		if (shouldAppend && donation > 0) {
			communityPool.push(tokenAddress);
		}

		communityBalance[tokenAddress] += donation;
		return amount - donation;
	}

	/**
	 * @dev Ability to change commission.
	 *
	 * @param incoming is commission when user collateralize
	 * @param outcoming is commission when user uncollateralize
	 */
	function _changeCommissions(uint256 incoming, uint256 outcoming) internal virtual {
		require(incoming < 1e5 && outcoming < 1e5, COMMISSION_TOO_HIGH);
		commissions[0] = incoming;
		commissions[1] = outcoming;
	}

	/**
	 * @dev Ability to change commission token.
	 *
	 * @param newTokenAddress represents new token for commission
	 * @param newBlackHole represents address for harvested tokens
	 */
	function _changeCommunityAddresses(address newTokenAddress, address newBlackHole) internal virtual {
		communityToken = newTokenAddress;
		blackHole = newBlackHole;
	}

	/**
	 * @dev Ability to change commission token.
	 *
	 * @param newGhostTokenAddress represents GHST token address
	 * @param newGhostBondingAddress represents ghostDAO bonding contract address
	 */
	function _changeGhostAddresses(
		address newGhostTokenAddress, 
		address newGhostBondingAddress
	) internal virtual {
		ghostAddress = newGhostTokenAddress;
		ghostBondingAddress = newGhostBondingAddress;
	}

	/**
	 * @dev Function that will disperse tokens from `disperseBalance` to any NFT
	 * owner. Should happen during uncollateralize process.
	 *
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 * @param tokenId unique identifier of NFT in collection
	 */
	function _disperse(address tokenAddress, uint256 tokenId) internal virtual {}
}