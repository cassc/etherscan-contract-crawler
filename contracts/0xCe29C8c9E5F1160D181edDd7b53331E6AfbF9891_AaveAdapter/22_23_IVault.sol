// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFlashLoanRecipient.sol";
import "./IProtocolFeesCollector.sol";
import "./IAsset.sol";

interface IVault is IFlashLoanRecipient {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    enum PoolBalanceChangeKind {
        JOIN,
        EXIT
    }

    enum PoolBalanceOpKind {
        WITHDRAW,
        DEPOSIT,
        UPDATE
    }

    enum UserBalanceOpKind {
        DEPOSIT_INTERNAL,
        WITHDRAW_INTERNAL,
        TRANSFER_INTERNAL,
        TRANSFER_EXTERNAL
    }

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    function WETH() external view returns (address);

    function batchSwap(
        uint8 kind,
        BatchSwapStep[] calldata swaps,
        address[] calldata assets,
        FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline
    ) external returns (int256[] memory assetDeltas);

    function deregisterTokens(bytes32 poolId, address[] calldata tokens)
        external;

    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest calldata request
    ) external;

    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    function getActionId(bytes4 selector) external view returns (bytes32);

    function getAuthorizer() external view returns (address);

    function getDomainSeparator() external view returns (bytes32);

    function getInternalBalance(address user, address[] calldata tokens)
        external
        view
        returns (uint256[] memory balances);

    function getNextNonce(address user) external view returns (uint256);

    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );

    function getPool(bytes32 poolId) external view returns (address, uint8);

    function getPoolTokenInfo(bytes32 poolId, address token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function getProtocolFeesCollector() external view returns (address);

    function hasApprovedRelayer(address user, address relayer)
        external
        view
        returns (bool);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest calldata request
    ) external;

    function managePoolBalance(PoolBalanceOp[] calldata ops) external;

    function manageUserBalance(UserBalanceOp[] calldata ops) external;

    function queryBatchSwap(
        uint8 kind,
        BatchSwapStep[] calldata swaps,
        address[] calldata assets,
        FundManagement calldata funds
    ) external returns (int256[] memory);

    function registerPool(uint8 specialization) external returns (bytes32);

    function registerTokens(
        bytes32 poolId,
        address[] calldata tokens,
        address[] calldata assetManagers
    ) external;

    function setAuthorizer(address newAuthorizer) external;

    function setPaused(bool paused) external;

    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    function swap(
        SingleSwap calldata singleSwap,
        FundManagement calldata funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256 amountCalculated);
}