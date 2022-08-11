// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.5.17;

interface ISTokensManager {
	/*
	 * @dev The event fired when a token is minted.
	 * @param tokenId The ID of the created new staking position
	 * @param owner The address of the owner of the new staking position
	 * @param property The address of the Property as the staking destination
	 * @param amount The amount of the new staking position
	 * @param price The latest unit price of the cumulative staking reward
	 */
	event Minted(
		uint256 tokenId,
		address owner,
		address property,
		uint256 amount,
		uint256 price
	);

	/*
	 * @dev The event fired when a token is updated.
	 * @param tokenId The ID of the staking position
	 * @param amount The new staking amount
	 * @param price The latest unit price of the cumulative staking reward
	 * This value equals the 3rd return value of the Lockup.calculateCumulativeRewardPrices
	 * @param cumulativeReward The cumulative withdrawn reward amount
	 * @param pendingReward The pending withdrawal reward amount amount
	 */
	event Updated(
		uint256 tokenId,
		uint256 amount,
		uint256 price,
		uint256 cumulativeReward,
		uint256 pendingReward
	);

	/*
	 * @dev The event fired when toke uri freezed.
	 * @param tokenId The ID of the freezed token uri
	 * @param freezingUser user of freezed token uri
	 */
	event Freezed(uint256 tokenId, address freezingUser);

	/*
	 * @dev Creates the new staking position for the caller.
	 * Mint must be called from the Lockup contract.
	 * @param _owner The address of the owner of the new staking position
	 * @param _property The address of the Property as the staking destination
	 * @param _amount The amount of the new staking position
	 * @param _price The latest unit price of the cumulative staking reward
	 * @param _payload The payload for token
	 * @return uint256 The ID of the created new staking position
	 */
	function mint(
		address _owner,
		address _property,
		uint256 _amount,
		uint256 _price,
		bytes32 _payload
	) external returns (uint256);

	/*
	 * @dev Updates the existing staking position.
	 * Update must be called from the Lockup contract.
	 * @param _tokenId The ID of the staking position
	 * @param _amount The new staking amount
	 * @param _price The latest unit price of the cumulative staking reward
	 * This value equals the 3rd return value of the Lockup.calculateCumulativeRewardPrices
	 * @param _cumulativeReward The cumulative withdrawn reward amount
	 * @param _pendingReward The pending withdrawal reward amount amount
	 * @return bool On success, true will be returned
	 */
	function update(
		uint256 _tokenId,
		uint256 _amount,
		uint256 _price,
		uint256 _cumulativeReward,
		uint256 _pendingReward
	) external returns (bool);

	/*
	 * @dev set token uri information
	 * @param _tokenId The ID of the staking position
	 * @param _data set data
	 */
	function setTokenURIImage(uint256 _tokenId, string calldata _data) external;

	/*
	 * @dev set token uri descriptor
	 * @param _property property address
	 * @param _descriptor descriptor address
	 */
	function setTokenURIDescriptor(address _property, address _descriptor)
		external;

	/*
	 * @dev freeze token uri data
	 * @param _tokenId The ID of the staking position
	 */
	function freezeTokenURI(uint256 _tokenId) external;

	/*
	 * @dev Gets the existing staking position.
	 * @param _tokenId The ID of the staking position
	 * @return address The address of the Property as the staking destination
	 * @return uint256 The amount of the new staking position
	 * @return uint256 The latest unit price of the cumulative staking reward
	 * @return uint256 The cumulative withdrawn reward amount
	 * @return uint256 The pending withdrawal reward amount amount
	 */
	function positions(uint256 _tokenId)
		external
		view
		returns (
			address,
			uint256,
			uint256,
			uint256,
			uint256
		);

	/*
	 * @dev Get the freezed status.
	 * @param _tokenId The ID of the staking position
	 * @return bool If freezed, return true
	 */
	function isFreezed(uint256 _tokenId) external view returns (bool);

	/*
	 * @dev Gets the reward status of the staking position.
	 * @param _tokenId The ID of the staking position
	 * @return uint256 The reward amount of adding the cumulative withdrawn amount
	 to the withdrawable amount
	 * @return uint256 The cumulative withdrawn reward amount
	 * @return uint256 The withdrawable reward amount
	 */
	function rewards(uint256 _tokenId)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);

	/*
	 * @dev get token ids by property
	 * @param _property property address
	 * @return uint256[] token id list
	 */
	function positionsOfProperty(address _property)
		external
		view
		returns (uint256[] memory);

	/*
	 * @dev get token ids by owner
	 * @param _owner owner address
	 * @return uint256[] token id list
	 */
	function positionsOfOwner(address _owner)
		external
		view
		returns (uint256[] memory);

	/*
	 * @dev get descriptor address
	 * @param _property property address
	 * @return address descriptor address
	 */
	function descriptorOf(address _property) external view returns (address);

	/*
	 * @dev get the payload
	 * @param _tokenId token id
	 * @return bytes32 stored payload
	 */
	function payloadOf(uint256 _tokenId) external view returns (bytes32);

	/*
	 * @dev get current token id
	 * @return uint256 current token id
	 */
	function currentIndex() external view returns (uint256);
}