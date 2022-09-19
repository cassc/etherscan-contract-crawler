pragma solidity ^0.8.17;
import 'contracts/interfaces/assets/IAssetListener.sol';

/// @dev base contract for IAssetListener interface
contract AssetListenerBase is IAssetListener {
    function beforeAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external virtual override {}

    function afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external virtual override {}
}