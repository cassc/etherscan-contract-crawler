// SPDX-License-Identifier: UNLICENSED

pragma solidity >0.8.0;

import "./interfaces/IBridgeAdapter.sol";
import "./interfaces/ICrossLedgerVault.sol";
import "./interfaces/IRootChainManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./Worker.sol";

struct TransferData {
    bytes32 nonce;
    uint256 dstChainId;
    uint256 value;
    address to;
    bool notifyVault;
    uint8 slippage;
}

/// @author YLDR <[email protected]>
contract PosBridgeAdapter is Initializable, IBridgeAdapter {
    using SafeERC20 for IERC20;

    ICrossLedgerVault public crossLedgerVault;
    IRootChainManager public rootChainManager;
    IERC20 public asset;
    bool public isRootChain;
    address public workerImplementation;
    uint256 nonce = 0;
    uint256 public dstChainId;

    event AssetsSent(
        bytes32 transferId, address worker, address asset, uint256 dstChainId, uint256 value, address to, bytes data
    );
    event AssetsReceived(bytes32 transferId);

    function initialize(
        ICrossLedgerVault _crossLedgerVault,
        bool _isRootChain,
        IRootChainManager _manager,
        uint256 _dstChainId 
    ) initializer public {
        crossLedgerVault = _crossLedgerVault;
        isRootChain = _isRootChain;
        rootChainManager = _manager;
        workerImplementation = address(new Worker());
        dstChainId = _dstChainId;
        asset = IERC20(crossLedgerVault.mainAsset());
    }

    // deploys proxy by given salt
    function _deployWorkerProxy(bytes32 salt) internal returns (Worker) {
        address proxy = Clones.cloneDeterministic(workerImplementation, salt);
        Worker(proxy).init(address(asset), rootChainManager, isRootChain);
        return Worker(proxy);
    }

    // deploys worker on source chain and performs sending from it
    // to == address(0) means send funds to vault on dst chain
    function sendAssets(uint256 value, address to, uint8 slippage) external override returns (bytes32 transferId) {
        bytes memory data = abi.encode(
            TransferData({
                nonce: keccak256(abi.encode(nonce++, uint256(block.chainid), address(this))),
                dstChainId: dstChainId,
                value: value,
                to: to,
                notifyVault: (msg.sender == address(crossLedgerVault)),
                slippage: slippage
            })
        );
        transferId = keccak256(data);
        Worker worker = _deployWorkerProxy(transferId);
        asset.safeTransferFrom(msg.sender, address(worker), value);
        worker.sendAssets(value);
        emit AssetsSent(transferId, address(worker), address(asset), dstChainId, value, to, data);
    }

    // deploys worker on destination chain and sends asset to destination
    function pullAssets(bytes memory data, bytes calldata exitData) external returns (uint256 pooled) {
        bytes32 transferId = keccak256(data);
        TransferData memory transferData = abi.decode(data, (TransferData));

        require(transferData.dstChainId == block.chainid, "that is not the destination chain");

        Worker worker = _deployWorkerProxy(transferId);
        pooled = worker.pullAssets(exitData);

        require(pooled >= transferData.value, "value is not enough");

        address receiver = transferData.to == address(0) ? address(crossLedgerVault) : transferData.to;
        asset.safeTransfer(receiver, pooled);

        if (transferData.notifyVault) {
            crossLedgerVault.transferCompleted(transferId, pooled, transferData.slippage);
        }

        emit AssetsReceived(transferId);
    }
}