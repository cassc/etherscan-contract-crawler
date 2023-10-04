// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DataTypesPeerToPeer} from "../DataTypesPeerToPeer.sol";

interface IQuoteHandler {
    event OnChainQuoteAdded(
        address indexed lenderVault,
        DataTypesPeerToPeer.OnChainQuote onChainQuote,
        bytes32 indexed onChainQuoteHash
    );

    event OnChainQuoteDeleted(
        address indexed lenderVault,
        bytes32 indexed onChainQuoteHash
    );

    event OnChainQuoteInvalidated(
        address indexed lenderVault,
        bytes32 indexed onChainQuoteHash
    );
    event OffChainQuoteNonceIncremented(
        address indexed lenderVault,
        uint256 newNonce
    );
    event OffChainQuoteInvalidated(
        address indexed lenderVault,
        bytes32 indexed offChainQuoteHash
    );
    event OnChainQuoteUsed(
        address indexed lenderVault,
        bytes32 indexed onChainQuoteHash,
        uint256 indexed toBeRegisteredLoanId,
        uint256 quoteTupleIdx
    );
    event OffChainQuoteUsed(
        address indexed lenderVault,
        bytes32 indexed offChainQuoteHash,
        uint256 indexed toBeRegisteredLoanId,
        DataTypesPeerToPeer.QuoteTuple quoteTuple
    );
    event QuotePolicyManagerUpdated(
        address indexed lenderVault,
        address indexed newPolicyManagerAddress
    );
    event OnChainQuotePublished(
        DataTypesPeerToPeer.OnChainQuote onChainQuote,
        bytes32 indexed onChainQuoteHash,
        address indexed proposer
    );
    event OnChainQuoteCopied(
        address indexed lenderVault,
        bytes32 indexed onChainQuoteHash
    );

    /**
     * @notice function adds on chain quote
     * @dev function can only be called by vault owner or on chain quote delegate
     * @param lenderVault address of the vault adding quote
     * @param onChainQuote data for the onChain quote (See notes in DataTypesPeerToPeer.sol)
     */
    function addOnChainQuote(
        address lenderVault,
        DataTypesPeerToPeer.OnChainQuote calldata onChainQuote
    ) external;

    /**
     * @notice function updates on chain quote
     * @dev function can only be called by vault owner or on chain quote delegate
     * @param lenderVault address of the vault updating quote
     * @param oldOnChainQuoteHash quote hash for the old onChain quote marked for deletion
     * @param newOnChainQuote data for the new onChain quote (See notes in DataTypesPeerToPeer.sol)
     */
    function updateOnChainQuote(
        address lenderVault,
        bytes32 oldOnChainQuoteHash,
        DataTypesPeerToPeer.OnChainQuote calldata newOnChainQuote
    ) external;

    /**
     * @notice function deletes on chain quote
     * @dev function can only be called by vault owner or on chain quote delegate
     * @param lenderVault address of the vault deleting
     * @param onChainQuoteHash quote hash for the onChain quote marked for deletion
     */
    function deleteOnChainQuote(
        address lenderVault,
        bytes32 onChainQuoteHash
    ) external;

    /**
     * @notice function to copy a published on chain quote
     * @dev function can only be called by vault owner or on chain quote delegate
     * @param lenderVault address of the vault approving
     * @param onChainQuoteHash quote hash of a published onChain quote
     */
    function copyPublishedOnChainQuote(
        address lenderVault,
        bytes32 onChainQuoteHash
    ) external;

    /**
     * @notice function to publish an on chain quote
     * @dev function can be called by anyone and used by any vault
     * @param onChainQuote data for the onChain quote (See notes in DataTypesPeerToPeer.sol)
     */
    function publishOnChainQuote(
        DataTypesPeerToPeer.OnChainQuote calldata onChainQuote
    ) external;

    /**
     * @notice function increments the nonce for a vault
     * @dev function can only be called by vault owner
     * incrementing the nonce can bulk invalidate any
     * off chain quotes with that nonce in one txn
     * @param lenderVault address of the vault
     */
    function incrementOffChainQuoteNonce(address lenderVault) external;

    /**
     * @notice function invalidates off chain quote
     * @dev function can only be called by vault owner
     * this function invalidates one specific quote
     * @param lenderVault address of the vault
     * @param offChainQuoteHash hash of the off chain quote to be invalidated
     */
    function invalidateOffChainQuote(
        address lenderVault,
        bytes32 offChainQuoteHash
    ) external;

