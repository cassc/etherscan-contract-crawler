pragma solidity ^0.8.17;
import 'contracts/interfaces/IOwnable.sol';

/// @dev asset abstraction
/// the owner of the asset is always the algorithm-observer of the asset
interface IAsset is IOwnable {
    /// @dev asset amount
    function count() external view returns (uint256);

    /// @dev withdrawal of a certain amount of asset to a certain address
    function withdraw(address recipient, uint256 amount) external;

    /// @dev creates a copy of the current asset, with 0 balance and the specified owner
    function clone(address owner) external returns (IAsset);

    /// @dev returns the asset type code (also used to check asset interface support)
    function assetTypeId() external returns (uint256);

    /// @dev if true, then notifies its observer (owner)
    function isNotifyListener() external returns (bool);

    /// @dev enables or disables the observer notification mechanism
    function setNotifyListener(bool value) external;
}