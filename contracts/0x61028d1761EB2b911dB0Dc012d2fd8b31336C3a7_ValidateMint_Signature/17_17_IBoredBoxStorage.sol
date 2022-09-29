// SPDX-License-Identifier: MIT
// vim: textwidth=119
pragma solidity 0.8.11;

/* Variable getters */
interface IBoredBoxStorage {
    function current_box() external view returns (uint256);

    function coordinator() external view returns (address);

    function all_paused() external view returns (bool);

    /// Get paused state for given `boxId`
    function box__is_paused(uint256) external view returns (bool);

    /// Get latest URI root/hash for given `boxId`
    function box__uri_root(uint256) external view returns (string memory);

    /// Get first token ID allowed to be minted for given `boxId`
    function box__lower_bound(uint256) external view returns (uint256);

    /// Get last token ID allowed to be minted for given `boxId`
    function box__upper_bound(uint256) external view returns (uint256);

    /// Get remaining quantity of tokens for given `boxId`
    function box__quantity(uint256) external view returns (uint256);

    /// Get price for given `boxId`
    function box__price(uint256) external view returns (uint256);

    /// Get address to Validate contract for given `boxId` and array index
    function box__validators(uint256, uint256) external view returns (address);

    /// Get `block.timestamp` given `boxId` generation allows tokens to be sold
    function box__sale_time(uint256) external view returns (uint256);

    /// Get `block.timestamp` given `boxId` generation allows tokens to be opened
    function box__open_time(uint256) external view returns (uint256);

    /// Get amount of time added to `block.timestamp` for `boxId` when token is opened
    function box__cool_down(uint256) external view returns (uint256);

    /// Get token ID for given hash of auth
    function hash__auth_token(bytes32) external view returns (uint256);

    /// Get `block.timestamp` a given `tokenId` was opened
    function token__opened_timestamp(uint256) external view returns (uint256);

    /// Get _TokenStatus_ value for given `tokenId`
    function token__status(uint256) external view returns (uint256);

    /// Get `boxId` for given `tokenId`
    function token__generation(uint256) external view returns (uint256);

    /// Get `tokenId` for given `boxId` and owner
    function token__original_owner(uint256, address) external view returns (uint256);
}