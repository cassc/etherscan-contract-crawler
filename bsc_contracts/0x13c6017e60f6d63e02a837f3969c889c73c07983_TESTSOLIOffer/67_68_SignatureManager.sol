/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./base/ISignatureManager.sol";

/**
 * @dev Asset Manager
 * @notice Signature Manager administra permissionamento por múltiplas assinaturas in-chain.
 **/
contract SignatureManager is Ownable, ISignatureManager {
    // 
    struct Asset {
        mapping(address => uint8) mapSigners;
        uint256 nTotalSigned;
        uint256 nNeededSigners;
    }

    // Address-permission access map
    mapping(address => Asset) private mapAssets;

    /**
     * @dev Enables access to the specified address
     * @param _assetAddress Address to enable access
     * @notice Registra um asset no contrato, e os endereços que podem assinar esse asset
     */
    function registerAsset(
        address _assetAddress,
        uint256 _neededSigners,
        address[] calldata _signers
    ) external onlyOwner {
        // check if the address is empty
        require(_assetAddress != address(0), "Asset address is empty");

        // make sure we have not registered this address yet
        require(
            mapAssets[_assetAddress].nNeededSigners == 0,
            "Already registered asset"
        );

        // minimum must be smaller than total signers
        require(
            _neededSigners <= _signers.length,
            "Minimum is bigger than total signers"
        );

        // get the pointer to the asset
        Asset storage asset = mapAssets[_assetAddress];

        // save how many signatures are needed
        asset.nNeededSigners = _neededSigners;

        // loop through all signers and register them on the map
        for (uint256 i = 0; i < _signers.length; i++) {
            address aSigner = _signers[i];
            require(aSigner != address(0x0), "Signer address is empty");
            
            // statuses:
            // 0: not a signer
            // 1: is a signer, not signed
            // 2: signed
            asset.mapSigners[aSigner] = 1;
        }
    }

    /**
     * @dev Signs an asset at the specified address. Only pre-set addresses will be allowed to complete the transaction
     * @param _assetAddress Address to enable access
     * @notice Assina um asset no endereço especificado. Somente endereços pré-cadastrados poderão completar a transação
     */
    function signAsset(address _assetAddress) public {
        require(_assetAddress != address(0), "Address is empty");

        // get the pointer to the asset
        Asset storage asset = mapAssets[_assetAddress];

        // cache sender address
        address aSender = _msgSender();

        // get the status for the sender
        uint8 nStatus = asset.mapSigners[aSender];

        // do not allow if sender is not a signer
        require(nStatus != 0, "Sender is not a signer for the specified asset");

        // do not allow if sender has already signed
        require(nStatus != 2, "Sender already signed the asset");

        // mark the asset as signed
        asset.mapSigners[aSender] = 2;

        // increase the total amount of signatures
        asset.nTotalSigned++;
    }

    /**
     * @dev Checks if the specified address is signed
     * @param _assetAddress Address to enable access
     * @notice Checa se o endereço espeficiado foi assinado
     */
    function isSigned(address _assetAddress) public override view returns (bool) {
        Asset memory asset = mapAssets[_assetAddress];

        // if more than minimum, and not 0
        return asset.nNeededSigners > 0 && asset.nTotalSigned >= asset.nNeededSigners;
    }
}