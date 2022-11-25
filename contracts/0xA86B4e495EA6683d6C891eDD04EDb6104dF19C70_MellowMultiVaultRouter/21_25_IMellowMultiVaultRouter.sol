// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/IWETH.sol";
import "../interfaces/IERC20RootVault.sol";

interface IMellowMultiVaultRouter {
    struct BatchedDeposit {
        address author;
        uint256 amount;
    }

    struct BatchedDeposits {
        mapping(uint256 => BatchedDeposit) batch;
        uint256 current;
        uint256 size;
    }

    // -------------------  INITIALIZER -------------------

    /// @notice Constructor for Proxies
    function initialize(
        IWETH weth_,
        IERC20Minimal token_,
        IERC20RootVault[] memory vaults_
    ) external;

    // -------------------  GETTERS -------------------

    /// @notice The official WETH of the network
    function weth() external view returns (IWETH);

    /// @notice The underlying token of the vaults
    function token() external view returns (IERC20Minimal);

    /// @notice Active batched deposits
    function getBatchedDeposits(uint256 index)
        external
        view
        returns (BatchedDeposit[] memory);

    /// @notice Get the LP token balances
    function getLPTokenBalances(address owner)
        external
        view
        returns (uint256[] memory);

    /// @notice All vaults assigned to this router
    function getVaults() external view returns (IERC20RootVault[] memory);

    /// @notice Checks if the vault is deprecated
    function isVaultDeprecated(uint256 index) external view returns(bool);

    // -------------------  CHECKS  -------------------

    function validWeights(uint256[] memory weights)
        external
        view
        returns (bool);

    // -------------------  SETTERS  -------------------

    /// @notice Add another vault to the router
    /// @param vault_ The new vault
    function addVault(IERC20RootVault vault_) external;

    /// @notice Deprecate vault
    /// @param index The index of the vault to be deprecated
    function deprecateVault(uint256 index) external;

    /// @notice Reactivate vault
    /// @param index The index of the vault to be deprecated
    function reactivateVault(uint256 index) external;

    // -------------------  DEPOSITS  -------------------

    /// @notice Deposit ETH to the router
    function depositEth(uint256[] memory weights) external payable;

    /// @notice Deposit ERC20 to the router
    function depositErc20(uint256 amount, uint256[] memory weights) external;

    // -------------------  BATCH PUSH  -------------------

    /// @notice Push the batched funds to Mellow
    function submitBatch(uint256 index, uint256 batchSize) external;

    // -------------------  WITHDRAWALS  -------------------

    /// @notice Burn the lp tokens and withdraw the funds
    function claimLPTokens(
        uint256 index,
        uint256[] memory minTokenAmounts,
        bytes[] memory vaultsOptions
    ) external;

    /// @notice Burn the lp tokens and rollover the funds according to the weights
    function rolloverLPTokens(
        uint256 index,
        uint256[] memory minTokenAmounts,
        bytes[] memory vaultsOptions,
        uint256[] memory weights
    ) external;
}