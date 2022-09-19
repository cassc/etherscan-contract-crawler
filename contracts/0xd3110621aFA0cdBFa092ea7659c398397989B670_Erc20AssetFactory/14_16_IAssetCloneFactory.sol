pragma solidity ^0.8.17;
import 'contracts/interfaces/assets/IAsset.sol';

interface IAssetCloneFactory {
    /// @dev makes a copy of the asset (the amount of the asset will be 0)
    function clone(address asset, address owner) external returns (IAsset);
}