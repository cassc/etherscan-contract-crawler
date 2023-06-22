// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Batch Worker 

import "SafeERC20.sol";
import "ITrustedWrapperV2.sol";
import "IERC20Extended.sol";
import "ServiceProviderOwnable.sol";



pragma solidity 0.8.19;

contract BatchWorkerV2 is  ServiceProviderOwnable {
    using SafeERC20 for IERC20Extended;

    ITrustedWrapperV2 public trustedWrapper;
    
    constructor (address _subscrRegistry) 
        ServiceProviderOwnable(_subscrRegistry)
    {}

    function wrapBatch(
        ETypes.INData[] calldata _inDataS, 
        ETypes.AssetItem[] calldata _collateralERC20,
        address[] memory _receivers
    ) public payable {
        _checkAndFixSubscription(msg.sender);
        require(
            _inDataS.length == _receivers.length, 
            "Array params must have equal length"
        );
        // make wNFTs
        for (uint256 i = 0; i < _inDataS.length; i++) {
            // wrap
            trustedWrapper.wrapUnsafe{value: (msg.value / _receivers.length)}(
                _inDataS[i],
                _collateralERC20,
                _receivers[i]
            );
            
            // Transfer original NFTs  to wrapper
            if (_inDataS[i].inAsset.asset.assetType == ETypes.AssetType.ERC721 ||
                _inDataS[i].inAsset.asset.assetType == ETypes.AssetType.ERC1155 ) 
            {
                trustedWrapper.transferIn(
                    _inDataS[i].inAsset, 
                    msg.sender
                );
            }
        }

        ETypes.AssetItem memory totalERC20Collateral;
        uint256 totalNativeAmount;
        for (uint256 i = 0; i < _collateralERC20.length; i ++) {

            if (_collateralERC20[i].asset.assetType == ETypes.AssetType.ERC20) {
            
                totalERC20Collateral.asset.assetType = _collateralERC20[i].asset.assetType;
                totalERC20Collateral.asset.contractAddress = _collateralERC20[i].asset.contractAddress; 
                totalERC20Collateral.tokenId = _collateralERC20[i].tokenId;
                // We need construct totalERC20Collateral due make one transfer
                // instead of maked wNFT counts
                totalERC20Collateral.amount = _collateralERC20[i].amount * _receivers.length;
                
                uint256 amountTransfered = trustedWrapper.transferIn(
                   totalERC20Collateral, 
                    msg.sender
                );
                require(amountTransfered == totalERC20Collateral.amount, "Check transfer ERC20 amount fail");
                
            }

            if (_collateralERC20[i].asset.assetType == ETypes.AssetType.NATIVE) {
                    totalNativeAmount += _collateralERC20[i].amount * _receivers.length;    
                } 
        }

        require(totalNativeAmount == msg.value,  "Native amount check failed");
    }


    function addCollateralBatch(
        address[] calldata _wNFTAddress, 
        uint256[] calldata _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateralERC20
    ) public payable {
        _checkAndFixSubscription(msg.sender);
        require(_wNFTAddress.length == _wNFTTokenId.length, "Array params must have equal length");
        
        for (uint256 i = 0; i < _collateralERC20.length; i ++) {
            if (_collateralERC20[i].asset.assetType == ETypes.AssetType.ERC20) {
                // 1. Transfer all erc20 tokens to BatchWorker        
                IERC20Extended(_collateralERC20[i].asset.contractAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _collateralERC20[i].amount * _wNFTAddress.length
                );
                // 2. approve for spending to wrapper
                IERC20Extended(_collateralERC20[i].asset.contractAddress).safeIncreaseAllowance(
                    address(trustedWrapper),
                    _collateralERC20[i].amount * _wNFTAddress.length
                );
            }
        }

            
        uint256 valuePerWNFT = msg.value / _wNFTAddress.length;
        for (uint256 i = 0; i < _wNFTAddress.length; i ++){
            trustedWrapper.addCollateral{value: valuePerWNFT}(
                _wNFTAddress[i],
                _wNFTTokenId[i],
                _collateralERC20
            );
        }

        if (valuePerWNFT * _wNFTAddress.length < msg.value ){
            address payable s = payable(msg.sender);
            s.transfer(msg.value - valuePerWNFT * _wNFTAddress.length);
        }
    }

    ////////////////////////////////////////
    //     Admin functions               ///
    ////////////////////////////////////////
    function setTrustedWrapper(address _wrapper) public onlyOwner {
        trustedWrapper = ITrustedWrapperV2(_wrapper);
        require(trustedWrapper.trustedOperator(address(this)), "Only for exact wrapper");
    }

        
    /////////////////////////////////////////////////////////////////////

    function checkUser(address _user) external view returns (bool ok, bool needFix) {
        return _checkUserSubscription(_user); 

    }
    
}