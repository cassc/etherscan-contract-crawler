// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Wrapper - Checker
pragma solidity 0.8.16;

import "Ownable.sol";
import "IWrapper.sol";
import "IChecker.sol";
import "IAdvancedWhiteList.sol";
import "LibEnvelopTypes.sol";

contract CheckerExchange is Ownable, IChecker {

    mapping(address => bool) public trustedMultisigs;
    function isWrapEnabled(
        address caller,
        ETypes.INData      calldata _inData, 
        ETypes.AssetItem[] calldata _collateral, 
        address _wrappFor
    ) external view returns (bool) 
    {
        bool isOk;

        // 1. Time Lock must have
        for (uint256 i = 0; i < _inData.locks.length; ++i ){
            if (_inData.locks[i].lockType == 0x00 && _inData.locks[i].param > 0) {
                isOk = true;
                break;
            }

        }
        require(isOk, 'No Time Lock found');
        isOk = false; 

        // 2. Rules: no transfer
        require(
            bytes2(0x0004) ==_inData.rules & bytes2(0x0004)
            ,'NoTransfer rule not set'
        );

        // 3. Check that trusted multisig exist in royalty address
        for (uint256 i = 0; i < _inData.royalties.length; ++ i){
            if (!trustedMultisigs[_inData.royalties[i].beneficiary]){
                isOk = false;
                break;
            } else {
                isOk = true;
            }
        }
        require(isOk, 'Trusted multisig not found in royalty');
        isOk = false;

        return true;
    }
    
    function isRemoveEnabled(
        address caller,
        address _wNFTAddress, 
        uint256 _wNFTTokenId,
        address _collateralAddress,
        uint256 _removeAmount
    ) external view returns (bool) 
    {
        ETypes.WNFT memory wnft = IWrapper(msg.sender).getWrappedToken(_wNFTAddress, _wNFTTokenId);
        bool isOk;
        // 1. Lets check original msg sender
        for (uint256 i = 0; i < wnft.royalties.length; ++ i){
            if (wnft.royalties[i].beneficiary == caller){
                isOk = true;
            }
        }
        require(isOk, 'Sender is not in beneficiary list');
        
        
        // 2. Check whitelist flag
        isOk = false;
        isOk = IAdvancedWhiteList(
            IWrapper(msg.sender).protocolWhiteList()
        ).enabledRemoveFromCollateral(_collateralAddress);
        require(isOk, 'Collateral not available for remove');
        
        return true;
    }

    /////////////////////////////////////////////////////////////////////
    //                    Admin functions                              //
    /////////////////////////////////////////////////////////////////////

    function setTrustedAddress(address _operator, bool _status) public onlyOwner {
        trustedMultisigs[_operator] = _status;
    }

}