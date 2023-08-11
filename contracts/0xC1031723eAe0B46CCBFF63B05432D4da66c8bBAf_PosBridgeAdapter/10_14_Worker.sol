// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.0;

import "./interfaces/IRootChainManager.sol";
import "./interfaces/IChildErc20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @author YLDR <[email protected]>
contract Worker is Ownable {
    event Pushed();

    using SafeERC20 for IERC20;

    IRootChainManager rootChainManager;
    address asset;
    bool isRootChain;
    bool isInitialized;

    uint256 internal _amount;
    bool public isSent = false;

    function init(address _asset, IRootChainManager _rootChainManager, bool _isRootChain) external {
        require(!isInitialized, "already initialized");
        _transferOwnership(_msgSender());
        asset = _asset;
        rootChainManager = _rootChainManager;
        isRootChain = _isRootChain;
        isInitialized = true;
    }

    function sendAssets(uint256 amount) external onlyOwner {
        _amount = amount;

        if (isRootChain) {
            address predicate = rootChainManager.typeToPredicate(rootChainManager.tokenToType(asset));
            IERC20(asset).safeIncreaseAllowance(predicate, type(uint256).max);
            rootChainManager.depositFor(address(this), address(asset), abi.encode(_amount));
            isSent = true;
        }
    }

    function pullAssets(bytes calldata exitData) external onlyOwner returns (uint256 received) {
        if (isRootChain) {
            rootChainManager.exit(exitData);
        }
        received = IERC20(asset).balanceOf(address(this));
        IERC20(asset).safeTransfer(owner(), received);
    }

    function pushTransfer() public {
        require(msg.sender == tx.origin, "Can be called only by external account");
        require(!isSent, "pushTransfer called before");
        require(!isRootChain, "Can be called only on non-root chain");

        IChildErc20(asset).withdraw(_amount);

        isSent = true;

        emit Pushed();
    }
}