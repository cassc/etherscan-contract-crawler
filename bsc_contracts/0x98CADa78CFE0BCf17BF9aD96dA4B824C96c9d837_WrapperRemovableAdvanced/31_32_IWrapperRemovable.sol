// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

//import "IERC721Enumerable.sol";
import "IWrapper.sol";

interface IWrapperRemovable is IWrapper  {

    event CollateralRemoved(
        address indexed wrappedAddress,
        uint256 indexed wrappedId,
        uint8   assetType,
        address collateralAddress,
        uint256 collateralTokenId,
        uint256 collateralBalance
    );

    function removeERC20Collateral(
        address _wNFTAddress, 
        uint256 _wNFTTokenId,
        address _collateralAddress
    ) external;
    
    function setTrustedAddress(address _operator, bool _status) external;
   
}