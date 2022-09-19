pragma solidity ^0.8.17;
import 'contracts/interfaces/assets/IAssetListener.sol';

interface IPositionAlgorithm is IAssetListener {
    /// @dev if true, the algorithm locks position editing
    function isPositionLocked(uint256 positionId) external view returns (bool);

    /// @dev transfers ownership of the asset to the specified address
    function transferAssetOwnerShipTo(address asset, address newOwner) external;
}