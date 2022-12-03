// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title SecretSanta
/// @author cesargdm.eth

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import '@openzeppelin/contracts/access/Ownable.sol';

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

struct Gift {
	address participant;
	address collection;
	uint256 itemId;
	uint256 value;
}

enum Participation {
	None,
	Sent,
	Received
}

/**
 * @dev This implementation uses Ownable, a Multisig wallet would be the best
 * owner of this contract or some kind of governance system.
 */
contract SecretSanta is IERC721Receiver, Ownable, ReentrancyGuard, Pausable {
	/**
	 * @dev Timestamp to enable receiving gifts
	 */
	uint256 public receiveTimestamp;

	/**
	 * @dev Gifts received by participants
	 */
	Gift[] private receivedGifts;

	/**
	 * @dev Address to participation status mapping
	 */
	mapping(address => Participation) public participations;

	/**
	 * @dev Better than allowlisting wallets, we allowlist collections
	 * this can be used to make exchanges between small and large communities
	 */
	mapping(address => bool) public approvedCollections;

	modifier onlyNotParticipants(address _from) {
		require(
			participations[_from] != Participation.Sent,
			'SecretSanta: you already sent a gift'
		);

		_;
	}

	modifier onlyApprovedCollection() {
		require(
			approvedCollections[_msgSender()],
			'SecretSanta: this collection is not approved'
		);

		_;
	}

	modifier onlyBeforeReceiveTimestamp() {
		require(
			block.timestamp <= receiveTimestamp,
			'SecretSanta: you can no longer send a gift'
		);

		_;
	}

	constructor(
		uint256 _receiveTimestamp,
		address[] memory _approvedCollections
	) {
		require(
			_receiveTimestamp > block.timestamp,
			'SecretSanta: receiveTimestamp must be in the future'
		);
		receiveTimestamp = _receiveTimestamp;

		for (uint256 i = 0; i < _approvedCollections.length; i++) {
			approvedCollections[_approvedCollections[i]] = true;
		}
	}

	function onERC1155Received(
		address,
		address _from,
		uint256 _tokenId,
		uint256 _value,
		bytes calldata
	)
		external
		whenNotPaused
		onlyBeforeReceiveTimestamp
		onlyApprovedCollection
		onlyNotParticipants(_from)
		returns (bytes4)
	{
		receivedGifts.push(Gift(_from, _msgSender(), _tokenId, _value));
		participations[_from] = Participation.Sent;

		return this.onERC1155Received.selector;
	}

	/**
	 * @dev This doesnt prevent malicious collections from transfering a token,
	 * but won't not take into account any tokens that are not allowed
	 * @notice Don't transfer tokens if your collection is not allowed
	 * @param _from The address which previously owned the token
	 * @param _tokenId The token identifier which is being transferred
	 */
	function onERC721Received(
		address,
		address _from,
		uint256 _tokenId,
		bytes calldata
	)
		external
		whenNotPaused
		onlyBeforeReceiveTimestamp
		onlyApprovedCollection
		onlyNotParticipants(_from)
		returns (bytes4)
	{
		receivedGifts.push(Gift(_from, _msgSender(), _tokenId, 0));
		participations[_from] = Participation.Sent;

		return this.onERC721Received.selector;
	}

	/*

		R E C E I V E

	*/

	/**
	 * @dev Withdraws the NFT from the contract and sends it to the participant
	 */
	function receiveGift() external nonReentrant whenNotPaused {
		require(
			block.timestamp > receiveTimestamp,
			'SecretSanta: receive not yet available'
		);
		require(
			participations[_msgSender()] != Participation.Received,
			"SecretSanta: you've already received a gift"
		);
		require(
			participations[_msgSender()] == Participation.Sent,
			"SecretSanta: you haven't sent a gift"
		);
		require(receivedGifts.length > 0, 'SecretSanta: no gifts available');

		Gift memory gift = receivedGifts[receivedGifts.length - 1];

		require(
			gift.participant != _msgSender(),
			'SecretSanta: you cannot receive your own gift'
		);

		if (gift.value > 0) {
			IERC1155(gift.collection).safeTransferFrom(
				address(this),
				_msgSender(),
				gift.itemId,
				gift.value,
				''
			);
		} else {
			IERC721(gift.collection).safeTransferFrom(
				address(this),
				_msgSender(),
				gift.itemId
			);
		}

		receivedGifts.pop();

		participations[_msgSender()] = Participation.Received;
	}

	/*

		U T I L I T I E S

	*/

	/**
	 * @dev Set the timestamp when participations can start receiving their gifts
	 * @param _receiveTimestamp Timestamp in seconds
	 */
	function setReceiveTimestamp(uint256 _receiveTimestamp) external onlyOwner {
		require(
			_receiveTimestamp > block.timestamp,
			'SecretSanta: receiveTimestamp must be in the future'
		);

		receiveTimestamp = _receiveTimestamp;
	}

	/**
	 * @dev Add a collection to the approvedCollections
	 * @param _collection Collection address
	 */
	function approveCollection(address _collection) external onlyOwner {
		approvedCollections[_collection] = true;
	}

	/**
	 * @dev Function to return a list of all current gifts
	 */
	function gifts() external view returns (Gift[] memory) {
		Gift[] memory _gifts = new Gift[](receivedGifts.length);

		for (uint256 i = 0; i < receivedGifts.length; i++) {
			_gifts[i] = receivedGifts[i];
		}

		return _gifts;
	}

	/*

		A D M I N

	*/

	/**
	 * @dev Intended to be used when we face an issue with the regular
	 * process of receiving a gift. Only to be used as the last resort.
	 * @param _collection Collection address
	 * @param _toAddress Address of the receiver
	 * @param _tokenId Token id
	 */
	function safeTransfer(
		address _collection,
		address _toAddress,
		uint256 _tokenId
	) external onlyOwner whenPaused {
		IERC721(_collection).safeTransferFrom(address(this), _toAddress, _tokenId);
	}

	/**
	 * @dev Intended to be used when we face an issue with the regular
	 * process of receiving a gift. Only to be used as the last resort.
	 * @param _collection Collection address
	 * @param _toAddress Address of the receiver
	 * @param _tokenId Token id
	 * @param _value Token value
	 */
	function safeTransfer(
		address _collection,
		address _toAddress,
		uint256 _tokenId,
		uint256 _value
	) external onlyOwner whenPaused {
		IERC1155(_collection).safeTransferFrom(
			address(this),
			_toAddress,
			_tokenId,
			_value,
			''
		);
	}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}
}