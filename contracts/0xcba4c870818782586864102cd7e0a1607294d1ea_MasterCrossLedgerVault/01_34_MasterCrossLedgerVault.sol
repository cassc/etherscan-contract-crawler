// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./CrossLedgerVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./libraries/Operations.sol";
import "./libraries/LzMessages.sol";
import "@apyflow-dlt/contracts/libraries/SafeAssetConverter.sol";
import "./interfaces/ISlippageProvider.sol";

/// @author YLDR <[email protected]>
contract MasterCrossLedgerVault is CrossLedgerVault, ERC20Burnable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using LzMessages for RedeemMessage;
    using LzMessages for bytes;
    using LzMessages for LzMessageType;
    using SafeAssetConverter for IAssetConverter;

    error TokenNotAllowed();
    error QueueBusy();
    error SlippageTooLow();
    error ZeroBeneficiary();
    error NotRebalancer();

    IAssetConverter public immutable assetConverter;
    ISlippageProvider public minSlippageProvider;

    // ---------------OPERATIONS DATA---------------
    struct Operation {
        OperationType opType;
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
    event ScoringUpdated(uint256 chainId, uint256 score);

    uint256 nextOpId = 1;
    OperationsQueue public operationsQueue;
    mapping(uint256 => uint256) opIdToActionsCount;
    mapping(uint256 => Operation) public operations;

    EnumerableSet.AddressSet internal tokens;

    // ----------------DEPOSITS DATA-----------------

    mapping(uint256 => uint256) public totalAssetsBeforeDeposit;
    mapping(uint256 => uint256) public totalAssetsAfterDeposit;
    mapping(uint256 => uint256) public portfolioScore;

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

    address public rebalancer;
    uint8 private immutable _decimals;

    constructor(
        IRootVault _rootVault,
        address _lzEndpoint,
        IAssetConverter _assetConverter,
        ISlippageProvider _minSlippageProvider,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) CrossLedgerVault(_rootVault, _lzEndpoint) {
        assetConverter = _assetConverter;
        operationsQueue.nextOperation = 1;
        minSlippageProvider = _minSlippageProvider;
        rebalancer = msg.sender;
        _decimals = mainAsset.decimals();
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    modifier onlyRebalancer() {
        if (msg.sender != rebalancer) {
            revert NotRebalancer();
        }
        _;
    }

    modifier onlyAllowedToken(address token) {
        if (!tokens.contains(token)) {
            revert TokenNotAllowed();
        }
        _;
    }

    modifier whenQueueNotBusy() {
        if (isQueueBusy()) {
            revert QueueBusy();
        }
        _;
    }

    function addToken(address token) external onlyOwner {
        require(!tokens.contains(token), "That token has already been added");
        tokens.add(token);

        IERC20(token).safeIncreaseAllowance(address(assetConverter), type(uint256).max);
    }

    function removeToken(address token) external onlyOwner onlyAllowedToken(token) {
        tokens.remove(token);
        IERC20(token).safeDecreaseAllowance(
            address(assetConverter), IERC20(token).allowance(address(this), address(assetConverter))
        );
    }

    function updateScores(uint256[] memory chains, uint256[] memory scores) public onlyRebalancer {
        require(chains.length == scores.length, "LM");
        for (uint256 i = 0; i < chains.length; i++) {
            portfolioScore[chains[i]] = scores[i];
            emit ScoringUpdated(chains[i], scores[i]);
        }
    }

    function setNewMinSlippageProvider(ISlippageProvider newProvider) external onlyOwner {
        minSlippageProvider = newProvider;
    }

    function setNewRebalancer(address newRebalancer) external onlyOwner {
        rebalancer = newRebalancer;
    }

    function setNewNextOperation(uint256 newNextOperation) external onlyOwner whenQueueNotBusy {
        operationsQueue.nextOperation = newNextOperation;
    }

    function dropCurrentOperation() external onlyOwner whenQueueNotBusy {
        operationsQueue.currentOperation = 0;
    }

    function totalPortfolioScore() public view returns (uint256 score) {
        score = portfolioScore[block.chainid];
        for (uint256 i = 0; i < chains.length(); i++) {
            uint256 chainId = chains.at(i);
            score += portfolioScore[chainId];
        }
    }

    // ----------------OPERATIONS LOGIC------------------

    function isQueueBusy() public view returns (bool) {
        return operationsQueue.currentOperation != 0;
    }

    function isQueueEmpty() public view returns (bool) {
        return !operations[operationsQueue.nextOperation].isInitialized;
    }

    function canNewOperationBeProcessedInstantly() public view returns (bool) {
        return !isQueueBusy() && isQueueEmpty();
    }

    function _addOperationToQueue(OperationType opType, bytes memory params) internal {
        uint256 opId = nextOpId++;
        bool canProcessNow = canNewOperationBeProcessedInstantly();
        operations[opId] = Operation({opType: opType, params: params, isInitialized: true});
        emit OperationQueued(opId);
        if (canProcessNow) {
            startNextOperation();
        }
    }

    function startNextOperation() public payable whenQueueNotBusy {
        uint256 opId = operationsQueue.nextOperation;
        require(operations[opId].isInitialized, "no operations to start");

        Operation storage operation = operations[opId];
        OperationType opType = operation.opType;
        operationsQueue.currentOperation = opId;
        operationsQueue.nextOperation = opId + 1;

        emit OperationStarted(opId);

        if (opType == OperationType.DEPOSIT) {
            _startDeposit(opId, abi.decode(operation.params, (DepositOperationParams)));
        } else if (opType == OperationType.REDEEM) {
            _startRedeem(opId, abi.decode(operation.params, (RedeemOperationParams)));
        } else if (opType == OperationType.REBALANCE) {
            _startRebalance(opId, abi.decode(operation.params, (RebalanceOperationParams)));
        }
    }

    function _decreaseOpIdToActionsCount(uint256 opId) internal {
        if (--opIdToActionsCount[opId] == 0) {
            _completeOperation(opId);
        }
    }

    function _completeOperation(uint256 opId) internal {
        Operation storage operation = operations[opId];
        OperationType opType = operation.opType;
        if (opType == OperationType.DEPOSIT) {
            _completeDeposit(opId, abi.decode(operation.params, (DepositOperationParams)));
        } else if (opType == OperationType.REDEEM) {
            _completeRedeem(opId, abi.decode(operation.params, (RedeemOperationParams)));
        } // don't need to complete rebalancing
        emit OperationCompleted(opId);
        operationsQueue.currentOperation = 0;
    }

    // ----------------DEPOSITS LOGIC------------------

    function _startDeposit(uint256 opId, DepositOperationParams memory params) internal {
        uint256 totalScore = totalPortfolioScore();
        uint256 leftMainAsset = params.mainAssetValue;

        for (uint256 i = 0; i < chains.length(); i++) {
            uint256 chainId = chains.at(i);
            uint256 score = portfolioScore[chainId];
            uint256 amountToSend = params.mainAssetValue * score / totalScore;
            _deposit(opId, chainId, amountToSend, params.slippage);
            leftMainAsset -= amountToSend;
        }

        uint256 amountForLocalDeposit = params.mainAssetValue * portfolioScore[block.chainid] / totalScore;
        _deposit(opId, block.chainid, amountForLocalDeposit, params.slippage);

        leftMainAsset -= amountForLocalDeposit;

        totalAssetsBeforeDeposit[opId] += dustAmount;
        totalAssetsAfterDeposit[opId] += dustAmount + leftMainAsset;

        dustAmount += leftMainAsset;
    }

    function _completeDeposit(uint256 opId, DepositOperationParams memory params) internal {
        uint256 totalAssetsBefore = totalAssetsBeforeDeposit[opId];
        uint256 totalAssetsAfter = totalAssetsAfterDeposit[opId];
        uint256 deposited = totalAssetsAfter - totalAssetsBefore;
        uint256 shares;
        uint256 pricePerToken;
        if (totalSupply() == 0) {
            shares = totalAssetsAfter;
        } else {
            shares = (deposited * totalSupply()) / totalAssetsBefore;
        }
        if (shares > 0) {
            _mint(params.beneficiary, shares);
            pricePerToken = params.value * (10 ** decimals()) / shares;
        } else {
            pricePerToken = 10 ** IERC20Metadata(params.asset).decimals();
        }
        emit Deposit(params.caller, params.beneficiary, params.asset, params.value, shares, pricePerToken, opId);
    }

    function deposit(address asset, uint256 value, address beneficiary, uint8 slippage)
        external
        onlyAllowedToken(asset)
    {
        if (beneficiary == address(0)) {
            revert ZeroBeneficiary();
        }

        uint8 minSlippage = minSlippageProvider.getMinDepositSlippage(asset, value);
        if (slippage < minSlippage) {
            revert SlippageTooLow();
        }

        IERC20(asset).safeTransferFrom(msg.sender, address(this), value);

        uint256 mainAssetValue = assetConverter.safeSwap(asset, address(mainAsset), value);

        bytes memory params = abi.encode(
            DepositOperationParams({
                caller: _msgSender(),
                asset: asset,
                value: value,
                mainAssetValue: mainAssetValue,
                beneficiary: beneficiary,
                slippage: slippage
            })
        );
        _addOperationToQueue(OperationType.DEPOSIT, params);
    }

    // ----------------REDEEMS LOGIC------------------

    function _startRedeem(uint256 opId, RedeemOperationParams memory params) internal {
        uint256 dustAmountToWithdraw = dustAmount * params.shares / totalSupply();
        redeemIdToAssetsTransferred[opId] = dustAmountToWithdraw;
        dustAmount -= dustAmountToWithdraw;

        for (uint256 i = 0; i < chains.length(); i++) {
            uint256 chainId = chains.at(i);
            _redeem(opId, chainId, params.shares, totalSupply(), params.slippage);
        }

        _redeem(opId, block.chainid, params.shares, totalSupply(), params.slippage);

        _burn(address(this), params.shares);
    }

    function _completeRedeem(uint256 opId, RedeemOperationParams memory params) internal {
        uint256 mainAssetValue = redeemIdToAssetsTransferred[opId];
        uint256 assets = assetConverter.safeSwap(address(mainAsset), params.asset, mainAssetValue);
        IERC20(params.asset).safeTransfer(params.beneficiary, assets);
        uint256 pricePerToken = (assets * (10 ** decimals()) * (10 ** 18))
            / ((10 ** IERC20Metadata(params.asset).decimals()) * params.shares);
        emit Withdrawal(params.caller, params.beneficiary, params.asset, assets, params.shares, pricePerToken, opId);
    }

    function redeem(address asset, uint256 shares, address beneficiary, uint8 slippage)
        external
        payable
        onlyAllowedToken(asset)
    {
        if (beneficiary == address(0)) {
            revert ZeroBeneficiary();
        }
        if (shares == 0) {
            revert ZeroAmount();
        }
        uint8 minSlippage = minSlippageProvider.getMinRedeemSlippage(shares);
        if (slippage < minSlippage) {
            revert SlippageTooLow();
        }

        _transfer(_msgSender(), address(this), shares);
        bytes memory params = abi.encode(
            RedeemOperationParams({
                caller: _msgSender(),
                asset: asset,
                shares: shares,
                beneficiary: beneficiary,
                slippage: slippage
            })
        );
        _addOperationToQueue(OperationType.REDEEM, params);
    }

    // --------------CROSS-CHAIN TRANSFERS LOGIC----------------

    // master vault receives only funds from redeems in slave vaults
    function _transferCompleted(bytes32, uint256 value, uint8) internal virtual override {
        _redeemCompleted(value);
    }

    // ----------------REBALANCING LOGIC------------------

    function rebalance(uint256 srcChainId, uint256 dstChainId, uint256 shareToRebalance, uint8 slippage)
        external
        onlyRebalancer
    {
        require(canNewOperationBeProcessedInstantly(), "rebalancing cannot be queued");
        bytes memory params = abi.encode(
            RebalanceOperationParams({
                srcChainId: srcChainId,
                dstChainId: dstChainId,
                shareToRebalance: shareToRebalance,
                slippage: slippage
            })
        );
        _addOperationToQueue(OperationType.REBALANCE, params);
    }

    function _startRebalance(uint256 opId, RebalanceOperationParams memory params) internal {
        _redeem(opId, params.srcChainId, params.shareToRebalance, 1000, params.slippage);
    }

    function _processLzMessage(LzMessageType messageType, bytes memory data) internal virtual override {
        if (messageType == LzMessageType.DEPOSITED_FROM_BRIDGE) {
            DepositedFromBridgeMessage memory message = abi.decode(data, (DepositedFromBridgeMessage));
            _depositCompleted(message.totalAssetsBefore, message.totalAssetsAfter);
        }
    }

    function _deposit(uint256 opId, uint256 toChainId, uint256 amount, uint8 slippage) internal {
        opIdToActionsCount[opId]++;
        if (toChainId == block.chainid) {
            _depositLocal(amount, slippage);
        } else {
            if (amount > 0) {
                IBridgeAdapter adapter = bridgeAdapters[toChainId];
                bytes32 transferId = adapter.sendAssets(amount, address(0), slippage);
                _sendUpdateMessage(toChainId, transferId);
            } else {
                bytes memory payload = LzMessageType.ZERO_DEPOSIT.encodeMessage("");
                _lzSend(chainIdToLzChainId[toChainId], payload, "");
            }
        }
    }

    function _redeem(uint256 opId, uint256 fromChainId, uint256 shares, uint256 totalSupply, uint8 slippage) internal {
        opIdToActionsCount[opId]++;
        if (fromChainId == block.chainid) {
            _redeemLocal(shares, totalSupply, slippage);
        } else {
            uint16 lzChainId = chainIdToLzChainId[fromChainId];
            bytes memory payload =
                RedeemMessage({shares: shares, totalSupply: totalSupply, slippage: slippage}).encodeMessage();
            _lzSend(lzChainId, payload, "");
        }
    }

    function _depositCompleted(uint256 totalAssetsBefore, uint256 totalAssetsAfter) internal override {
        uint256 opId = operationsQueue.currentOperation;
        Operation memory operation = operations[opId];
        if (operation.opType == OperationType.DEPOSIT) {
            totalAssetsBeforeDeposit[opId] += totalAssetsBefore;
            totalAssetsAfterDeposit[opId] += totalAssetsAfter;
        }
        _decreaseOpIdToActionsCount(opId);
    }

    function _redeemCompleted(uint256 assetsReceived) internal override {
        uint256 opId = operationsQueue.currentOperation;
        Operation memory operation = operations[opId];
        if (operation.opType == OperationType.REDEEM) {
            redeemIdToAssetsTransferred[opId] += assetsReceived;
        } else {
            // REBALANCE case
            RebalanceOperationParams memory params = abi.decode(operation.params, (RebalanceOperationParams));
            _deposit(opId, params.dstChainId, assetsReceived, params.slippage);
        }
        _decreaseOpIdToActionsCount(opId);
    }
}