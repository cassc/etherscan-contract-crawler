/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;



// Part: IPhutureIndex

/// @title Interface for Phuture indices
interface IPhutureIndex{
    /// @notice Provides the anatomy of an index including assets and weights
    function anatomy() external view returns (address[] memory _assets, uint8[] memory _weights);
    /// @notice Provides the vToken factory for a given index
    function vTokenFactory() external view returns(address);
    /// @notice Provides an array of inactive assets for a given index
    function inactiveAnatomy() external view returns (address[] memory);
    }

// Part: IVToken

/// @title Interface for vTokens
interface IVToken {
    /// @notice Function that returns the total supply of an asset in the vToken contract including any interest earned on Yearn
    function virtualTotalAssetSupply() external view returns (uint);
}

// Part: IVTokenFactory

/// @title Interface for vTokenFactory
interface IVTokenFactory{
    /// @notice Provides the vToken contract address for a given asset
    function vTokenOf(address) external view returns(address);
}

// File: indexComponents.sol

/// @title Obtains contract address and balances of each asset within a given Phuture index
/// @notice This contract is to be used for 3rd party data integrations
contract IndexComponents {

    struct componentStruct {
        address assetAddress;
        uint256 balance;
    }
    /// @notice Retrieve the active and inactive assets from the index
    /// @param index The index which you are interested in retrieving the assets for
    /// @return Array of contract addresses for each asset in the index
    function callActiveAndInactiveAnatomy(address index) internal view returns(address[] memory){
        IPhutureIndex indexContract = IPhutureIndex(index);
        (address[] memory assets ,) = indexContract.anatomy();
        address[] memory inactiveAssets = indexContract.inactiveAnatomy();
        address[] memory allAssets = new address[](assets.length+inactiveAssets.length);

        for(uint i; i < assets.length;i++){
            allAssets[i] = assets[i];
        }
        for (uint i; i < inactiveAssets.length; i++){
            allAssets[i+assets.length] = inactiveAssets[i];
        }
        return allAssets;
        
    }
    /// @notice Retrieve the address of the vToken factory
    /// @param index The index for which you want the vToken factory for
    /// @return Address of vToken factory
    function getVTokenFactory(address index) internal view returns (address){
        IPhutureIndex indexContract = IPhutureIndex(index);
        return indexContract.vTokenFactory();
    }
    /// @notice Retrieve the address of the vToken contract for a specified asset
    /// @param index The index related to the vToken contract
    /// @param asset The underlying asset of the index for which you want to find the vToken contract
    /// @return Address of the vToken contract
    function getVTokenOf(address index, address asset) internal view returns(address){
        IVTokenFactory vTokenFactory = IVTokenFactory(getVTokenFactory(index));
        return vTokenFactory.vTokenOf(asset);
    }
    /// @notice Retrieve the contract address and balance of each token held by the index
    /// @param index Specify the index which you want to find the underlying components for
    /// @return components An array of componentStructs each holding a contract address and balance in WEI
    function getComponents(address index) public view returns(componentStruct[] memory){
        address[] memory underlyingAssetAddresses = callActiveAndInactiveAnatomy(index);
        componentStruct[] memory components = new componentStruct[](underlyingAssetAddresses.length);
        
        for (uint i=0;i<underlyingAssetAddresses.length;i++){
            address _vTokenasset = getVTokenOf(index, underlyingAssetAddresses[i]);
            IVToken _vToken = IVToken(_vTokenasset);
            uint256 _vTokenBalance = _vToken.virtualTotalAssetSupply();
            components[i] =  componentStruct({
                assetAddress:underlyingAssetAddresses[i],
                balance:_vTokenBalance});  
        }
        return components;
    }
    }