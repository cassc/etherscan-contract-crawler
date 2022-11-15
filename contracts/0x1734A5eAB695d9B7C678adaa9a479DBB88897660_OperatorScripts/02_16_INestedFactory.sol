// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../NestedReserve.sol";
import "../FeeSplitter.sol";

/// @title NestedFactory interface
interface INestedFactory {
    /* ------------------------------ EVENTS ------------------------------ */

    /// @dev Emitted when the feeSplitter is updated
    /// @param feeSplitter The new feeSplitter address
    event FeeSplitterUpdated(address feeSplitter);

    /// @dev Emitted when the entryFees is updated
    /// @param entryFees The new entryFees amount
    event EntryFeesUpdated(uint256 entryFees);

    /// @dev Emitted when the exitFees is updated
    /// @param exitFees The new exitFees amount
    event ExitFeesUpdated(uint256 exitFees);

    /// @dev Emitted when the reserve is updated
    /// @param reserve The new reserve address
    event ReserveUpdated(address reserve);

    /// @dev Emitted when a NFT (portfolio) is created
    /// @param nftId The NFT token Id
    /// @param originalNftId If replicated, the original NFT token Id
    event NftCreated(uint256 indexed nftId, uint256 originalNftId);

    /// @dev Emitted when a NFT (portfolio) is updated
    /// @param nftId The NFT token Id
    event NftUpdated(uint256 indexed nftId);

    /// @dev Emitted when a new operator is added
    /// @param newOperator The new operator bytes name
    event OperatorAdded(bytes32 newOperator);

    /// @dev Emitted when an operator is removed
    /// @param oldOperator The old operator bytes name
    event OperatorRemoved(bytes32 oldOperator);

    /// @dev Emitted when tokens are unlocked (sent to the owner)
    /// @param token The unlocked token address
    /// @param amount The unlocked amount
    event TokensUnlocked(address token, uint256 amount);

    /* ------------------------------ STRUCTS ------------------------------ */

    /// @dev Represent an order made to the factory when creating/editing an NFT
    /// @param operator The bytes32 name of the Operator
    /// @param token The expected token address in output/input
    /// @param callData The operator parameters (delegatecall)
    struct Order {
        bytes32 operator;
        address token;
        bytes callData;
    }

    /// @dev Represent multiple input orders for a given token to perform multiple trades.
    /// @param inputToken The input token
    /// @param amount The amount to transfer (input amount)
    /// @param orders The orders to perform using the input token.
    /// @param _fromReserve Specify the input token source (true if reserve, false if wallet)
    ///        Note: fromReserve can be read as "from portfolio"
    struct BatchedInputOrders {
        IERC20 inputToken;
        uint256 amount;
        Order[] orders;
        bool fromReserve;
    }

    /// @dev Represent multiple output orders to receive a given token
    /// @param outputToken The output token
    /// @param amounts The amount of sell tokens to use
    /// @param orders Orders calldata
    /// @param toReserve Specify the output token destination (true if reserve, false if wallet)
    ///        Note: toReserve can be read as "to portfolio"
    struct BatchedOutputOrders {
        IERC20 outputToken;
        uint256[] amounts;
        Order[] orders;
        bool toReserve;
    }

    /* ------------------------------ OWNER FUNCTIONS ------------------------------ */

    /// @notice Add an operator (name) for building cache
    /// @param operator The operator name to add
    function addOperator(bytes32 operator) external;

    /// @notice Remove an operator (name) for building cache
    /// @param operator The operator name to remove
    function removeOperator(bytes32 operator) external;

    /// @notice Sets the address receiving the fees
    /// @param _feeSplitter The address of the receiver
    function setFeeSplitter(FeeSplitter _feeSplitter) external;

    /// @notice Sets the entry fees amount
    ///         Where 1 = 0.01% and 10000 = 100%
    /// @param _entryFees Entry fees amount
    function setEntryFees(uint256 _entryFees) external;

    /// @notice Sets the exit fees amount
    ///         Where 1 = 0.01% and 10000 = 100%
    /// @param _exitFees Exit fees amount
    function setExitFees(uint256 _exitFees) external;

    /// @notice The Factory is not storing funds, but some users can make
    /// bad manipulations and send tokens to the contract.
    /// In response to that, the owner can retrieve the factory balance of a given token
    /// to later return users funds.
    /// @param _token The token to retrieve.
    function unlockTokens(IERC20 _token) external;

    /* ------------------------------ USERS FUNCTIONS ------------------------------ */

    /// @notice Create a portfolio and store the underlying assets from the positions
    /// @param _originalTokenId The id of the NFT replicated, 0 if not replicating
    /// @param _batchedOrders The order to execute
    function create(uint256 _originalTokenId, BatchedInputOrders[] calldata _batchedOrders) external payable;

    /// @notice Process multiple input orders
    /// @param _nftId The id of the NFT to update
    /// @param _batchedOrders The order to execute
    function processInputOrders(uint256 _nftId, BatchedInputOrders[] calldata _batchedOrders) external payable;

    /// @notice Process multiple output orders
    /// @param _nftId The id of the NFT to update
    /// @param _batchedOrders The order to execute
    function processOutputOrders(uint256 _nftId, BatchedOutputOrders[] calldata _batchedOrders) external;

    /// @notice Process multiple input orders and then multiple output orders
    /// @param _nftId The id of the NFT to update
    /// @param _batchedInputOrders The input orders to execute (first)
    /// @param _batchedOutputOrders The output orders to execute (after)
    function processInputAndOutputOrders(
        uint256 _nftId,
        BatchedInputOrders[] calldata _batchedInputOrders,
        BatchedOutputOrders[] calldata _batchedOutputOrders
    ) external payable;

    /// @notice Burn NFT and exchange all tokens for a specific ERC20 then send it back to the user
    /// @dev Will unwrap WETH output to ETH
    /// @param _nftId The id of the NFT to destroy
    /// @param _buyToken The output token
    /// @param _orders Orders calldata
    function destroy(
        uint256 _nftId,
        IERC20 _buyToken,
        Order[] calldata _orders
    ) external;

    /// @notice Withdraw a token from the reserve and transfer it to the owner without exchanging it
    /// @param _nftId NFT token ID
    /// @param _tokenIndex Index in array of tokens for this NFT and holding.
    function withdraw(uint256 _nftId, uint256 _tokenIndex) external;

    /// @notice Update the lock timestamp of an NFT record.
    /// Note: Can only increase the lock timestamp.
    /// @param _nftId The NFT id to get the record
    /// @param _timestamp The new timestamp.
    function updateLockTimestamp(uint256 _nftId, uint256 _timestamp) external;
}