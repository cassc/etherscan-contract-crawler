/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/interfaces/IERC1271.sol';

import './IQuote.sol';

/// @title IHashflowPool
/// @author Victor Ionescu
/**
 * Pool contract used for trading. The Pool can either hold funds or
 * rely on external accounts. External accounts are used in order to preserve
 * Capital Efficiency on the Market Maker side. This way, a Market Maker can
 * make markets using funds that are also used on other venues.
 */
interface IHashflowPool is IQuote, IERC1271 {
    /// @notice Specifies a HashflowPool on a foreign chain.
    struct AuthorizedXChainPool {
        uint16 chainId;
        bytes32 pool;
    }

    /// @notice Contains a signer verification address, and whether trading is enabled.
    struct SignerConfiguration {
        address signer;
        bool enabled;
    }

    /// @notice Emitted when the authorization status of a withdrawal account changes.
    /// @param account The account for which the status changes.
    /// @param authorized The new authorization status.
    event UpdateWithdrawalAccount(address account, bool authorized);

    /// @notice Emitted when the signer key used for the pool has changed.
    /// @param signer The new signer key.
    /// @param prevSigner The old signer key.
    event UpdateSigner(address signer, address prevSigner);

    /// @notice Emitted when liquidity is withdrawn from the pool.
    /// @param token Token being withdrawn.
    /// @param recipient Address receiving the token.
    /// @param withdrawAmount Amount being withdrawn.
    event RemoveLiquidity(
        address token,
        address recipient,
        uint256 withdrawAmount
    );

    /// @notice Emitted when an intra-chain trade happens.
    /// @param trader The trader.
    /// @param effectiveTrader The effective Trader.
    /// @param txid The txid of the quote.
    /// @param baseToken The token the trader sold.
    /// @param quoteToken The token the trader bought.
    /// @param baseTokenAmount The amount of baseToken sold.
    /// @param quoteTokenAmount The amount of quoteToken bought.
    event Trade(
        address trader,
        address effectiveTrader,
        bytes32 txid,
        address baseToken,
        address quoteToken,
        uint256 baseTokenAmount,
        uint256 quoteTokenAmount
    );

    /// @notice Emitted when a cross-chain trade happens.
    /// @param dstChainId The Hashflow Chain ID for the destination chain.
    /// @param dstPool The pool address on the destination chain.
    /// @param trader The trader address.
    /// @param txid The txid of the quote.
    /// @param baseToken The token the trader sold.
    /// @param quoteToken The token the trader bought.
    /// @param baseTokenAmount The amount of baseToken sold.
    /// @param quoteTokenAmount The amount of quoteToken bought.
    event XChainTrade(
        uint16 dstChainId,
        bytes32 dstPool,
        address trader,
        bytes32 dstTrader,
        bytes32 txid,
        address baseToken,
        bytes32 quoteToken,
        uint256 baseTokenAmount,
        uint256 quoteTokenAmount
    );

    /// @notice Emitted when a cross-chain trade is filled.
    /// @param txid The txid identified the quote that was filled.
    event XChainTradeFill(bytes32 txid);

    /// @notice Main initializer.
    /// @param name Name of the pool.
    /// @param signer Signer key used for quote / deposit verification.
    /// @param operations Operations key that governs the pool.
    /// @param router Address of the HashflowRouter contract.
    function initialize(
        string calldata name,
        address signer,
        address operations,
        address router
    ) external;

    /// @notice Returns the pool name.
    function name() external view returns (string memory);

    /// @notice Returns the signer address and whether the pool is enabled.
    function signerConfiguration() external view returns (address, bool);

    /// @notice Returns the Operations address of this pool.
    function operations() external view returns (address);

    /// @notice Returns the Router contract address.
    function router() external view returns (address);

    /// @notice Returns the current nonce for a trader.
    function nonces(address trader) external view returns (uint256);

    /// @notice Removes liquidity from the pool.
    /// @param token Token to withdraw.
    /// @param recipient Address to send token to.
    /// @param amount Amount to withdraw.
    function removeLiquidity(
        address token,
        address recipient,
        uint256 amount
    ) external;

    /// @notice Execute an RFQ-T trade.
    /// @param quote The quote to be executed.
    function tradeRFQT(RFQTQuote memory quote) external payable;

    /// @notice Execute an RFQ-M trade.
    /// @param quote The quote to be executed.
    function tradeRFQM(RFQMQuote memory quote) external;

    /// @notice Execute a cross-chain RFQ-T trade.
    /// @param quote The quote to be executed.
    /// @param trader The account that sends baseToken on this chain.
    function tradeXChainRFQT(XChainRFQTQuote memory quote, address trader)
        external
        payable;

    /// @notice Execute a cross-chain RFQ-M trade.
    /// @param quote The quote to be executed.
    function tradeXChainRFQM(XChainRFQMQuote memory quote) external;

    /// @notice Changes authorization for a set of pools to send X-Chain messages.
    /// @param pools The pools to change authorization status for.
    /// @param authorized The new authorization status.
    function updateXChainPoolAuthorization(
        AuthorizedXChainPool[] calldata pools,
        bool authorized
    ) external;

    /// @notice Changes authorization for an X-Chain Messenger app.
    /// @param xChainMessenger The address of the Messenger app.
    /// @param authorized The new authorization status.
    function updateXChainMessengerAuthorization(
        address xChainMessenger,
        bool authorized
    ) external;

    /// @notice Fills an x-chain order that completed on the source chain.
    /// @param externalAccount The external account to fill from, if any.
    /// @param txid The txid of the quote.
    /// @param trader The trader to receive the funds.
    /// @param quoteToken The token to be sent.
    /// @param quoteTokenAmount The amount of quoteToken to be sent.
    function fillXChain(
        address externalAccount,
        bytes32 txid,
        address trader,
        address quoteToken,
        uint256 quoteTokenAmount
    ) external;

    /// @notice Updates withdrawal account authorization.
    /// @param withdrawalAccounts the accounts for which to update authorization status.
    /// @param authorized The new authorization status.
    function updateWithdrawalAccount(
        address[] memory withdrawalAccounts,
        bool authorized
    ) external;

    /// @notice Updates the signer key.
    /// @param signer The new signer key.
    function updateSigner(address signer) external;

    /// @notice Used by the router to disable pool actions (Trade, Withdraw, Deposit)
    function killswitchOperations(bool enabled) external;

    /// @notice Returns the token reserves for this pool.
    /// @param token The token to check reserves for.
    function getReserves(address token) external view returns (uint256);

    /// @notice Approves a token for spend. Used for 1inch RFQ protocol.
    /// @param token The address of the ERC-20 token.
    /// @param spender The spender address (typically the 1inch RFQ order router)
    /// @param amount The approval amount.
    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) external;

    /// @notice Increases allowance for a token. Used for 1inch RFQ protocol.
    /// @param token The address of the ERC-20 token.
    /// @param spender The spender address (typically the 1inch RFQ order router).
    /// @param amount The approval amount.
    function increaseTokenAllowance(
        address token,
        address spender,
        uint256 amount
    ) external;

    /// @notice Decreases allowance for a token. Used for 1inch RFQ protocol.
    /// @param token The address of the ERC-20 token.
    /// @param spender The spender address (typically the 1inch RFQ order router)
    /// @param amount The approval amount.
    function decreaseTokenAllowance(
        address token,
        address spender,
        uint256 amount
    ) external;
}