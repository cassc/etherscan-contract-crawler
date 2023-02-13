// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";
import "./openzeppelin/utils/Address.sol";
import "./openzeppelin/utils/Context.sol";

import "./interfaces/IEnviousHouse.sol";
import "./interfaces/IERC721Envious.sol";
import "./interfaces/IBondDepository.sol";
import "./interfaces/INoteKeeper.sol";

/**
 * @title EnviousHouse is contract for any NFT to be collateralized.
 *
 * @author F4T50 @ghostchain
 * @author 571nkY @ghostchain
 * @author 5Tr3TcH @ghostchain
 *
 * @dev The main idea is to maintain any existant ERC721-based token. For any new Envious NFT this smart contract 
 * is optionally needed, only for registration purposes. That's why all Envious functionality is re-routed if 
 * functionality exists and otherwise duplicates it here.
 *
 * NOTE: We are using additional key in all mappings. Key is `collection` address. For more in-depth documentation 
 * visit the parent smart contract {ERC721Envious}.
 */
contract EnviousHouse is Context, IEnviousHouse {
	using SafeERC20 for IERC20;

	uint256 private _totalCollections;
	address private _initializor;

	uint256 public immutable registerAmount;

	address private _ghostAddress;
	address private _ghostBondingAddress;
	address private _blackHole;
	
	mapping(address => uint256[2]) private _commissions;
	mapping(address => address) private _communityToken;
	mapping(address => address[]) private _communityPool;
	mapping(address => mapping(address => uint256)) private _communityBalance;

	mapping(address => address[]) private _disperseTokens;
	mapping(address => mapping(address => uint256)) private _disperseBalance;
	mapping(address => mapping(address => uint256)) private _disperseTotalTaken;
	mapping(address => mapping(uint256 => mapping(address => uint256))) private _disperseTaken;

	mapping(address => mapping(uint256 => uint256)) private _bondPayouts;
	mapping(address => mapping(uint256 => uint256[])) private _bondIndexes;

	mapping(address => mapping(uint256 => address[])) private _collateralTokens;
	mapping(address => mapping(uint256 => mapping(address => uint256))) private _collateralBalances;
	
	mapping(uint256 => address) public override collections;
	mapping(address => uint256) public override collectionIds;
	mapping(address => bool) public override specificCollections;

	// solhint-disable-next-line
	string private constant NO_DECIMALS = "no decimals";
	// solhint-disable-next-line
	string private constant LOW_AMOUNT = "low amount";
	// solhint-disable-next-line
	string private constant NOT_TOKEN_OWNER = "not token owner";
	// solhint-disable-next-line
	string private constant INVALID_TOKEN_ID = "invalid tokenId";
	// solhint-disable-next-line
	string private constant EMPTY_GHOST = "ghst address is empty";
	// solhint-disable-next-line
	string private constant LENGTHS_NOT_MATCH = "lengths not match";
	// solhint-disable-next-line
	string private constant ZERO_COMMUNITY_TOKEN = "no community token provided";
	// solhint-disable-next-line
	string private constant COLLECTION_EXISTS = "collection exists";
	// solhint-disable-next-line
	string private constant COLLECTION_NOT_EXISTS = "collection not exists";
	// solhint-disable-next-line
	string private constant INVALID_COLLECTION = "invalid collection address";
	// solhint-disable-next-line
	string private constant NO_TOKENS_MINTED = "no tokens minted";
	// solhint-disable-next-line
	string private constant ALREADY_ENVIOUS = "already envious";

	constructor (address blackHoleAddress, uint256 minimalEthAmount) {
		_initializor = _msgSender();
		_blackHole = blackHoleAddress;

		registerAmount = minimalEthAmount;
	}

	function totalCollections() external view override returns (uint256) {
		return _totalCollections;
	}

	function ghostAddress(address collection) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).ghostAddress();
		} else {
			return _ghostAddress;
		}
	}

	function ghostBondingAddress(address collection) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).ghostBondingAddress();
		} else {
			return _ghostBondingAddress;
		}
	}

	function blackHole(address collection) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).blackHole();
		} else {
			return _blackHole;
		}
	}

	function commissions(address collection, uint256 index) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).commissions(index);
		} else {
			return _commissions[collection][index];
		}
	}

	function communityToken(address collection) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).communityToken();
		} else {
			return _communityToken[collection];
		}
	}

	function communityPool(address collection, uint256 index) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).communityPool(index);
		} else {
			return _communityPool[collection][index];
		}
	}

	function communityBalance(
		address collection, 
		address tokenAddress
	) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).communityBalance(tokenAddress);
		} else {
			return _communityBalance[collection][tokenAddress];
		}
	}

	function disperseTokens(
		address collection, 
		uint256 index
	) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).disperseTokens(index);
		} else {
			return _disperseTokens[collection][index];
		}
	}

	function disperseBalance(
		address collection, 
		address tokenAddress
	) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).disperseBalance(tokenAddress);
		} else {
			return _disperseBalance[collection][tokenAddress];
		}
	}

	function disperseTotalTaken(
		address collection, 
		address tokenAddress
	) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).disperseTotalTaken(tokenAddress);
		} else {
			return _disperseTotalTaken[collection][tokenAddress];
		}
	}

	function disperseTaken(
		address collection, 
		uint256 tokenId,
		address tokenAddress
	) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).disperseTaken(tokenId, tokenAddress);
		} else {
			return _disperseTaken[collection][tokenId][tokenAddress];
		}
	}

	function bondPayouts(address collection, uint256 tokenId) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).bondPayouts(tokenId);
		} else {
			return _bondPayouts[collection][tokenId];
		}
	}

	function collateralTokens(
		address collection, 
		uint256 tokenId,
		uint256 index
	) external view override returns (address) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).collateralTokens(tokenId, index);
		} else {
			return _collateralTokens[collection][tokenId][index];
		}
	}

	function collateralBalances(
		address collection, 
		uint256 tokenId,
		address tokenAddress
	) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).collateralBalances(tokenId, tokenAddress);
		} else {
			return _collateralBalances[collection][tokenId][tokenAddress];
		}
	}

	function bondIndexes(
		address collection, 
		uint256 tokenId,
		uint256 index
	) external view override returns (uint256) {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).bondIndexes(tokenId, index);
		} else {
			return _bondIndexes[collection][tokenId][index];
		}
	}

	function setGhostAddresses(address ghostToken, address ghostBonding) external override {
		// solhint-disable-next-line
		require(_initializor == _msgSender() && ghostToken != address(0) && ghostBonding != address(0));

		_ghostAddress = ghostToken;
		_ghostBondingAddress = ghostBonding;
	}

	function setSpecificCollection(address collection) external override {
		// solhint-disable-next-line
		require(_initializor == _msgSender() && collection != address(0));

		specificCollections[collection] = true;
	}

	function registerCollection(
		address collection, 
		address token, 
		uint256 incoming, 
		uint256 outcoming
	) external payable override {
		require(collectionIds[collection] == 0, COLLECTION_EXISTS);
		require(
			IERC721(collection).supportsInterface(type(IERC721).interfaceId) ||
			specificCollections[collection],
			INVALID_COLLECTION
		);
		
		_rescueCollection(collection);

		if (!IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			require(msg.value >= registerAmount, LOW_AMOUNT);
			if (incoming != 0 || outcoming != 0) {
				require(token != address(0), ZERO_COMMUNITY_TOKEN);
				require(incoming < 1e5 && outcoming < 1e5, LOW_AMOUNT);

				_commissions[collection][0] = incoming;
				_commissions[collection][1] = outcoming;
				_communityToken[collection] = token;
			}

			_disperseTokenCollateral(collection, msg.value, address(0));
		}
	}

	function harvest(
		address collection, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external override {
		require(collectionIds[collection] != 0, COLLECTION_NOT_EXISTS);
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);
		
		_checkEnvious(collection);

		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			_harvest(collection, amounts[i], tokenAddresses[i]);
		}
	}

	function collateralize(
		address collection, 
		uint256 tokenId, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external payable override {
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);
		
		_checkEnvious(collection);
		_rescueCollection(collection);

		uint256 ethAmount = msg.value;
		
		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			if (tokenAddresses[i] == address(0)) {
				ethAmount -= amounts[i];
			}
			_addTokenCollateral(collection, tokenId, amounts[i], tokenAddresses[i], false);
		}

		if (ethAmount > 0) {
			Address.sendValue(payable(_msgSender()), ethAmount);
		}
	}

	function uncollateralize(
		address collection, 
		uint256 tokenId, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external override {
		require(collectionIds[collection] != 0, COLLECTION_NOT_EXISTS);
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);

		_checkEnvious(collection);

		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			_removeTokenCollateral(collection, tokenId, amounts[i], tokenAddresses[i]);
		}
	}

	function disperse(
		address collection, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external payable override {
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);

		_checkEnvious(collection);
		_rescueCollection(collection);

		uint256 ethAmount = msg.value;
		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			if (tokenAddresses[i] == address(0)) {
				ethAmount -= amounts[i];
			}
			_disperseTokenCollateral(collection, amounts[i], tokenAddresses[i]);
		}

		if (ethAmount > 0) {
			Address.sendValue(payable(_msgSender()), ethAmount);
		}
	}

	function getDiscountedCollateral(
		address collection,
		uint256 bondId,
		address quoteToken,
		uint256 tokenId,
		uint256 amount,
		uint256 maxPrice
	) external override {
		require(collectionIds[collection] != 0, COLLECTION_NOT_EXISTS);
		
		_checkEnvious(collection);
		_rescueCollection(collection);
		
		// NOTE: this contract is temporary holder of `quoteToken` due to the need of
		// registration of bond inside. `amount` of `quoteToken`s should be empty in
		// the end of transaction.
		IERC20(quoteToken).safeTransferFrom(_msgSender(), address(this), amount);
		IERC20(quoteToken).safeApprove(_ghostBondingAddress, amount);
		
		(uint256 payout,, uint256 index) = IBondDepository(_ghostBondingAddress).deposit(
			bondId,
			amount,
			maxPrice,
			address(this),
			address(this)
		);
		
		if (payout > 0) {
			_bondPayouts[collection][tokenId] += payout;
			_bondIndexes[collection][tokenId].push(index);
		}
	}
	
	function claimDiscountedCollateral(
		address collection,
		uint256 tokenId,
		uint256[] memory indexes
	) external override {
		require(collectionIds[collection] != 0, COLLECTION_NOT_EXISTS);
		require(_ghostAddress != address(0), EMPTY_GHOST);
		
		_checkEnvious(collection);
		
		for (uint256 i = 0; i < indexes.length; i++) {
			uint256 index = _arrayContains(indexes[i], _bondIndexes[collection][tokenId]);
			uint256 last = _bondIndexes[collection][tokenId].length - 1;
			_bondIndexes[collection][tokenId][index] = _bondIndexes[collection][tokenId][last];
			_bondIndexes[collection][tokenId].pop();
		}
		
		uint256 payout = INoteKeeper(_ghostBondingAddress).redeem(address(this), indexes, true);
		
		if (payout > 0) {
			_bondPayouts[collection][tokenId] -= payout;
			_addTokenCollateral(collection, tokenId, payout, _ghostAddress, true);
		}
	}
	
	function getAmount(
		address collection,
		uint256 amount,
		address tokenAddress
	) public view override returns (uint256) {
		require(collectionIds[collection] != 0, COLLECTION_NOT_EXISTS);
		
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			return IERC721Envious(collection).getAmount(amount, tokenAddress);
		} else {
			uint256 circulatingSupply =
				IERC20(_communityToken[collection]).totalSupply() - 
				IERC20(_communityToken[collection]).balanceOf(_blackHole);
			return amount * _scaledAmount(collection, tokenAddress) / circulatingSupply;
		}
	}

	function _arrayContains(
		address tokenAddress,
		address[] memory findFrom
	) private pure returns (bool shouldAppend, uint256 index) {
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

	function _arrayContains(
		uint256 noteId,
		uint256[] memory findFrom
	) private pure returns (uint256 index) {
		index = type(uint256).max;
		
		for (uint256 i = 0; i < findFrom.length; i++) {
			if (findFrom[i] == noteId) {
				index = i;
				break;
			}
		}
	}
	
	function _scaledAmount(address collection, address tokenAddress) private view returns (uint256) {
		uint256 totalValue = 0;
		uint256 scaled = 0;
		uint256 defaultDecimals = 10**IERC20Metadata(_communityToken[collection]).decimals();
		
		for (uint256 i = 0; i < _communityPool[collection].length; i++) {
			uint256 innerDecimals = _communityPool[collection][i] == address(0) ? 
				10**18 : 
				10**IERC20Metadata(_communityPool[collection][i]).decimals();
			
			uint256 tempValue =
				_communityBalance[collection][_communityPool[collection][i]] * 
				defaultDecimals / innerDecimals;
			
			totalValue += tempValue;
			
			if (_communityPool[collection][i] == tokenAddress) {
				scaled = tempValue;
			}
		}
		
		return _communityBalance[collection][tokenAddress] * totalValue / scaled;
	}

	function _harvest(address collection, uint256 amount, address tokenAddress) private {
		uint256 scaledAmount = getAmount(collection, amount, tokenAddress);
		_communityBalance[collection][tokenAddress] -= scaledAmount;
		
		if (_communityBalance[collection][tokenAddress] == 0) {
			(, uint256 index) = _arrayContains(tokenAddress, _communityPool[collection]);
			_communityPool[collection][index] =
				_communityPool[collection][_communityPool[collection].length - 1];
			_communityPool[collection].pop();
		}
		
		if (tokenAddress == address(0)) {
			Address.sendValue(payable(_msgSender()), scaledAmount);
		} else {
			IERC20(tokenAddress).safeTransfer(_msgSender(), scaledAmount);
		}
		
		// NOTE: not every token implements `burn` function, so that is a littl cheat
		IERC20(_communityToken[collection]).safeTransferFrom(_msgSender(), _blackHole, amount);
		
		emit Harvested(collection, tokenAddress, amount, scaledAmount);
	}

	function _addTokenCollateral(
		address collection,
		uint256 tokenId,
		uint256 amount,
		address tokenAddress,
		bool claim
	) private {
		require(amount > 0, LOW_AMOUNT);
		require(IERC721(collection).ownerOf(tokenId) != address(0), INVALID_TOKEN_ID);
		
		_disperse(collection, tokenAddress, tokenId);
		
		(bool shouldAppend,) = _arrayContains(tokenAddress, _collateralTokens[collection][tokenId]);
		if (shouldAppend) {
			_checkValidity(tokenAddress);
			_collateralTokens[collection][tokenId].push(tokenAddress);
		}
		
		uint256 ownerBalance = 
			_communityCommission(collection, amount, _commissions[collection][0], tokenAddress);
		_collateralBalances[collection][tokenId][tokenAddress] += ownerBalance;
		
		if (tokenAddress != address(0) && !claim) {
			IERC20(tokenAddress).safeTransferFrom(_msgSender(), address(this), amount);
		}
		
		emit Collateralized(collection, tokenId, amount, tokenAddress);
	}
	
	function _removeTokenCollateral(
		address collection,
		uint256 tokenId,
		uint256 amount,
		address tokenAddress
	) private {
		require(IERC721(collection).ownerOf(tokenId) == _msgSender(), NOT_TOKEN_OWNER);
		
		_disperse(collection, tokenAddress, tokenId);
		_collateralBalances[collection][tokenId][tokenAddress] -= amount;
		
		if (_collateralBalances[collection][tokenId][tokenAddress] == 0) {
			(, uint256 index) = _arrayContains(tokenAddress, _collateralTokens[collection][tokenId]);
			_collateralTokens[collection][tokenId][index] = 
				_collateralTokens[collection][tokenId][_collateralTokens[collection][tokenId].length - 1];
			_collateralTokens[collection][tokenId].pop();
		}
		
		uint256 ownerBalance =
			_communityCommission(collection, amount, _commissions[collection][1], tokenAddress);
		
		if (tokenAddress == address(0)) {
			Address.sendValue(payable(_msgSender()), ownerBalance);
		} else {
			IERC20(tokenAddress).safeTransfer(_msgSender(), ownerBalance);
		}
		
		emit Uncollateralized(collection, tokenId, ownerBalance, tokenAddress);
	}

	function _disperseTokenCollateral(
		address collection,
		uint256 amount,
		address tokenAddress
	) private {
		require(amount > 0, LOW_AMOUNT);
		
		(bool shouldAppend,) = _arrayContains(tokenAddress, _disperseTokens[collection]);
		if (shouldAppend) {
			_checkValidity(tokenAddress);
			_disperseTokens[collection].push(tokenAddress);
		}
		
		_disperseBalance[collection][tokenAddress] += amount;
		
		if (tokenAddress != address(0)) {
			IERC20(tokenAddress).safeTransferFrom(_msgSender(), address(this), amount);
		}
		
		emit Dispersed(collection, tokenAddress, amount);
	}

	function _checkValidity(address tokenAddress) private view {
		if (tokenAddress != address(0)) {
			require(IERC20Metadata(tokenAddress).decimals() != type(uint8).max, NO_DECIMALS);
		}
    }

	function _communityCommission(
		address collection,
		uint256 amount,
		uint256 percentage,
		address tokenAddress
	) private returns (uint256) {
		uint256 donation = amount * percentage / 1e5;
		
		(bool shouldAppend,) = _arrayContains(tokenAddress, _communityPool[collection]);
		if (shouldAppend && donation > 0) {
			_communityPool[collection].push(tokenAddress);
		}
		
		_communityBalance[collection][tokenAddress] += donation;
		return amount - donation;
	}

	function _disperse(address collection, address tokenAddress, uint256 tokenId) private {
		uint256 balance = _disperseBalance[collection][tokenAddress] / IERC721Enumerable(collection).totalSupply();
		
		if (_disperseTotalTaken[collection][tokenAddress] + balance > _disperseBalance[collection][tokenAddress]) {
			balance = _disperseBalance[collection][tokenAddress] - _disperseTotalTaken[collection][tokenAddress];
		}
		
		if (balance > _disperseTaken[collection][tokenId][tokenAddress]) {
			uint256 amount = balance - _disperseTaken[collection][tokenId][tokenAddress];
			_disperseTaken[collection][tokenId][tokenAddress] += amount;
			
			(bool shouldAppend,) = _arrayContains(tokenAddress, _collateralTokens[collection][tokenId]);
			if (shouldAppend) {
				_collateralTokens[collection][tokenId].push(tokenAddress);
			}
			
			_collateralBalances[collection][tokenId][tokenAddress] += amount;
			_disperseTotalTaken[collection][tokenAddress] += amount;
		}
	}

	function _rescueCollection(address collection) private {
		if (collectionIds[collection] == 0) {
			require(IERC721Enumerable(collection).totalSupply() > 0, NO_TOKENS_MINTED);
			
			_totalCollections += 1;
			collections[_totalCollections] = collection;
			collectionIds[collection] = _totalCollections;
		}
	}

	function _checkEnvious(address collection) private view {
		if (IERC721(collection).supportsInterface(type(IERC721Envious).interfaceId)) {
			revert(ALREADY_ENVIOUS);
		}
	}
}