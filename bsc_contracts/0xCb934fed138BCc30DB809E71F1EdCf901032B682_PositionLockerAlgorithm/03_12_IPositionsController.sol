pragma solidity ^0.8.17;
import 'contracts/lib/factories/ContractData.sol';
import 'contracts/fee/IFeeSettings.sol';

interface IPositionsController {
    /// @dev returns fee settings
    function getFeeSettings() external view returns(IFeeSettings);

    /// @dev returns the position owner
    function ownerOf(uint256 positionId) external view returns (address);

    /// @dev changes position owner
    function transferPositionOwnership(uint256 positionId, address newOwner)
        external;

    /// @dev returns the position of the asset to its address
    function getAssetPositionId(address assetAddress)
        external
        view
        returns (uint256);

    /// @dev returns an asset by its code in position 1 or 2
    function getAsset(uint256 positionId, uint256 assetCode)
        external
        view
        returns (ContractData memory);

    /// @dev creates a position
    function createPosition() external;

    /// @dev sets an asset to position
    /// @param positionId position ID
    /// @param assetCode asset code 1 - owner asset 2 - output asset
    /// @param data asset contract data
    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        ContractData calldata data
    ) external;

    /// @dev sets the position algorithm
    function setAlgorithm(uint256 positionId, ContractData calldata data)
        external;

    /// @dev returns the position algorithm
    function getAlgorithm(uint256 positionId)
        external
        view
        returns (ContractData memory data);

    /// @dev disables position editing
    function disableEdit(uint256 positionId) external;

    /// @dev returns position from the account's list of positions
    function positionOfOwnerByIndex(address account, uint256 index)
        external
        view
        returns (uint256);

    /// @dev returns the number of positions the account owns
    function ownedPositionsCount(address account)
        external
        view
        returns (uint256);
}