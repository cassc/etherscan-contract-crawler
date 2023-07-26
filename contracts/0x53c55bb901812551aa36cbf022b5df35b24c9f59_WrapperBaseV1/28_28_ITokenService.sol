// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. 
pragma solidity 0.8.13;

import "LibEnvelopTypes.sol";


interface ITokenService {

    error UnSupportedAsset(ETypes.AssetItem asset);
	
	function mintNFT(
        ETypes.AssetType _mint_type, 
        address _contract, 
        address _mintFor, 
        uint256 _tokenId, 
        uint256 _outBalance
    ) 
        external;
    

    function burnNFT(
        ETypes.AssetType _burn_type, 
        address _contract, 
        address _burnFor, 
        uint256 _tokenId, 
        uint256 _balance
    ) 
        external; 

    function transfer(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) external  returns (bool _transfered);

    function transferSafe(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) external  returns (uint256 _transferedValue);

    // This function must never revert. Use it for unwrap in case some 
    // collateral transfers are revert
    function transferEmergency(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) external  returns (uint256 _transferedValue);
}