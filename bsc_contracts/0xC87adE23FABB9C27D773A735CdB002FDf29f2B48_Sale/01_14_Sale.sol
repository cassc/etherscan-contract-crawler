pragma solidity ^0.8.17;
import 'contracts/position_trading/algorithms/PositionLockerAlgorithm.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/interfaces/assets/IAsset.sol';
import 'contracts/position_trading/algorithms/PositionLockerBase.sol';
import 'contracts/interfaces/position_trading/algorithms/ISaleAlgorithm.sol';

/// @dev performs a simple sale of the owner's asset for the output asset
contract Sale is PositionLockerBase, ISaleAlgorithm {
    mapping(uint256 => Price) public prices;

    event Sell(
        uint256 indexed positionId,
        address indexed buyer,
        uint256 count
    );

    constructor(address positionsControllerAddress)
        PositionLockerBase(positionsControllerAddress)
    {}

    function outputAssetLocked(uint256 positionId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return false;
    }

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

    function setPrice(uint256 positionId, Price calldata price)
        external
        onlyPositionOwner(positionId)
        positionUnlocked(positionId)
    {
        prices[positionId] = price;
    }

    function _afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) internal virtual override {
        uint256 positionId = positionsController.getAssetPositionId(asset);
        address ownerAssetAddr = positionsController
            .getAsset(positionId, 1)
            .contractAddr;
        address outputAssetAddr = positionsController
            .getAsset(positionId, 2)
            .contractAddr;
        // transfers from assets are not processed
        if (from == ownerAssetAddr || from == outputAssetAddr) return;
        // transfer to the owner's asset is not processed (top up)
        if (to == ownerAssetAddr) return;

        /*require(
            _positionLocked(positionId),
            'sale can be maked only if position editing is locked'
        );*/

        Price memory price = prices[positionId];
        require(
            price.nom > 0 && price.denom > 0,
            'the price is zero - owner of position must set price first'
        );
        require(
            price.nom == data[0] && price.denom == data[1],
            'price is changed'
        );

        IAsset ownerAsset = IAsset(ownerAssetAddr);
        IAsset outputAsset = IAsset(outputAssetAddr);
        require(
            to == address(outputAsset),
            'sale algorithm expects buyer transfer output asset'
        );

        uint256 buyCount = (amount * price.denom) / price.nom;
        require(buyCount > 0, 'nothing bought');
        require(
            buyCount <= ownerAsset.count(),
            'not enough owner asset to buy'
        );

        uint256 fee = (buyCount *
            positionsController.getFeeSettings().feePercent()) /
            positionsController.getFeeSettings().feeDecimals();

        if (fee == 0) {
            ownerAsset.withdraw(from, buyCount);
        } else {
            ownerAsset.withdraw(
                positionsController.getFeeSettings().feeAddress(),
                fee
            );
            ownerAsset.withdraw(from, buyCount - fee);
        }
        emit Sell(positionId, from, buyCount);
    }
}