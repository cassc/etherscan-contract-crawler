pragma solidity 0.8.17;

import "CrossLedgerVault.sol";
import "IERC20.sol";
import "ERC20Burnable.sol";
import "IERC20Metadata.sol";
import "EnumerableSet.sol";
import "EnumerableMap.sol";
import "ECDSA.sol";
import "CrossLedgerOracle.sol";

contract MasterCrossLedgerVault is CrossLedgerVault, ERC20Burnable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    CrossLedgerOracle oracle;

    // ---------------OPERATIONS DATA---------------
    enum OperationType {
        DEPOSIT,
        REDEEM,
        REBALANCE
    }

    struct Operation {
        OperationType opType;
        address caller;
        bytes params;
        bool isInitialized;
    }

    struct OperationsQueue {
        uint256 nextOperation;
        uint256 currentOperation;
    }

    event OperationQueued(uint256 opId);
    event OperationStarted(uint256 opId);
    event OperationCompleted(uint256 opId);

    uint256 nextOpId = 1;
    OperationsQueue operationsQueue;
    EnumerableMap.UintToUintMap opIdToTransfersCount;
    mapping(uint256 => Operation) public operations;

    // ----------CROSS-CHAIN TRANSFERS DATA----------

    mapping(uint256 => uint256) public chainIdToGasLimit;
    mapping(bytes32 => bool) public isTransferCompleted;
    mapping(bytes32 => uint256) public transferIdToOpId;

    // ----------------DEPOSITS DATA-----------------

    mapping(uint256 => uint256) public totalAssetsBeforeDeposit;
    mapping(uint256 => uint256) public totalAssetsAfterDeposit;

    event Deposit(
        address indexed who,
        address indexed receiver,
        address indexed asset,
        uint256 numberOfAssets,
        uint256 numberOfShares,
        uint256 pricePerToken,
        uint256 opId
    );

    // ----------------REDEEMS DATA------------------
    mapping(uint256 => uint256) public redeemIdToAssetsTransferred;

    event Withdrawal(
        address indexed who,
        address indexed receiver,
        address indexed asset,
        uint256 numberOfAssets,
        uint256 numberOfShares,
        uint256 pricePerToken,
        uint256 opId
    );

    // -----------------------------------------------

    constructor(
        IRootVault _rootVault,
        IRootVaultZap _zap,
        address _lzEndpoint,
        CrossLedgerOracle _oracle,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) CrossLedgerVault(_rootVault, _zap, _lzEndpoint) {
        oracle = _oracle;
        operationsQueue.nextOperation = 1;
    }

    function oracleDataAcrossAllLedgers()
        public
        view
        returns (uint256 totalScore, uint256 totalAssets)
    {
        totalScore = oracle.portfolioScore(block.chainid);
        totalAssets = oracle.totalAssets(block.chainid);
        for (uint256 i = 0; i < chains.length(); i++) {
            uint256 chainId = chains.at(i);
            totalScore += oracle.portfolioScore(chainId);
            totalAssets += oracle.totalAssets(chainId);
        }
    }

    function updateGasLimit(uint256 chainId, uint256 gasLimit)
        external
        onlyOwner
    {
        chainIdToGasLimit[chainId] = gasLimit;
    }

    // ----------------OPERATIONS LOGIC------------------

    function _decreaseOpIdToTransferCount(uint256 opId) internal {
        uint256 value = opIdToTransfersCount.get(opId);
        if (value == 1) {
            opIdToTransfersCount.remove(opId);
            _completeOperation(opId);
        } else {
            opIdToTransfersCount.set(opId, value - 1);
        }
    }

    function isQueueBusy() public view returns (bool) {
        return operationsQueue.currentOperation != 0;
    }

    function isQueueEmpty() public view returns (bool) {
        return !operations[operationsQueue.nextOperation].isInitialized;
    }

    function canNewOperationBeProcessedInstantly() public view returns (bool) {
        return !isQueueBusy() && isQueueEmpty();
    }

    function _addOperationToQueue(
        OperationType opType,
        address caller,
        bytes memory params
    ) internal {
        uint256 opId = nextOpId++;
        bool canProcessNow = canNewOperationBeProcessedInstantly();
        operations[opId] = Operation({
            opType: opType,
            caller: caller,
            params: params,
            isInitialized: true
        });
        emit OperationQueued(opId);
        if (canProcessNow) {
            startNextOperation();
        }
    }

    function startNextOperation() public payable {
        require(
            operationsQueue.currentOperation == 0,
            "there is another operation in progress"
        );
        uint256 opId = operationsQueue.nextOperation;
        require(operations[opId].isInitialized, "no operations to start");
        emit OperationStarted(opId);
        Operation storage operation = operations[opId];
        if (operation.opType == OperationType.REDEEM) {
            (address asset, uint256 shares, address beneficiary) = abi.decode(
                operation.params,
                (address, uint256, address)
            );
            _startRedeem(opId, asset, shares, beneficiary);
        } else if (operation.opType == OperationType.DEPOSIT) {
            (address asset, uint256 value, ) = abi.decode(
                operation.params,
                (address, uint256, address)
            );
            _startDeposit(opId, asset, value);
        } else if (operation.opType == OperationType.REBALANCE) {
            (
                uint256 srcChainId,
                uint256 dstChainId,
                address asset,
                uint256 shareToRebalance
            ) = abi.decode(
                    operation.params,
                    (uint256, uint256, address, uint256)
                );
            _startRebalance(
                opId,
                srcChainId,
                dstChainId,
                asset,
                shareToRebalance
            );
        }
        operationsQueue.currentOperation = opId;
        operationsQueue.nextOperation = opId + 1;
    }

    function _completeOperation(uint256 opId) internal {
        require(operationsQueue.currentOperation == opId, "This operation is not in progress");
        Operation storage operation = operations[opId];
        if (operation.opType == OperationType.REDEEM) {
            (address asset, uint256 shares, address beneficiary) = abi.decode(
                operation.params,
                (address, uint256, address)
            );
            _completeRedeem(opId, operation.caller, asset, shares, beneficiary);
        } else if (operation.opType == OperationType.DEPOSIT) {
            (address asset, uint256 value, address beneficiary) = abi.decode(
                operation.params,
                (address, uint256, address)
            );
            _completeDeposit(opId, value, asset, operation.caller, beneficiary);
        } else if (operation.opType == OperationType.REBALANCE) {
            // no need to complete rebalancing
        }
        emit OperationCompleted(opId);
        operationsQueue.currentOperation = 0;
    }

    // ----------------DEPOSITS LOGIC------------------

    function _startDeposit(
        uint256 opId,
        address asset,
        uint256 value
    ) internal {
        totalAssetsBeforeDeposit[opId] += totalAssets();
        (uint256 totalScore, ) = oracleDataAcrossAllLedgers();
        _depositLocal(asset, value * oracle.portfolioScore(block.chainid) / totalScore);
        totalAssetsAfterDeposit[opId] += totalAssets();
        uint256 sentTransfers;
        for (uint256 i = 0; i < chains.length(); i++) {
            uint256 chainId = chains.at(i);
            uint256 score = oracle.portfolioScore(chainId);
            IBridgeAdapter adapter = bridgeAdapters[asset][chainId];
            uint256 amountToSend = (value * score) / totalScore;
            if (amountToSend == 0) continue;
            bytes32 transferId = adapter.sendAssets(
                amountToSend,
                asset,
                address(0)
            );
            transferIdToOpId[transferId] = opId;
            sentTransfers++;
        }
        opIdToTransfersCount.set(opId, sentTransfers);
    }

    function _completeDeposit(
        uint256 opId,
        uint256 value,
        address asset,
        address caller,
        address beneficiary
    ) internal {
        uint256 totalAssetsBefore = totalAssetsBeforeDeposit[opId];
        uint256 totalAssetsAfter = totalAssetsAfterDeposit[opId];
        uint256 pricePerToken = 0;
        if (totalSupply() == 0) {
            pricePerToken = 10**18;
        } else {
            pricePerToken =
                (totalAssetsBefore * (10**decimals())) /
                totalSupply();
        }

        uint256 shares = ((totalAssetsAfter - totalAssetsBefore) *
            (10**decimals())) / pricePerToken;
        _mint(beneficiary, shares);
        emit Deposit(
            caller,
            beneficiary,
            asset,
            value,
            shares,
            pricePerToken,
            opId
        );
    }

    function deposit(
        address asset,
        uint256 value,
        address beneficiary
    ) external onlyAllowedToken(asset) {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), value);
        _addOperationToQueue(
            OperationType.DEPOSIT,
            msg.sender,
            abi.encode(asset, value, beneficiary)
        );
    }

    // ----------------REDEEMS LOGIC------------------

    function _requestRedeemOnOtherChain(
        uint256 chainId,
        uint256 opId,
        uint256 shares,
        uint256 totalSupply,
        address receiver, // address(0) in case of rebalancing
        address asset
    ) internal {
        uint16 lzChainId = chainIdToLzChainId[chainId];
        IBridgeAdapter bridgeAdapter = bridgeAdapters[asset][chainId];
        address dstAsset = bridgeAdapter.dstAssets(asset);
        bytes memory payload = _encodeRedeemMessage(
            opId,
            shares,
            totalSupply,
            receiver,
            dstAsset
        );
        uint256 gasLimitAtDst = chainIdToGasLimit[chainId];
        bytes memory adapterParams = abi.encodePacked(uint16(1), gasLimitAtDst);
        uint256 _nativeFee = _estimateLzCall(lzChainId, payload, adapterParams);
        _lzSend(
            lzChainId,
            payload,
            payable(msg.sender),
            address(0),
            adapterParams,
            _nativeFee
        );
    }

    function _startRedeem(
        uint256 opId,
        address asset,
        uint256 shares,
        address beneficiary
    ) internal {
        uint256 _totalSupply = totalSupply();
        _burn(address(this), shares);
        opIdToTransfersCount.set(opId, chains.length());
        for (uint256 i = 0; i < chains.length(); i++) {
            uint256 chainId = chains.at(i);
            _requestRedeemOnOtherChain(
                chainId,
                opId,
                shares,
                _totalSupply,
                beneficiary,
                asset
            );
        }
        uint256 assets = _redeemLocal(shares, _totalSupply, asset);
        redeemIdToAssetsTransferred[opId] += assets;
        IERC20(asset).safeTransfer(beneficiary, assets);
    }

    function _completeRedeem(
        uint256 opId,
        address caller,
        address asset,
        uint256 shares,
        address beneficiary
    ) internal {
        uint256 assets = redeemIdToAssetsTransferred[opId];
        uint256 pricePerToken = (assets * (10**18) * (10**decimals())) /
            ((10**IERC20Metadata(asset).decimals()) * shares);
        emit Withdrawal(
            caller,
            beneficiary,
            asset,
            assets,
            shares,
            pricePerToken,
            opId
        );
    }

    function redeem(
        address asset,
        uint256 shares,
        address beneficiary
    ) external payable onlyAllowedToken(asset) {
        _transfer(msg.sender, address(this), shares);
        _addOperationToQueue(
            OperationType.REDEEM,
            msg.sender,
            abi.encode(asset, shares, beneficiary)
        );
    }

    // --------------CROSS-CHAIN TRANSFERS LOGIC----------------

    function _setTransferAsCompleted(
        bytes32 transferId,
        address asset,
        uint256 value
    ) internal {
        isTransferCompleted[transferId] = true;
        uint256 opId = transferIdToOpId[transferId];
        require(opId != 0, "transfer is not matched to operation (yet)");
        Operation storage operation = operations[opId];
        if (operation.opType == OperationType.REDEEM) {
            redeemIdToAssetsTransferred[opId] += value;
        } else if (operations[opId].opType == OperationType.REBALANCE) {
            if (opIdToTransfersCount.get(opId) == 2) {

                // if rebalance needs two transfers (src -> current; current -> dst)
                // then we need to start the second (current -> dst)
                
                (, uint256 dstChainId, , ) = abi.decode(
                    operation.params,
                    (uint256, uint256, address, uint256)
                );
                IBridgeAdapter adapter = bridgeAdapters[asset][dstChainId];
                bytes32 secondTransferId = adapter.sendAssets(
                    value,
                    asset,
                    address(0)
                );
                transferIdToOpId[secondTransferId] = opId;
            }
        }
        _decreaseOpIdToTransferCount(opId);
        
    }

    function transferCompleted(
        bytes32 transferId,
        address asset,
        uint256 value
    ) public override onlyFromBridgeAdapter {
        _setTransferAsCompleted(transferId, asset, value);
    }

    function depositFundsToRootVault(
        bytes32 transferId,
        address asset,
        uint256 value
    ) public override returns (uint256 shares) {
        shares = super.depositFundsToRootVault(transferId, asset, value);
        _setTransferAsCompleted(transferId, asset, value);
    }

    // ----------------REBALANCING LOGIC------------------

    function _computeDeviation(
        uint256 totalAssets,
        uint256 totalScore,
        uint256 assets,
        uint256 score
    ) internal pure returns (int256 deviation) {
        deviation =
            int256((1000000 * assets) / totalAssets) -
            int256((1000000 * score) / totalScore);
    }

    function checkRebalancing(
        uint256 srcChainId,
        uint256 dstChainId,
        uint256 shareToRebalance
    ) public view returns (bool isCorrect) {
        (
            uint256 totalScore,
            uint256 totalAssets
        ) = oracleDataAcrossAllLedgers();
        uint256 srcScore = oracle.portfolioScore(srcChainId);
        uint256 dstScore = oracle.portfolioScore(dstChainId);
        uint256 srcAssets = oracle.totalAssets(srcChainId);
        uint256 dstAssets = oracle.totalAssets(dstChainId);
        int256 srcDeviation = _computeDeviation(
            totalAssets,
            totalScore,
            srcAssets,
            srcScore
        );
        int256 dstDeviation = _computeDeviation(
            totalAssets,
            totalScore,
            dstAssets,
            dstScore
        );
        uint256 amountToRebalance = (srcAssets * shareToRebalance) / 1000;
        int256 srcDeviationAfter = _computeDeviation(
            totalAssets,
            totalScore,
            srcAssets - amountToRebalance,
            srcScore
        );
        int256 dstDeviationAfter = _computeDeviation(
            totalAssets,
            totalScore,
            dstAssets + amountToRebalance,
            dstScore
        );
        isCorrect =
            (srcDeviation >= 0) &&
            (dstDeviation <= 0) &&
            (srcDeviationAfter >= 0) &&
            (dstDeviationAfter <= 0);
    }

    function rebalance(
        uint256 srcChainId,
        uint256 dstChainId,
        address asset,
        uint256 shareToRebalance
    ) external onlyAllowedToken(asset) {
        require(
            checkRebalancing(srcChainId, dstChainId, shareToRebalance),
            "rebalancing request invalid"
        );
        require(
            canNewOperationBeProcessedInstantly(),
            "rebalancing cannot be queued"
        );

        bytes memory params = abi.encode(
            srcChainId,
            dstChainId,
            asset,
            shareToRebalance
        );
        _addOperationToQueue(OperationType.REBALANCE, msg.sender, params);
    }

    function _startRebalance(
        uint256 opId,
        uint256 srcChainId,
        uint256 dstChainId,
        address asset,
        uint256 shareToRebalance
    ) internal {
        if (srcChainId == block.chainid) {
            uint256 assets = _redeemLocal(shareToRebalance, 1000, asset);
            IBridgeAdapter adapter = bridgeAdapters[asset][dstChainId];
            bytes32 transferId = adapter.sendAssets(assets, asset, address(0));
            transferIdToOpId[transferId] = opId;
            opIdToTransfersCount.set(opId, 1);
        } else if (dstChainId == block.chainid) {
            _requestRedeemOnOtherChain(
                srcChainId,
                opId,
                shareToRebalance,
                1000,
                address(0),
                asset
            );
            opIdToTransfersCount.set(opId, 1);
        } else {
            _requestRedeemOnOtherChain(
                srcChainId,
                opId,
                shareToRebalance,
                1000,
                address(this),
                asset
            );
            opIdToTransfersCount.set(opId, 2);
        }
    }

    function _blockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal virtual override {
        (LzMessage messageType, bytes memory data) = abi.decode(
            _payload,
            (LzMessage, bytes)
        );
        if (messageType == LzMessage.UPDATE) {
            (bytes32 transferId, uint256 opId) = abi.decode(
                data,
                (bytes32, uint256)
            );
            transferIdToOpId[transferId] = opId;
        } else if (messageType == LzMessage.DEPOSITED_FROM_BRIDGE) {
            (
                bytes32 transferId,
                uint256 totalAssetsBefore,
                uint256 totalAssetsAfter
            ) = abi.decode(data, (bytes32, uint256, uint256));
            uint256 opId = transferIdToOpId[transferId];
            totalAssetsBeforeDeposit[opId] += totalAssetsBefore;
            totalAssetsAfterDeposit[opId] += totalAssetsAfter;
            _decreaseOpIdToTransferCount(opId);
        }
    }
}