pragma solidity ^0.8.17;
import 'contracts/position_trading/assets/AssetBase.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import 'contracts/position_trading/PositionSnapshot.sol';
import 'contracts/interfaces/position_trading/IPositionAlgorithm.sol';
import 'contracts/interfaces/assets/typed/IErc721ItemAsset.sol';

contract Erc721ItemAsset is AssetBase, IErc721ItemAsset {
    address contractAddress;
    uint256 tokenId;

    constructor(
        address owner_,
        IAssetCloneFactory factory_,
        address contractAddress_,
        uint256 tokenId_
    ) AssetBase(owner_, factory_) {
        contractAddress = contractAddress_;
        tokenId = tokenId_;
    }

    function getContractAddress() external view override returns (address) {
        return contractAddress;
    }

    function getTokenId() external view override returns (uint256) {
        return tokenId;
    }

    function count() external view override returns (uint256) {
        return
            IERC721(contractAddress).ownerOf(tokenId) == address(this) ? 1 : 0;
    }

    function withdrawInternal(address recipient, uint256 amount)
        internal
        virtual
        override
    {
        if (amount == 0) return;
        require(amount == 1);
        IERC721(contractAddress).transferFrom(
            address(this),
            recipient,
            tokenId
        );
    }

    function transferToAsset(uint256[] calldata data)
        external
    {
        listener().beforeAssetTransfer(
            address(this),
            msg.sender,
            address(this),
            1,
            data
        );
        IERC721(contractAddress).transferFrom(msg.sender, address(this), tokenId);
        listener().afterAssetTransfer(
            address(this),
            msg.sender,
            address(this),
            1,
            data
        );
    }

    function clone(address owner) external override returns (IAsset) {
        return factory.clone(address(this), owner);
    }

    function assetTypeId() external pure override returns (uint256) {
        return 3;
    }
}