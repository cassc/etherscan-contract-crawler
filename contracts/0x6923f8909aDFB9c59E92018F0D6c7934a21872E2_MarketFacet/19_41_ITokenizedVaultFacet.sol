// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenizedVaultFacet {
    /**
     * @notice Gets balance of an account within platform
     * @dev Internal balance for given account
     * @param tokenId Internal ID of the asset
     * @return current balance
     */
    function internalBalanceOf(bytes32 accountId, bytes32 tokenId) external view returns (uint256);

    /**
     * @notice Current supply for the asset
     * @dev Total supply of platform asset
     * @param tokenId Internal ID of the asset
     * @return current balance
     */
    function internalTokenSupply(bytes32 tokenId) external view returns (uint256);

    /**
     * @notice Internal transfer of `amount` tokens
     * @dev Transfer tokens internally
     * @param to token receiver
     * @param tokenId Internal ID of the token
     */
    function internalTransferFromEntity(
        bytes32 to,
        bytes32 tokenId,
        uint256 amount
    ) external;

    /**
     * @notice Internal transfer of `amount` tokens `from` -> `to`
     * @dev Transfer tokens internally between two IDs
     * @param from token sender
     * @param to token receiver
     * @param tokenId Internal ID of the token
     */
    function wrapperInternalTransferFrom(
        bytes32 from,
        bytes32 to,
        bytes32 tokenId,
        uint256 amount
    ) external;

    function internalBurn(
        bytes32 from,
        bytes32 tokenId,
        uint256 amount
    ) external;

    /**
     * @notice Get withdrawable dividend amount
     * @dev Divident available for an entity to withdraw
     * @param _entityId Unique ID of the entity
     * @param _tokenId Unique ID of token
     * @param _dividendTokenId Unique ID of dividend token
     * @return _entityPayout accumulated dividend
     */
    function getWithdrawableDividend(
        bytes32 _entityId,
        bytes32 _tokenId,
        bytes32 _dividendTokenId
    ) external view returns (uint256 _entityPayout);

    /**
     * @notice Withdraw available dividend
     * @dev Transfer dividends to the entity
     * @param ownerId Unique ID of the dividend receiver
     * @param tokenId Unique ID of token
     * @param dividendTokenId Unique ID of dividend token
     */
    function withdrawDividend(
        bytes32 ownerId,
        bytes32 tokenId,
        bytes32 dividendTokenId
    ) external;

    /**
     * @notice Withdraws a user's available dividends.
     * @dev Dividends can be available in more than one dividend denomination. This method will withdraw all available dividends in the different dividend denominations.
     * @param ownerId Unique ID of the dividend receiver
     * @param tokenId Unique ID of token
     */
    function withdrawAllDividends(bytes32 ownerId, bytes32 tokenId) external;

    /**
     * @notice Pay `amount` of dividends
     * @dev Transfer dividends to the entity
     * @param guid Globally unique identifier of a dividend distribution.
     * @param amount the mamount of the dividend token to be distributed to NAYMS token holders.
     */
    function payDividendFromEntity(bytes32 guid, uint256 amount) external;

    /**
     * @notice Get the amount of tokens that an entity has for sale in the marketplace.
     * @param _entityId  Unique platform ID of the entity.
     * @param _tokenId The ID assigned to an external token.
     * @return amount of tokens that the entity has for sale in the marketplace.
     */
    function getLockedBalance(bytes32 _entityId, bytes32 _tokenId) external view returns (uint256 amount);
}