// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMintableERC721 {
	/**
	 * @notice Checks if specified token exists
	 *
	 * @dev Returns whether the specified token ID has an ownership
	 *      information associated with it
	 *
	 * @param _tokenId ID of the token to query existence for
	 * @return whether the token exists (true - exists, false - doesn't exist)
	 */
	function exists(uint256 _tokenId) external view returns(bool);

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function mint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMintBatch` instead of `mintBatch`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint tokens to
	 * @param _tokenId ID of the first token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function mintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function safeMint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMint(address _to, uint256 _tokenId, bytes memory _data) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n, bytes memory _data) external;
}