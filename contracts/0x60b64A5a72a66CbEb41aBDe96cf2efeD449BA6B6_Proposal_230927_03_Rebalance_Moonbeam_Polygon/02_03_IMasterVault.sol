pragma solidity ^0.8.20;

interface IMasterVault {
    event ActionCompleted();
    event ActionQueued(uint256 amountIn, uint8 actionType);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Deposit(
        address indexed who,
        address indexed receiver,
        address indexed asset,
        uint256 numberOfAssets,
        uint256 numberOfShares,
        uint256 pricePerToken,
        uint256 opId
    );
    event OperationCompleted(uint256 opId);
    event OperationQueued(uint256 opId);
    event OperationStarted(uint256 opId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ScoringUpdated(uint256 chainId, uint256 score);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdrawal(
        address indexed who,
        address indexed receiver,
        address indexed asset,
        uint256 numberOfAssets,
        uint256 numberOfShares,
        uint256 pricePerToken,
        uint256 opId
    );

    struct RootVaultAction {
        uint8 actionType;
        uint8 slippage;
        uint256 amountIn;
        uint256 amountOut;
    }

    struct CallData {
        address to;
        bytes data;
        uint256 value;
    }

    function addChain(uint256 chainId, uint16 lzChainId, address remoteVaultAddress) external;
    function addToken(address token) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function assetConverter() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function bridgeAdapterToChainId(address) external view returns (uint256);
    function bridgeAdapters(uint256) external view returns (address);
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function call(CallData[] memory calls) external;
    function canNewOperationBeProcessedInstantly() external view returns (bool);
    function chainIdToLzChainId(uint256) external view returns (uint16);
    function currentAction() external view returns (RootVaultAction memory);
    function decimals() external view returns (uint8);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function deposit(address asset, uint256 value, address beneficiary, uint8 slippage) external;
    function dropCurrentAction(bool finalize) external;
    function dropCurrentOperation() external;
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function isActionInProgress() external view returns (bool);
    function isQueueBusy() external view returns (bool);
    function isQueueEmpty() external view returns (bool);
    function isTransferExpected(bytes32) external view returns (bool);
    function lzEndpoint() external view returns (address);
    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) external;
    function mainAsset() external view returns (address);
    function minSlippageProvider() external view returns (address);
    function name() external view returns (string memory);
    function operations(uint256) external view returns (uint8 opType, bytes memory params, bool isInitialized);
    function operationsQueue() external view returns (uint256 nextOperation, uint256 currentOperation);
    function owner() external view returns (address);
    function portfolioScore(uint256) external view returns (uint256);
    function processAction(uint256 amountToProcess) external returns (bool isExecutedCompletly);
    function rebalance(uint256 srcChainId, uint256 dstChainId, uint256 shareToRebalance, uint8 slippage) external;
    function rebalancer() external view returns (address);
    function redeem(address asset, uint256 shares, address beneficiary, uint8 slippage) external payable;
    function redeemIdToAssetsTransferred(uint256) external view returns (uint256);
    function removeChain(uint256 chainId) external;
    function removeToken(address token) external;
    function renounceOwnership() external;
    function rootVault() external view returns (address);
    function setNewMinSlippageProvider(address newProvider) external;
    function setNewNextOperation(uint256 newNextOperation) external;
    function setNewRebalancer(address newRebalancer) external;
    function startNextOperation() external payable;
    function symbol() external view returns (string memory);
    function totalAssets() external view returns (uint256 assets);
    function totalAssetsAfterDeposit(uint256) external view returns (uint256);
    function totalAssetsBeforeDeposit(uint256) external view returns (uint256);
    function totalPortfolioScore() external view returns (uint256 score);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferCompleted(bytes32 transferId, uint256 value, uint8 slippage) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transferOwnership(address newOwner) external;
    function trustedRemotes(uint16) external view returns (bytes memory);
    function updateBridgeAdapter(uint256 chainId, address bridgeAdapter) external;
    function updateScores(uint256[] memory chains, uint256[] memory scores) external;
}