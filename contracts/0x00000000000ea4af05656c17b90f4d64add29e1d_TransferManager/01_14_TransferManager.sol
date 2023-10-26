// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// LooksRare unopinionated libraries
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {LowLevelERC20Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Transfer.sol";
import {LowLevelERC721Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC721Transfer.sol";
import {LowLevelERC1155Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC1155Transfer.sol";

// Interfaces and errors
import {ITransferManager} from "./interfaces/ITransferManager.sol";
import {AmountInvalid, LengthsInvalid} from "./errors/SharedErrors.sol";

// Enums
import {TokenType} from "./enums/TokenType.sol";

/**
 * @title TransferManager
 * @notice This contract provides the transfer functions for ERC20/ERC721/ERC1155 for contracts that require them.
 *         Token type "0" refers to ERC20 transfer functions.
 *         Token type "1" refers to ERC721 transfer functions.
 *         Token type "2" refers to ERC1155 transfer functions.
 * @dev "Safe" transfer functions for ERC721 are not implemented since they come with added gas costs
 *       to verify if the recipient is a contract as it requires verifying the receiver interface is valid.
 * @author LooksRare protocol team (👀,💎)
 */
contract TransferManager is
    ITransferManager,
    LowLevelERC20Transfer,
    LowLevelERC721Transfer,
    LowLevelERC1155Transfer,
    OwnableTwoSteps
{
    /**
     * @notice This returns whether the user has approved the operator address.
     * The first address is the user and the second address is the operator.
     */
    mapping(address => mapping(address => bool)) public hasUserApprovedOperator;

    /**
     * @notice This returns whether the operator address is allowed by this contract's owner.
     */
    mapping(address => bool) public isOperatorAllowed;

    /**
     * @notice Constructor
     * @param _owner Owner address
     */
    constructor(address _owner) OwnableTwoSteps(_owner) {}

    /**
     * @inheritdoc ITransferManager
     */
    function transferERC20(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) external {
        _isOperatorValidForTransfer(from, msg.sender);

        if (amount == 0) {
            revert AmountInvalid();
        }

        _executeERC20TransferFrom(tokenAddress, from, to, amount);
    }

    /**
     * @inheritdoc ITransferManager
     */
    function transferItemERC721(
        address tokenAddress,
        address from,
        address to,
        uint256 itemId
    ) external {
        _isOperatorValidForTransfer(from, msg.sender);
        _executeERC721TransferFrom(tokenAddress, from, to, itemId);
    }

    /**
     * @inheritdoc ITransferManager
     */
    function transferItemsERC721(
        address tokenAddress,
        address from,
        address to,
        uint256[] calldata itemIds,
        uint256[] calldata amounts
    ) external {
        uint256 length = itemIds.length;
        if (length == 0 || amounts.length != length) {
            revert LengthsInvalid();
        }

        _isOperatorValidForTransfer(from, msg.sender);

        for (uint256 i; i < length; ) {
            if (amounts[i] != 1) {
                revert AmountInvalid();
            }
            _executeERC721TransferFrom(tokenAddress, from, to, itemIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc ITransferManager
     */
    function transferItemERC1155(
        address tokenAddress,
        address from,
        address to,
        uint256 itemId,
        uint256 amount
    ) external {
        _isOperatorValidForTransfer(from, msg.sender);
        if (amount == 0) {
            revert AmountInvalid();
        }
        _executeERC1155SafeTransferFrom(tokenAddress, from, to, itemId, amount);
    }

    /**
     * @inheritdoc ITransferManager
     */
    function transferItemsERC1155(
        address tokenAddress,
        address from,
        address to,
        uint256[] calldata itemIds,
        uint256[] calldata amounts
    ) external {
        uint256 length = itemIds.length;

        if (length == 0 || amounts.length != length) {
            revert LengthsInvalid();
        }

        _isOperatorValidForTransfer(from, msg.sender);

        if (length == 1) {
            if (amounts[0] == 0) {
                revert AmountInvalid();
            }
            _executeERC1155SafeTransferFrom(tokenAddress, from, to, itemIds[0], amounts[0]);
        } else {
            for (uint256 i; i < length; ) {
                if (amounts[i] == 0) {
                    revert AmountInvalid();
                }

                unchecked {
                    ++i;
                }
            }
            _executeERC1155SafeBatchTransferFrom(tokenAddress, from, to, itemIds, amounts);
        }
    }

    /**
     * @inheritdoc ITransferManager
     */
    function transferBatchItemsAcrossCollections(
        BatchTransferItem[] calldata items,
        address from,
        address to
    ) external {
        uint256 itemsLength = items.length;

        if (itemsLength == 0) {
            revert LengthsInvalid();
        }

        if (from != msg.sender) {
            _isOperatorValidForTransfer(from, msg.sender);
        }

        for (uint256 i; i < itemsLength; ) {
            uint256[] calldata itemIds = items[i].itemIds;
            uint256 itemIdsLengthForSingleCollection = itemIds.length;
            uint256[] calldata amounts = items[i].amounts;

            TokenType tokenType = items[i].tokenType;

            if (tokenType == TokenType.ERC20) {
                if (itemIdsLengthForSingleCollection != 0 || amounts.length != 1) {
                    revert LengthsInvalid();
                }
            } else {
                if (itemIdsLengthForSingleCollection == 0 || amounts.length != itemIdsLengthForSingleCollection) {
                    revert LengthsInvalid();
                }
            }

            if (tokenType == TokenType.ERC20) {
                uint256 amount = amounts[0];
                if (amount == 0) {
                    revert AmountInvalid();
                }
                _executeERC20TransferFrom(items[i].tokenAddress, from, to, amount);
            } else if (tokenType == TokenType.ERC721) {
                for (uint256 j; j < itemIdsLengthForSingleCollection; ) {
                    if (amounts[j] != 1) {
                        revert AmountInvalid();
                    }
                    _executeERC721TransferFrom(items[i].tokenAddress, from, to, itemIds[j]);
                    unchecked {
                        ++j;
                    }
                }
            } else if (tokenType == TokenType.ERC1155) {
                for (uint256 j; j < itemIdsLengthForSingleCollection; ) {
                    if (amounts[j] == 0) {
                        revert AmountInvalid();
                    }

                    unchecked {
                        ++j;
                    }
                }
                _executeERC1155SafeBatchTransferFrom(items[i].tokenAddress, from, to, itemIds, amounts);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc ITransferManager
     */
    function grantApprovals(address[] calldata operators) external {
        uint256 length = operators.length;

        if (length == 0) {
            revert LengthsInvalid();
        }

        for (uint256 i; i < length; ) {
            address operator = operators[i];

            if (!isOperatorAllowed[operator]) {
                revert OperatorNotAllowed();
            }

            if (hasUserApprovedOperator[msg.sender][operator]) {
                revert OperatorAlreadyApprovedByUser();
            }

            hasUserApprovedOperator[msg.sender][operator] = true;

            unchecked {
                ++i;
            }
        }

        emit ApprovalsGranted(msg.sender, operators);
    }

    /**
     * @inheritdoc ITransferManager
     */
    function revokeApprovals(address[] calldata operators) external {
        uint256 length = operators.length;
        if (length == 0) {
            revert LengthsInvalid();
        }

        for (uint256 i; i < length; ) {
            address operator = operators[i];

            if (!hasUserApprovedOperator[msg.sender][operator]) {
                revert OperatorNotApprovedByUser();
            }

            delete hasUserApprovedOperator[msg.sender][operator];
            unchecked {
                ++i;
            }
        }

        emit ApprovalsRemoved(msg.sender, operators);
    }

    /**
     * @inheritdoc ITransferManager
     */
    function allowOperator(address operator) external onlyOwner {
        if (isOperatorAllowed[operator]) {
            revert OperatorAlreadyAllowed();
        }

        isOperatorAllowed[operator] = true;

        emit OperatorAllowed(operator);
    }

    /**
     * @inheritdoc ITransferManager
     */
    function removeOperator(address operator) external onlyOwner {
        if (!isOperatorAllowed[operator]) {
            revert OperatorNotAllowed();
        }

        delete isOperatorAllowed[operator];

        emit OperatorRemoved(operator);
    }

    /**
     * @notice This function is internal and verifies whether the transfer
     *         (by an operator on behalf of a user) is valid. If not, it reverts.
     * @param user User address
     * @param operator Operator address
     */
    function _isOperatorValidForTransfer(address user, address operator) private view {
        if (isOperatorAllowed[operator] && hasUserApprovedOperator[user][operator]) {
            return;
        }

        revert TransferCallerInvalid();
    }
}