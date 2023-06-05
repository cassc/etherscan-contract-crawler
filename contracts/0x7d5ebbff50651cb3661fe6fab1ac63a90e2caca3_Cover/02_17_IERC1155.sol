// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "./IERC165.sol";

/**
* @title ERC-1155 Multi Token Standard
* @dev See https://eips.ethereum.org/EIPS/eip-1155
* Note: The ERC-165 identifier for this interface is 0xd9b67a26.
*/
interface IERC1155 /* is IERC165 */ {
  /**
  * @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is
  *   enabled or disabled (absence of an event assumes disabled).
  * 
  * @param owner address that owns the tokens
  * @param operator address allowed or not to manage the tokens
  * @param approved whether the operator is allowed
  */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  /**
  * @dev MUST emit when the URI is updated for a token ID.
  * URIs are defined in RFC 3986.
  * The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
  * 
  * @param value the new uri
  * @param id the token id involved
  */
  event URI(string value, uint256 indexed id);
  /**
  * @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred,
  *   including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
  * 
  * The `operator` argument MUST be the address of an account/contract
  *   that is approved to make the transfer (SHOULD be msg.sender).
  * The `from` argument MUST be the address of the holder whose balance is decreased.
  * The `to` argument MUST be the address of the recipient whose balance is increased.
  * The `ids` argument MUST be the list of tokens being transferred.
  * The `values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in ids)
  *   the holder balance is decreased by and match what the recipient balance is increased by.
  * When minting/creating tokens, the `from` argument MUST be set to `0x0` (i.e. zero address).
  * When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).
  * 
  * @param operator address ordering the transfer
  * @param from address tokens are being transferred from
  * @param to address tokens are being transferred to
  * @param ids identifiers of the tokens being transferred
  * @param values amounts of tokens being transferred
  */
  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );
  /**
  * @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred,
  *   including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
  * 
  * The `operator` argument MUST be the address of an account/contract
  *   that is approved to make the transfer (SHOULD be msg.sender).
  * The `from` argument MUST be the address of the holder whose balance is decreased.
  * The `to` argument MUST be the address of the recipient whose balance is increased.
  * The `id` argument MUST be the token type being transferred.
  * The `value` argument MUST be the number of tokens the holder balance is decreased by
  *   and match what the recipient balance is increased by.
  * When minting/creating tokens, the `from` argument MUST be set to `0x0` (i.e. zero address).
  * When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).
  * 
  * @param operator address ordering the transfer
  * @param from address tokens are being transferred from
  * @param to address tokens are being transferred to
  * @param id identifier of the token being transferred
  * @param value amount of token being transferred
  */
  event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

  /**
  * @notice Transfers `values_` amount(s) of `ids_` from the `from_` address to the `to_` address specified
  *   (with safety call).
  * 
  * @dev Caller must be approved to manage the tokens being transferred out of the `from_` account
  *   (see "Approval" section of the standard).
  * 
  * MUST revert if `to_` is the zero address.
  * MUST revert if length of `ids_` is not the same as length of `values_`.
  * MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids_` is lower than the respective amount(s)
  *   in `values_` sent to the recipient.
  * MUST revert on any other error.        
  * MUST emit {TransferSingle} or {TransferBatch} event(s) such that all the balance changes are reflected
  *   (see "Safe Transfer Rules" section of the standard).
  * Balance changes and events MUST follow the ordering of the arrays
  *   (ids_[0]/values_[0] before ids_[1]/values_[1], etc).
  * After the above conditions for the transfer(s) in the batch are met,
  *   this function MUST check if `to_` is a smart contract (e.g. code size > 0).
  *   If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to_`
  *   and act appropriately (see "Safe Transfer Rules" section of the standard).
  */
  function safeBatchTransferFrom(
    address from_,
    address to_,
    uint256[] calldata ids_,
    uint256[] calldata values_,
    bytes calldata data_
  ) external;
  /**
  * @notice Transfers `value_` amount of an `id_` from the `from_` address to the `to_` address specified
  *   (with safety call).
  * 
  * @dev Caller must be approved to manage the tokens being transferred out of the `from_` account
  *   (see "Approval" section of the standard).
  * 
  * MUST revert if `to_` is the zero address.
  * MUST revert if balance of holder for token `id_` is lower than the `value_` sent.
  * MUST revert on any other error.
  * MUST emit the {TransferSingle} event to reflect the balance change
  *   (see "Safe Transfer Rules" section of the standard).
  * After the above conditions are met, this function MUST check if `to_` is a smart contract (e.g. code size > 0).
  *   If so, it MUST call `onERC1155Received` on `to_` and act appropriately
  *   (see "Safe Transfer Rules" section of the standard).
  */
  function safeTransferFrom(address from_, address to_, uint256 id_, uint256 value_, bytes calldata data_) external;
  /**
  * @notice Enable or disable approval for `operator_` to manage all of the caller's tokens.
  * 
  * @dev MUST emit the {ApprovalForAll} event on success.
  */
  function setApprovalForAll(address operator_, bool approved_) external;

  /**
  * @notice Returns the balance of `owner_`'s tokens of type `id_`.
  */
  function balanceOf(address owner_, uint256 id_) external view returns (uint256);
  /**
  * @notice Returns the balance of multiple account/token pairs.
  */
  function balanceOfBatch(address[] calldata owners_, uint256[] calldata ids_) external view returns (uint256[] memory);
  /**
  * @notice Returns the approval status of `operator_` for `owner_`.
  */
  function isApprovedForAll(address owner_, address operator_) external view returns (bool);
}