    /**
     * @notice function performs checks on quote and, if valid, updates quotehandler's state
     * @dev function can only be called by borrowerGateway
     * @param borrower address of borrower
     * @param lenderVault address of the vault
     * @param quoteTupleIdx index of the quote tuple in the vault's quote array
     * @param onChainQuote data for the onChain quote (See notes in DataTypesPeerToPeer.sol)
     */
    function checkAndRegisterOnChainQuote(
        address borrower,
        address lenderVault,
        uint256 quoteTupleIdx,
        DataTypesPeerToPeer.OnChainQuote memory onChainQuote
    ) external;

    /**
     * @notice function performs checks on quote and, if valid, updates quotehandler's state
     * @dev function can only be called by borrowerGateway
     * @param borrower address of borrower
     * @param lenderVault address of the vault
     * @param offChainQuote data for the offChain quote (See notes in DataTypesPeerToPeer.sol)
     * @param quoteTuple quote data (see notes in DataTypesPeerToPeer.sol)
     * @param proof array of bytes needed to verify merkle proof
     */
    function checkAndRegisterOffChainQuote(
        address borrower,
        address lenderVault,
        DataTypesPeerToPeer.OffChainQuote calldata offChainQuote,
        DataTypesPeerToPeer.QuoteTuple calldata quoteTuple,
        bytes32[] memory proof
    ) external;

    /**
     * @notice function to update the quote policy manager for a vault
     * @param lenderVault address for which quote policy manager is being updated
     * @param newPolicyManagerAddress address of new quote policy manager
     * @dev function can only be called by vault owner
     */
    function updateQuotePolicyManagerForVault(
        address lenderVault,
        address newPolicyManagerAddress
    ) external;

    /**
     * @notice function to return address of registry
     * @return registry address
     */
    function addressRegistry() external view returns (address);

    /**
     * @notice function to return the current nonce for offchain quotes
     * @param lender address for which nonce is being retrieved
     * @return current value of nonce
     */
    function offChainQuoteNonce(address lender) external view returns (uint256);

    /**
     * @notice function returns if offchain quote hash is invalidated
     * @param lenderVault address of vault
     * @param hashToCheck hash of the offchain quote
     * @return true if invalidated, else false
     */
    function offChainQuoteIsInvalidated(
        address lenderVault,
        bytes32 hashToCheck
    ) external view returns (bool);

    /**
     * @notice function returns if hash is for an on chain quote
     * @param lenderVault address of vault
     * @param hashToCheck hash of the on chain quote
     * @return true if hash belongs to a valid on-chain quote, else false
     */
    function isOnChainQuote(
        address lenderVault,
        bytes32 hashToCheck
    ) external view returns (bool);

    /**
     * @notice function returns if hash belongs to a published on chain quote
     * @param hashToCheck hash of the on chain quote
     * @return true if hash belongs to a published on-chain quote, else false
     */
    function isPublishedOnChainQuote(
        bytes32 hashToCheck
    ) external view returns (bool);

    /**
     * @notice function returns valid until timestamp of the published on-chain quote
     * @param hashToCheck hash of the on chain quote
     * @return valid until timestamp of the published on-chain quote
     */
    function publishedOnChainQuoteValidUntil(
        bytes32 hashToCheck
    ) external view returns (uint256);

    /**
     * @notice function returns the address of the policy manager for a vault
     * @param lenderVault address of vault
     * @return address of quote policy manager for vault
     * @dev if policy manager address changes in registry, this function will still return the old address
     * unless and until the vault owner calls updateQuotePolicyManagerForVault
     */
    function quotePolicyManagerForVault(
        address lenderVault
    ) external view returns (address);

    /**
     * @notice function returns element of on-chain history
     * @param lenderVault address of vault
     * @return element of on-chain quote history
     */
    function getOnChainQuoteHistory(
        address lenderVault,
        uint256 idx
    ) external view returns (DataTypesPeerToPeer.OnChainQuoteInfo memory);

    /**
     * @notice function returns array of structs containing the on-chain quote hash and validUntil timestamp
     * @param lenderVault address of vault
     * @param startIdx starting index from on chain quote history array
     * @param endIdx ending index of on chain quote history array (non-inclusive)
     * @return array of quote hash and validUntil data for on-chain quote history of a vault
     */
    function getOnChainQuoteHistorySlice(
        address lenderVault,
        uint256 startIdx,
        uint256 endIdx
    ) external view returns (DataTypesPeerToPeer.OnChainQuoteInfo[] memory);

    /**
     * @notice function returns the number of on-chain quotes that were added or updated
     * @param lenderVault address of vault
     * @return number of on-chain quotes that were added or updated
     */
    function getOnChainQuoteHistoryLength(
        address lenderVault
    ) external view returns (uint256);
}