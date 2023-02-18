pragma solidity >0.8.0;

import "IBridgeAdapter.sol";
import "ICrossLedgerVault.sol";
import "Ownable.sol";
import "IERC20.sol";
import "ERC1967Proxy.sol";
import "SafeERC20.sol";

interface IChildErc20 {
    function withdraw(uint256 amount) external;
}

interface IRootChainManager {
    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function exit(bytes calldata inputData) external;

    function tokenToType(address token) external returns (bytes32);

    function typeToPredicate(bytes32 tokenType) external returns (address);
}

contract Worker is Ownable {
    using SafeERC20 for IERC20;

    IRootChainManager rootChainManager;
    bool isRootChain;
    bool isInitialized;

    function init(IRootChainManager _rootChainManager, bool _isRootChain)
        external
    {
        require(!isInitialized, "already initialized");
        _transferOwnership(_msgSender());
        rootChainManager = _rootChainManager;
        isRootChain = _isRootChain;
        isInitialized = true;
    }

    function sendAssets(uint256 amount, address asset) external onlyOwner {
        if (isRootChain) {
            address predicate = rootChainManager.typeToPredicate(
                rootChainManager.tokenToType(asset)
            );
            IERC20(asset).safeIncreaseAllowance(predicate, type(uint256).max);
            rootChainManager.depositFor(
                address(this),
                asset,
                abi.encode(amount)
            );
        } else {
            IChildErc20(asset).withdraw(amount);
        }
    }

    function pullAssets(address asset, bytes calldata exitData)
        external
        onlyOwner
        returns (uint256 received)
    {
        if (isRootChain) {
            rootChainManager.exit(exitData);
        }
        received = IERC20(asset).balanceOf(address(this));
        IERC20(asset).safeTransfer(owner(), received);
    }
}

contract PosBridgeAdapter is IBridgeAdapter, Ownable {
    using SafeERC20 for IERC20;

    ICrossLedgerVault public crossLedgerVault;

    IRootChainManager public rootChainManager;

    mapping(address => address) public dstAssets;

    bool public isRootChain;

    address workerImplementation;

    uint256 nonce = 0;

    uint256 public dstChainId;

    event AssetsSent(
        bytes32 transferId,
        address worker,
        address asset,
        address dstAsset,
        uint256 dstChainId,
        uint256 value,
        address to,
        bytes data
    );
    event AssetsReceived(bytes32 transferId);

    constructor(
        ICrossLedgerVault _crossLedgerVault,
        bool _isRootChain,
        IRootChainManager _manager,
        uint256 _dstChainId
    ) {
        crossLedgerVault = _crossLedgerVault;
        isRootChain = _isRootChain;
        rootChainManager = _manager;
        workerImplementation = address(new Worker());
        dstChainId = _dstChainId;
    }

    function updateDstAsset(address asset, address dstAsset) public onlyOwner {
        dstAssets[asset] = dstAsset;
    }

    // deploys proxy by given salt
    function _deployWorkerProxy(bytes32 salt) internal returns (Worker) {
        address proxy = address(
            new ERC1967Proxy{salt: salt}(workerImplementation, "")
        );
        Worker(proxy).init(rootChainManager, isRootChain);
        return Worker(proxy);
    }

    // deploys worker on source chain and performs sending from it
    // to - address(0) in case of root vault deposit
    function sendAssets(
        uint256 value,
        address asset,
        address to
    ) external override returns (bytes32 transferId) {
        address dstAsset = dstAssets[asset];
        bool notifyVault = (msg.sender == address(crossLedgerVault));
        require((to != address(0)) || (notifyVault), "Can't deposit to vault without notification");
        bytes memory data = abi.encode(
            keccak256(abi.encode(nonce++, uint256(block.chainid), address(this))),
            dstChainId,
            value,
            dstAsset,
            to,
            notifyVault
        );
        transferId = keccak256(data);
        Worker worker = _deployWorkerProxy(transferId);
        IERC20(asset).safeTransferFrom(msg.sender, address(worker), value);
        worker.sendAssets(value, asset);
        emit AssetsSent(
            transferId,
            address(worker),
            asset,
            dstAsset,
            dstChainId,
            value,
            to,
            data
        );
    }

    // deploys worker on destination chain and sends asset to destination
    function pullAssets(bytes memory data, bytes calldata exitData)
        external
        returns (uint256 pooled)
    {
        bytes32 transferId = keccak256(data);
        (, uint256 neededChainId, uint256 value, address asset, address receiver, bool notifyVault) = abi.decode(
            data,
            (bytes32, uint256, uint256, address, address, bool)
        );

        Worker worker = _deployWorkerProxy(transferId);
        pooled = worker.pullAssets(asset, exitData);

        require(neededChainId == block.chainid, "that is not the destination chain");
        require(pooled >= value, "value is not enough");

        if (receiver == address(0)) {
            if (
                IERC20(asset).allowance(
                    address(this),
                    address(crossLedgerVault)
                ) < pooled
            ) {
                IERC20(asset).safeIncreaseAllowance(
                    address(crossLedgerVault),
                    type(uint256).max
                );
            }
            crossLedgerVault.depositFundsToRootVault(transferId, asset, pooled);
        } else {
            IERC20(asset).safeTransfer(receiver, pooled);
            if (notifyVault) {
                crossLedgerVault.transferCompleted(transferId, asset, pooled);
            }
        }
        emit AssetsReceived(transferId);
    }
}