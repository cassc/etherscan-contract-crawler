// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Enums
import {TokenType} from "../enums/TokenType.sol";

/**
 * @title ITransferManager
 * @author LooksRare protocol team (👀,💎)
 */
interface ITransferManager {
    /**
     * @notice This struct is only used for transferBatchItemsAcrossCollections.
     * @param tokenAddress Token address
     * @param tokenType 0 for ERC721, 1 for ERC1155
     * @param itemIds Array of item ids to transfer
     * @param amounts Array of amounts to transfer
     */
    struct BatchTransferItem {
        address tokenAddress;
        TokenType tokenType;
        uint256[] itemIds;
        uint256[] amounts;
    }

    /**
     * @notice It is emitted if operators' approvals to transfer NFTs are granted by a user.
     * @param user Address of the user
     * @param operators Array of operator addresses
     */
    event ApprovalsGranted(address user, address[] operators);

    /**
     * @notice It is emitted if operators' approvals to transfer NFTs are revoked by a user.
     * @param user Address of the user
     * @param operators Array of operator addresses
     */
    event ApprovalsRemoved(address user, address[] operators);

    /**
     * @notice It is emitted if a new operator is added to the global allowlist.
     * @param operator Operator address
     */
    event OperatorAllowed(address operator);

    /**
     * @notice It is emitted if an operator is removed from the global allowlist.
     * @param operator Operator address
     */
    event OperatorRemoved(address operator);

    /**
     * @notice It is returned if the operator to approve has already been approved by the user.
     */
    error OperatorAlreadyApprovedByUser();

    /**
     * @notice It is returned if the operator to revoke has not been previously approved by the user.
     */
    error OperatorNotApprovedByUser();

    /**
     * @notice It is returned if the transfer caller is already allowed by the owner.
     * @dev This error can only be returned for owner operations.
     */
    error OperatorAlreadyAllowed();

    /**
     * @notice It is returned if the operator to approve is not in the global allowlist defined by the owner.
     * @dev This error can be returned if the user tries to grant approval to an operator address not in the
     *      allowlist or if the owner tries to remove the operator from the global allowlist.
     */
    error OperatorNotAllowed();

    /**
     * @notice It is returned if the transfer caller is invalid.
     *         For a transfer called to be valid, the operator must be in the global allowlist and
     *         approved by the 'from' user.
     */
    error TransferCallerInvalid();

    /**
     * @notice This function transfers ERC20 tokens.
     * @param tokenAddress Token address
     * @param from Sender address
     * @param to Recipient address
     * @param amount amount
     */
    function transferERC20(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice This function transfers a single item for a single ERC721 collection.
     * @param tokenAddress Token address
     * @param from Sender address
     * @param to Recipient address
     * @param itemId Item ID
     */
    function transferItemERC721(
        address tokenAddress,
        address from,
        address to,
        uint256 itemId
    ) external;

    /**
     * @notice This function transfers items for a single ERC721 collection.
     * @param tokenAddress Token address
     * @param from Sender address
     * @param to Recipient address
     * @param itemIds Array of itemIds
     * @param amounts Array of amounts
     */
    function transferItemsERC721(
        address tokenAddress,
        address from,
        address to,
        uint256[] calldata itemIds,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice This function transfers a single item for a single ERC1155 collection.
     * @param tokenAddress Token address
     * @param from Sender address
     * @param to Recipient address
     * @param itemId Item ID
     * @param amount Amount
     */
    function transferItemERC1155(
        address tokenAddress,
        address from,
        address to,
        uint256 itemId,
        uint256 amount
    ) external;

    /**
     * @notice This function transfers items for a single ERC1155 collection.
     * @param tokenAddress Token address
     * @param from Sender address
     * @param to Recipient address
     * @param itemIds Array of itemIds
     * @param amounts Array of amounts
     * @dev It does not allow batch transferring if from = msg.sender since native function should be used.
     */
    function transferItemsERC1155(
        address tokenAddress,
        address from,
        address to,
        uint256[] calldata itemIds,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice This function transfers items across an array of tokens that can be ERC20, ERC721 and ERC1155.
     * @param items Array of BatchTransferItem
     * @param from Sender address
     * @param to Recipient address
     */
    function transferBatchItemsAcrossCollections(
        BatchTransferItem[] calldata items,
        address from,
        address to
    ) external;

    /**
     * @notice This function allows a user to grant approvals for an array of operators.
     *         Users cannot grant approvals if the operator is not allowed by this contract's owner.
     * @param operators Array of operator addresses
     * @dev Each operator address must be globally allowed to be approved.
     */
    function grantApprovals(address[] calldata operators) external;

    /**
     * @notice This function allows a user to revoke existing approvals for an array of operators.
     * @param operators Array of operator addresses
     * @dev Each operator address must be approved at the user level to be revoked.
     */
    function revokeApprovals(address[] calldata operators) external;

    /**
     * @notice This function allows an operator to be added for the shared transfer system.
     *         Once the operator is allowed, users can grant NFT approvals to this operator.
     * @param operator Operator address to allow
     * @dev Only callable by owner.
     */
    function allowOperator(address operator) external;

    /**
     * @notice This function allows the user to remove an operator for the shared transfer system.
     * @param operator Operator address to remove
     * @dev Only callable by owner.
     */
    function removeOperator(address operator) external;
}