pragma solidity ^0.8.17;
import './PositionAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/interfaces/assets/IAsset.sol';

/// @dev locks the asset of the position owner for a certain time
contract PositionLockerBase is PositionAlgorithm {
    mapping(uint256 => uint256) public unlockTimes; // unlock time by position

    modifier positionUnlocked(uint256 positionId) {
        require(!_positionLocked(positionId), 'for unlocked positions only');
        _;
    }

    modifier positionLocked(uint256 positionId) {
        require(_positionLocked(positionId), 'for locked positions only');
        _;
    }

    modifier assetUnLocked(uint256 positionId, uint256 assetCode) {
        if(!_positionLocked(positionId)){
             _;
             return;
        }
        if (assetCode == 1)
            require(!ownerAssetLocked(positionId), 'owner asset locked');
        else if (assetCode == 2)
            require(!outputAssetLocked(positionId), 'output asset locked');
        _;
    }

    constructor(address positionsController)
        PositionAlgorithm(positionsController)
    {}

    function isPositionLocked(uint256 positionId)
        external
        view
        virtual
        override
        returns (bool)
    {
        return _positionLocked(positionId);
    }

    function _positionLocked(uint256 positionId)
        internal
        view
        virtual
        returns (bool)
    {
        return block.timestamp < unlockTimes[positionId];
    }

    function lockPosition(uint256 positionId, uint256 lockSeconds)
        external
        onlyPositionOwner(positionId)
        positionUnlocked(positionId)
    {
        unlockTimes[positionId] = block.timestamp + lockSeconds * 1 seconds;
    }

    function lapsedLockSeconds(uint256 positionId)
        external
        view
        returns (uint256)
    {
        if (!_positionLocked(positionId)) return 0;
        return unlockTimes[positionId] - block.timestamp;
    }

    function _withdrawAsset(
        uint256 positionId,
        uint256 assetCode,
        address recipient,
        uint256 amount
    ) internal override assetUnLocked(positionId, assetCode) {
        super._withdrawAsset(positionId, assetCode, recipient, amount);
    }

    function ownerAssetLocked(uint256 positionId)
        public
        view
        virtual
        returns (bool)
    {
        return _positionLocked(positionId);
    }

    function outputAssetLocked(uint256 positionId)
        public
        view
        virtual
        returns (bool)
    {
        return _positionLocked(positionId);
    }
}