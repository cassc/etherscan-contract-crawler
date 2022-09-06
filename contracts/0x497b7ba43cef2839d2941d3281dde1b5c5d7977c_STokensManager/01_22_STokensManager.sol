// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

import {IERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ISTokensManager} from "@devprotocol/i-s-tokens/contracts/interfaces/ISTokensManager.sol";
import {ISTokenManagerStruct} from "./interface/ISTokenManagerStruct.sol";
import {ISTokenManagerDescriptor} from "./interface/ISTokenManagerDescriptor.sol";
import {ITokenURIDescriptor} from "./interface/ITokenURIDescriptor.sol";
import {IAddressConfig} from "./interface/IAddressConfig.sol";
import {ILockup} from "./interface/ILockup.sol";
import {IProperty} from "./interface/IProperty.sol";

contract STokensManager is
	ISTokenManagerStruct,
	ISTokensManager,
	IERC721EnumerableUpgradeable,
	ERC721Upgradeable
{
	Counters.Counter private tokenIdCounter;
	address public config;
	mapping(bytes32 => bytes) private bytesStorage;
	mapping(address => uint256[]) private tokenIdsMap;
	mapping(address => EnumerableSet.UintSet) private tokenIdsMapOfOwner;
	mapping(uint256 => string) private tokenUriImage;
	mapping(uint256 => bool) public override isFreezed;
	address public descriptor;
	mapping(address => address) public override descriptorOf;
	mapping(uint256 => bytes32) public override payloadOf;

	using Counters for Counters.Counter;
	using EnumerableSet for EnumerableSet.UintSet;

	modifier onlyAuthor(uint256 _tokenId) {
		StakingPositionV1 memory currentPosition = getStoragePositionsV1(
			_tokenId
		);
		address author = IProperty(currentPosition.property).author();
		require(author == _msgSender(), "illegal access");
		_;
	}

	modifier onlyPropertyAuthor(address _property) {
		address author = IProperty(_property).author();
		require(author == _msgSender(), "illegal access");
		_;
	}

	modifier onlyLockup() {
		require(
			IAddressConfig(config).lockup() == _msgSender(),
			"illegal access"
		);
		_;
	}

	function initialize(address _config) external initializer {
		__ERC721_init("Dev Protocol sTokens V1", "DEV-STOKENS-V1");
		config = _config;
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(IERC165Upgradeable, ERC721Upgradeable)
		returns (bool)
	{
		return
			interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	/**
	 * @dev See {IERC721Enumerable-totalSupply}.
	 */
	function totalSupply() public view virtual override returns (uint256) {
		return tokenIdCounter.current();
	}

	/**
	 * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
	 */
	function tokenOfOwnerByIndex(address owner, uint256 index)
		public
		view
		virtual
		override
		returns (uint256)
	{
		// solhint-disable-next-line reason-string
		require(
			index < tokenIdsMapOfOwner[owner].length(),
			"ERC721Enumerable: owner index out of bounds"
		);
		return tokenIdsMapOfOwner[owner].at(index);
	}

	/**
	 * @dev See {IERC721Enumerable-tokenByIndex}.
	 */
	function tokenByIndex(uint256 index)
		public
		view
		virtual
		override
		returns (uint256)
	{
		// solhint-disable-next-line reason-string
		require(
			index < tokenIdCounter.current(),
			"ERC721Enumerable: global index out of bounds"
		);
		return index + 1;
	}

	function setDescriptor(address _descriptor) external {
		require(descriptor == address(0), "already set");
		descriptor = _descriptor;
	}

	function tokenURI(uint256 _tokenId)
		public
		view
		override
		returns (string memory)
	{
		uint256 curretnTokenId = tokenIdCounter.current();
		require(_tokenId <= curretnTokenId, "not found");
		StakingPositionV1 memory positons = getStoragePositionsV1(_tokenId);
		RewardsV1 memory tokenRewards = _rewards(_tokenId);
		address owner = ownerOf(_tokenId);
		return
			_tokenURI(
				_tokenId,
				owner,
				positons,
				tokenRewards,
				payloadOf[_tokenId]
			);
	}

	function tokenURISim(
		uint256 _tokenId,
		address _owner,
		StakingPositionV1 memory _positions,
		RewardsV1 memory _rewardsArg,
		bytes32 _payload
	) external view returns (string memory) {
		return _tokenURI(_tokenId, _owner, _positions, _rewardsArg, _payload);
	}

	function currentIndex() external view override returns (uint256) {
		return tokenIdCounter.current();
	}

	function mint(
		address _owner,
		address _property,
		uint256 _amount,
		uint256 _price,
		bytes32 _payload
	) external override onlyLockup returns (uint256 tokenId_) {
		tokenIdCounter.increment();
		uint256 currentId = tokenIdCounter.current();
		_mint(_owner, currentId);
		emit Minted(currentId, _owner, _property, _amount, _price);
		StakingPositionV1 memory newPosition = StakingPositionV1(
			_property,
			_amount,
			_price,
			0,
			0
		);
		setStoragePositionsV1(currentId, newPosition);
		tokenIdsMap[_property].push(currentId);

		address _descriptor = descriptorOf[_property];
		if (_descriptor != address(0)) {
			require(
				ITokenURIDescriptor(_descriptor).onBeforeMint(
					currentId,
					_owner,
					newPosition,
					_payload
				),
				"failed to call onBeforeMint"
			);
		}
		payloadOf[currentId] = _payload;

		return currentId;
	}

	function update(
		uint256 _tokenId,
		uint256 _amount,
		uint256 _price,
		uint256 _cumulativeReward,
		uint256 _pendingReward
	) external override onlyLockup returns (bool) {
		StakingPositionV1 memory currentPosition = getStoragePositionsV1(
			_tokenId
		);
		currentPosition.amount = _amount;
		currentPosition.price = _price;
		currentPosition.cumulativeReward = _cumulativeReward;
		currentPosition.pendingReward = _pendingReward;
		setStoragePositionsV1(_tokenId, currentPosition);
		emit Updated(
			_tokenId,
			_amount,
			_price,
			_cumulativeReward,
			_pendingReward
		);
		return true;
	}

	function setTokenURIImage(uint256 _tokenId, string memory _data)
		external
		override
		onlyAuthor(_tokenId)
	{
		require(isFreezed[_tokenId] == false, "freezed");
		tokenUriImage[_tokenId] = _data;
	}

	function setTokenURIDescriptor(address _property, address _descriptor)
		external
		override
		onlyPropertyAuthor(_property)
	{
		descriptorOf[_property] = _descriptor;
	}

	function freezeTokenURI(uint256 _tokenId)
		external
		override
		onlyAuthor(_tokenId)
	{
		require(isFreezed[_tokenId] == false, "already freezed");
		string memory tokeUri = tokenUriImage[_tokenId];
		require(bytes(tokeUri).length != 0, "no data");
		isFreezed[_tokenId] = true;
		emit Freezed(_tokenId, _msgSender());
	}

	function positions(uint256 _tokenId)
		external
		view
		override
		returns (
			address property_,
			uint256 amount_,
			uint256 price_,
			uint256 cumulativeReward_,
			uint256 pendingReward_
		)
	{
		StakingPositionV1 memory currentPosition = getStoragePositionsV1(
			_tokenId
		);
		return (
			currentPosition.property,
			currentPosition.amount,
			currentPosition.price,
			currentPosition.cumulativeReward,
			currentPosition.pendingReward
		);
	}

	function rewards(uint256 _tokenId)
		external
		view
		override
		returns (
			uint256 entireReward_,
			uint256 cumulativeReward_,
			uint256 withdrawableReward_
		)
	{
		RewardsV1 memory tokenRewards = _rewards(_tokenId);
		return (
			tokenRewards.entireReward,
			tokenRewards.cumulativeReward,
			tokenRewards.withdrawableReward
		);
	}

	function positionsOfProperty(address _property)
		external
		view
		override
		returns (uint256[] memory)
	{
		return tokenIdsMap[_property];
	}

	function positionsOfOwner(address _owner)
		external
		view
		override
		returns (uint256[] memory)
	{
		return tokenIdsMapOfOwner[_owner].values();
	}

	function _rewards(uint256 _tokenId)
		private
		view
		returns (RewardsV1 memory)
	{
		address lockupAddress = IAddressConfig(config).lockup();
		uint256 withdrawableReward = ILockup(lockupAddress)
			.calculateWithdrawableInterestAmountByPosition(_tokenId);
		StakingPositionV1 memory currentPosition = getStoragePositionsV1(
			_tokenId
		);
		uint256 cumulativeReward = currentPosition.cumulativeReward;
		uint256 entireReward = cumulativeReward + withdrawableReward;

		return RewardsV1(entireReward, cumulativeReward, withdrawableReward);
	}

	function _tokenURI(
		uint256 _tokenId,
		address _owner,
		StakingPositionV1 memory _positions,
		RewardsV1 memory _rewardsArg,
		bytes32 _payload
	) private view returns (string memory) {
		string memory _tokeUriImage = tokenUriImage[_tokenId];
		if (bytes(_tokeUriImage).length == 0) {
			address descriptorOfProperty = descriptorOf[_positions.property];
			if (descriptorOfProperty != address(0)) {
				_tokeUriImage = ITokenURIDescriptor(descriptorOfProperty).image(
						_tokenId,
						_owner,
						_positions,
						_rewardsArg,
						_payload
					);
			}
		}
		return
			ISTokenManagerDescriptor(descriptor).getTokenURI(
				_positions.property,
				_positions.amount,
				_positions.cumulativeReward,
				_tokeUriImage
			);
	}

	function getStoragePositionsV1(uint256 _tokenId)
		private
		view
		returns (StakingPositionV1 memory)
	{
		bytes32 key = getStoragePositionsV1Key(_tokenId);
		bytes memory tmp = bytesStorage[key];
		return abi.decode(tmp, (StakingPositionV1));
	}

	function setStoragePositionsV1(
		uint256 _tokenId,
		StakingPositionV1 memory _position
	) private {
		bytes32 key = getStoragePositionsV1Key(_tokenId);
		bytes memory tmp = abi.encode(_position);
		bytesStorage[key] = tmp;
	}

	function getStoragePositionsV1Key(uint256 _tokenId)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_positionsV1", _tokenId));
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override {
		super._beforeTokenTransfer(from, to, tokenId);

		if (from == address(0)) {
			// mint
			tokenIdsMapOfOwner[to].add(tokenId);
		} else if (to == address(0)) {
			// burn
			revert("s tokens is not burned");
		} else if (to != from) {
			tokenIdsMapOfOwner[from].remove(tokenId);
			tokenIdsMapOfOwner[to].add(tokenId);
		}
	}
}