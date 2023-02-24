// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Wrapper - main protocol contract
pragma solidity 0.8.16;

import "TokenService.sol";

abstract contract TokenServiceExtended is TokenService {
	

    function _balanceOf(
        ETypes.AssetItem memory _assetItem,
        address _holder
    ) internal view virtual returns (uint256 _balance){
        if (_assetItem.asset.assetType == ETypes.AssetType.NATIVE) {
            _balance = _holder.balance;
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC20) {
            _balance = IERC20Extended(_assetItem.asset.contractAddress).balanceOf(_holder);
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC721) {
            _balance = IERC721Mintable(_assetItem.asset.contractAddress).balanceOf(_holder); 
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC1155) {
            _balance = IERC1155Mintable(_assetItem.asset.contractAddress).balanceOf(_holder, _assetItem.tokenId);
        } else {
            revert UnSupportedAsset(_assetItem);
        }
    }

    function _ownerOf(
        ETypes.AssetItem memory _assetItem
    ) internal view virtual returns (address _owner){
        if (_assetItem.asset.assetType == ETypes.AssetType.NATIVE) {
            _owner = address(0);
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC20) {
            _owner = address(0);
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC721) {
            _owner = IERC721Mintable(_assetItem.asset.contractAddress).ownerOf(_assetItem.tokenId); 
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC1155) {
            _owner = address(0);
        } else {
            revert UnSupportedAsset(_assetItem);
        }
    }
}