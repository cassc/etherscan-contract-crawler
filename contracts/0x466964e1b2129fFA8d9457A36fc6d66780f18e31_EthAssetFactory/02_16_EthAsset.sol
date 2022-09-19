pragma solidity ^0.8.17;
import 'contracts/position_trading/assets/AssetBase.sol';
import 'contracts/position_trading/PositionSnapshot.sol';
import 'contracts/interfaces/position_trading/IPositionAlgorithm.sol';
import 'contracts/interfaces/assets/typed/IErc721ItemAsset.sol';

contract EthAsset is AssetBase {
    constructor(address owner_, IAssetCloneFactory factory_)
        AssetBase(owner_, factory_)
    {}

    function count() external view override returns (uint256) {
        return address(this).balance;
    }

    function withdrawInternal(address recipient, uint256 amount)
        internal
        virtual
        override
    {
        payable(recipient).transfer(amount);
    }

    receive() external payable {} // for silent payable (without alerting the observer)

    function receiveWithData(uint256[] calldata data) external payable {
        listener().beforeAssetTransfer(
            address(this),
            msg.sender,
            address(this),
            msg.value,
            data
        );
        listener().afterAssetTransfer(
            address(this),
            msg.sender,
            address(this),
            msg.value,
            data
        );
    }

    function clone(address owner) external override returns (IAsset) {
        return factory.clone(address(this), owner);
    }

    function assetTypeId() external pure override returns (uint256) {
        return 1;
    }
}