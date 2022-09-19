pragma solidity ^0.8.17;
import 'contracts/position_trading/assets/AssetBase.sol';
import 'contracts/position_trading/PositionSnapshot.sol';
import 'contracts/interfaces/position_trading/IPositionAlgorithm.sol';
import 'contracts/interfaces/assets/typed/IErc20Asset.sol';

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Erc20Asset is AssetBase, IErc20Asset {
    address contractAddress;

    constructor(
        address owner_,
        IAssetCloneFactory factory_,
        address contractAddress_
    ) AssetBase(owner_, factory_) {
        contractAddress = contractAddress_;
    }

    function count() external view override returns (uint256) {
        return IERC20(contractAddress).balanceOf(address(this));
    }

    function getContractAddress() external view override returns (address) {
        return contractAddress;
    }

    function withdrawInternal(address recipient, uint256 amount)
        internal
        virtual
        override
    {
        IERC20(contractAddress).transfer(recipient, amount);
    }

    function transferToAsset(uint256 amount, uint256[] calldata data) external {
        listener().beforeAssetTransfer(
            address(this),
            msg.sender,
            address(this),
            amount,
            data
        );
        uint256 lastCount = this.count();
        IERC20(contractAddress).transferFrom(msg.sender, address(this), amount);
        listener().afterAssetTransfer(
            address(this),
            msg.sender,
            address(this),
            this.count() - lastCount,
            data
        );
    }

    function clone(address owner) external override returns (IAsset) {
        return factory.clone(address(this), owner);
    }

    function assetTypeId() external pure override returns (uint256) {
        return 2;
    }
}