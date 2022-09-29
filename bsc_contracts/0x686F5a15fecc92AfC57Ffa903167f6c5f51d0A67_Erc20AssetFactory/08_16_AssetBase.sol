pragma solidity ^0.8.17;
import 'contracts/interfaces/assets/IAsset.sol';
import 'contracts/interfaces/assets/IAssetListener.sol';
import 'contracts/lib/ownable/OwnableSimple.sol';
import 'contracts/interfaces/assets/IAssetCloneFactory.sol';

/// @dev an asset always has an owner algorithm, asset event listener
abstract contract AssetBase is IAsset, OwnableSimple {
    IAssetCloneFactory public factory;
    bool internal _isNotifyListener;

    constructor(address owner_, IAssetCloneFactory factory_)
        OwnableSimple(owner_)
    {
        _owner = address(owner_);
        factory = factory_;
    }

    function listener() internal view returns (IAssetListener) {
        return IAssetListener(_owner);
    }

    function withdraw(address recipient, uint256 amount)
        external
        virtual
        override
        onlyOwner
    {
        uint256[] memory data;
        if (_isNotifyListener)
            listener().beforeAssetTransfer(
                address(this),
                address(this),
                recipient,
                amount,
                data
            );
        withdrawInternal(recipient, amount);
        if (_isNotifyListener)
            listener().afterAssetTransfer(
                address(this),
                address(this),
                recipient,
                amount,
                data
            );
    }

    function withdrawInternal(address recipient, uint256 amount)
        internal
        virtual;

    function isNotifyListener() external view returns (bool) {
        return _isNotifyListener;
    }

    function setNotifyListener(bool value) external onlyOwner {
        _isNotifyListener = value;
    }
}