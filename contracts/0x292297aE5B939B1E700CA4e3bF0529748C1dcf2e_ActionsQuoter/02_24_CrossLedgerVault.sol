// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@apyflow-dlt/contracts/SuperAdminControl.sol";
import "./interfaces/IBridgeAdapter.sol";
import "@apyflow-dlt/contracts/interfaces/IRootVault.sol";
import "./LzApp.sol";
import "./libraries/LzMessages.sol";

abstract contract CrossLedgerVault is LzApp, SuperAdminControl {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;
    using SafeERC20 for IRootVault;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using LzMessages for bytes;
    using LzMessages for UpdateMessage;

    error NoActionIsInProgress();
    error TryingToProcessTooMuch();
    error ZeroAmount();
    error SlippageTooBig(uint256 expectedAssets, uint256 receivedAssets);

    event ActionQueued(uint256 amountIn, RootVaultActionType actionType);
    event ActionCompleted();

    IRootVault public immutable rootVault;
    IERC20Metadata public immutable mainAsset;

    EnumerableSet.UintSet internal chains;
    mapping(uint256 => uint16) public chainIdToLzChainId;
    RootVaultAction private _currentAction;
    bool public isActionInProgress;

    uint256 dustAmount = 0;

    enum RootVaultActionType {
        DEPOSIT,
        REDEEM
    }

    struct RootVaultAction {
        RootVaultActionType actionType;
        uint8 slippage;
        // in assets for deposits and in shares for redeem
        uint256 amountIn;
        // in shares for deposits and in assets for redeem
        uint256 amountOut;
    }

    // chain id => bridge adapter address
    mapping(uint256 => IBridgeAdapter) public bridgeAdapters;
    mapping(address => uint256) public bridgeAdapterToChainId;

    mapping(bytes32 => bool) public isTransferExpected;

    uint8 private immutable _decimals = 18;

    constructor(IRootVault _rootVault, address _lzEndpoint) LzApp(_lzEndpoint) {
        rootVault = _rootVault;
        mainAsset = IERC20Metadata(rootVault.asset());
        IERC20Metadata(mainAsset).safeIncreaseAllowance(address(rootVault), type(uint256).max);
    }

    modifier onlyFromBridgeAdapter() {
        require(bridgeAdapterToChainId[msg.sender] != 0, "only bridge adapter can call this method");
        _;
    }

    function currentAction() external view returns (RootVaultAction memory) {
        return _currentAction;
    }

    /// @dev This function may be used in cases when we have skipped operation, and don't want action to complete
    /// and affect next operation. Also it may be used if during normal functioning of vault for some reason
    /// we can't deposit dust into the root vault. In this case it may be called with finalize == true
    function dropCurrentAction(bool finalize) external onlyOwner {
        if (!isActionInProgress) {
            revert NoActionIsInProgress();
        }
        if (finalize) {
            _finalizeCurrentAction();
        } else {
            isActionInProgress = false;
        }
    }

    function addChain(uint256 chainId, uint16 lzChainId, address remoteVaultAddress) external onlyOwner {
        chains.add(chainId);
        chainIdToLzChainId[chainId] = lzChainId;
        _setTrustedRemoteAddress(lzChainId, remoteVaultAddress);
    }

    function removeChain(uint256 chainId) external onlyOwner {
        chains.remove(chainId);
        uint16 lzChainId = chainIdToLzChainId[chainId];
        chainIdToLzChainId[chainId] = 0;
        _setTrustedRemoteAddress(lzChainId, address(0));
    }

    function updateBridgeAdapter(uint256 chainId, address bridgeAdapter) external onlyOwner {
        require(chains.contains(chainId), "That distributed ledger has not been added yet");
        address oldBridgeAdapter = address(bridgeAdapters[chainId]);
        bridgeAdapters[chainId] = IBridgeAdapter(bridgeAdapter);
        bridgeAdapterToChainId[oldBridgeAdapter] = 0;
        bridgeAdapterToChainId[address(bridgeAdapter)] = chainId;
        if (oldBridgeAdapter != address(0)) {
            mainAsset.safeDecreaseAllowance(oldBridgeAdapter, mainAsset.allowance(address(this), oldBridgeAdapter));
        }
        mainAsset.safeIncreaseAllowance(bridgeAdapter, type(uint256).max);
    }

    function transferCompleted(bytes32 transferId, uint256 value, uint8 slippage) external onlyFromBridgeAdapter {
        require(isTransferExpected[transferId], "Unknown transfer ID");

        _transferCompleted(transferId, value, slippage);
    }

    function _transferCompleted(bytes32 transferId, uint256 value, uint8 slippage) internal virtual;

    function totalAssets() public view returns (uint256 assets) {
        assets = rootVault.convertToAssets(rootVault.balanceOf(address(this))) + dustAmount;
    }

    function _depositLocal(uint256 assets, uint8 slippage) internal {
        emit ActionQueued(assets, RootVaultActionType.DEPOSIT);
        _currentAction = RootVaultAction({
            actionType: RootVaultActionType.DEPOSIT,
            amountIn: assets,
            amountOut: 0,
            slippage: slippage
        });
        if (assets == 0) {
            _finalizeCurrentAction();
        } else {
            isActionInProgress = true;
        }
    }

    function _redeemLocal(uint256 shares, uint256 totalSupply, uint8 slippage) internal {
        uint256 amountToRedeem = (shares * rootVault.balanceOf(address(this))) / totalSupply;
        emit ActionQueued(amountToRedeem, RootVaultActionType.REDEEM);
        _currentAction = RootVaultAction({
            actionType: RootVaultActionType.REDEEM,
            amountIn: amountToRedeem,
            amountOut: 0,
            slippage: slippage
        });
        if (amountToRedeem == 0) {
            _finalizeCurrentAction();
        } else {
            isActionInProgress = true;
        }
    }

    function _depositCompleted(uint256 totalAssetsBefore, uint256 totalAssetsAfter) internal virtual;

    function _redeemCompleted(uint256 received) internal virtual;

    function _finalizeCurrentAction() internal {
        emit ActionCompleted();

        if (_currentAction.actionType == RootVaultActionType.REDEEM) {
            _redeemCompleted(_currentAction.amountOut);
        } else if (_currentAction.actionType == RootVaultActionType.DEPOSIT) {
            uint256 balanceAtRootVault = rootVault.balanceOf(address(this));

            uint256 totalAssetsBefore = rootVault.convertToAssets(balanceAtRootVault - _currentAction.amountOut);
            uint256 totalAssetsAfter = rootVault.convertToAssets(balanceAtRootVault);
            _depositCompleted(totalAssetsBefore, totalAssetsAfter);
        }
    }

    function processAction(uint256 amountToProcess) external returns (bool isExecutedCompletly) {
        if (!isActionInProgress) {
            revert NoActionIsInProgress();
        }
        if (_currentAction.amountIn < amountToProcess) {
            revert TryingToProcessTooMuch();
        }
        if (amountToProcess == 0) {
            revert ZeroAmount();
        }

        uint256 expectedAssets;
        uint256 receivedAssets;
        uint256 amountOut;

        if (_currentAction.actionType == RootVaultActionType.DEPOSIT) {
            expectedAssets = amountToProcess;
            amountOut = rootVault.deposit(amountToProcess, address(this));
            receivedAssets = rootVault.convertToAssets(amountOut);
        } else {
            receivedAssets = amountOut = rootVault.redeem(amountToProcess, address(this));
            expectedAssets = rootVault.feeInclusivePricePerToken() * amountToProcess / (10 ** rootVault.decimals());
        }

        // Adding 100 wei to avoid rounding errors
        bool receivedEnough = (receivedAssets + 100) >= ((1000 - _currentAction.slippage) * expectedAssets / 1000);

        if (!receivedEnough) {
            revert SlippageTooBig(expectedAssets, receivedAssets);
        }
        _currentAction.amountOut += amountOut;
        _currentAction.amountIn -= amountToProcess;

        if (_currentAction.amountIn == 0) {
            isActionInProgress = false;
            _finalizeCurrentAction();
            return true;
        } else {
            return false;
        }
    }

    // sends update message to tell the slave/master vault to expect certain transfer ID
    // we need this because anybody can trigger transfer from our bridge adapters
    function _sendUpdateMessage(uint256 toChainId, bytes32 transferId) internal {
        bytes memory payload = UpdateMessage({transferId: transferId}).encodeMessage();
        _lzSend(chainIdToLzChainId[toChainId], payload, "");
    }

    function _blockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal virtual override {
        (LzMessageType messageType, bytes memory data) = _payload.decodeTypeAndData();
        if (messageType == LzMessageType.UPDATE) {
            UpdateMessage memory message = abi.decode(data, (UpdateMessage));
            isTransferExpected[message.transferId] = true;
        } else {
            _processLzMessage(messageType, data);
        }
    }

    function _processLzMessage(LzMessageType messageType, bytes memory data) internal virtual;

    receive() external payable {}
}