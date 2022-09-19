pragma solidity ^0.8.17;
import './PositionAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/interfaces/assets/IAsset.sol';
import './PositionLockerBase.sol';
import 'contracts/interfaces/position_trading/algorithms/IPositionLockerAlgorithmInstaller.sol';

/// @dev locks the asset of the position owner for a certain time
contract PositionLockerAlgorithm is
    PositionLockerBase,
    IPositionLockerAlgorithmInstaller
{
    constructor(address positionsController)
        PositionLockerBase(positionsController)
    {}

    function setAlgorithm(uint256 positionId) external {
        _setAlgorithm(positionId);
    }

    function _setAlgorithm(uint256 positionId)
        internal
        onlyPositionOwner(positionId)
        positionUnlocked(positionId)
    {
        ContractData memory data;
        data.factory = address(0);
        data.contractAddr = address(this);
        positionsController.setAlgorithm(positionId, data);
    }
}