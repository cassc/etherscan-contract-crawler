// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/*           
                                                                                                                                                                                                                                                                                   
  ,----..                                                 ____                        ___     
 /   /   \                                              ,'  , `. ,--,               ,--.'|_   
|   :     : __  ,-.  ,---.                           ,-+-,.' _ ,--.'|        ,---,  |  | :,'  
.   |  ;. ,' ,'/ /| '   ,'\  .--.--.   .--.--.    ,-+-. ;   , ||  |,     ,-+-. /  | :  : ' :  
.   ; /--`'  | |' |/   /   |/  /    ' /  /    '  ,--.'|'   |  |`--'_    ,--.'|'   .;__,'  /   
;   | ;   |  |   ,.   ; ,. |  :  /`./|  :  /`./ |   |  ,', |  |,' ,'|  |   |  ,"' |  |   |    
|   : |   '  :  / '   | |: |  :  ;_  |  :  ;_   |   | /  | |--''  | |  |   | /  | :__,'| :    
.   | '___|  | '  '   | .; :\  \    `.\  \    `.|   : |  | ,   |  | :  |   | |  | | '  : |__  
'   ; : .';  : |  |   :    | `----.   \`----.   |   : |  |/    '  : |__|   | |  |/  |  | '.'| 
'   | '/  |  , ;   \   \  / /  /`--'  /  /`--'  |   | |`-'     |  | '.'|   | |--'   ;  :    ; 
|   :    / ---'     `----' '--'.     '--'.     /|   ;/         ;  :    |   |/       |  ,   /  
 \   \ .'                    `--'---'  `--'---' '---'          |  ,   /'---'         ---`-'   
  `---`                                                         ---`-'                        
                                                                                              
*/

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

/**
 * @title MintAPIFactory
 * @dev This contract deploys NFT and SFT collections using the beacon pattern.
 */

contract MintAPIFactory {
    IBeacon public nftBeacon;
    IBeacon public sftBeacon;

    /**
     * @dev Represents the type of the contract to be deployed - NFT or SFT
     */
    enum ContractType {
        defaultNFT,
        defaultSFT
    }

    /**
     * @dev Emits when a new NFT or SFT collection is deployed.
     * @param deployer The address deploying the new collection.
     * @param contractAddress The address of the newly deployed collection.
     * @param contractType The type of the contract deployed (NFT or SFT).
     * @param initialVersion The initial version of the deployed contract.
     */
    event CollectionDeployed(
        address indexed deployer,
        address indexed contractAddress,
        ContractType contractType,
        string initialVersion
    );

    /**
     * @dev Initialize the contract with the NFT and SFT beacon addresses.
     * @param _nftBeacon The NFT beacon address.
     * @param _sftBeacon The SFT beacon address.
     */
    constructor(IBeacon _nftBeacon, IBeacon _sftBeacon) {
        nftBeacon = _nftBeacon;
        sftBeacon = _sftBeacon;
    }

    /**
     * @dev Deploys a new NFT collection.
     * @param initData data for the initialization function
     * @param salt The salt for creating the BeaconProxy using Create2.
     * @return The address of the new NFT collection.
     */
    function deployNFTCollection(
        bytes calldata initData,
        bytes32 salt
    ) public returns (address) {
        BeaconProxy proxy = new BeaconProxy{salt: salt}(address(nftBeacon), "");

        (bool success, ) = address(proxy).call(initData);
        require(success, "Initialization failed");

        emit CollectionDeployed(
            msg.sender,
            address(proxy),
            ContractType.defaultNFT,
            _getInitialDeploymentVersion(proxy)
        );

        return address(proxy);
    }

    /**
     * @dev Deploys a new SFT collection.
     * @param initData data for the initialization function
     * @param salt The salt for creating the BeaconProxy using Create2.
     * @return The address of the new SFT collection.
     */
    function deploySFTCollection(
        bytes calldata initData,
        bytes32 salt
    ) public returns (address) {
        BeaconProxy proxy = new BeaconProxy{salt: salt}(address(sftBeacon), "");

        (bool success, ) = address(proxy).call(initData);
        require(success, "Initialization failed");

        emit CollectionDeployed(
            msg.sender,
            address(proxy),
            ContractType.defaultSFT,
            _getInitialDeploymentVersion(proxy)
        );

        return address(proxy);
    }

    /**
     * @dev Computes the address that a contract will have if deployed by CREATE2.
     * @param salt The salt for creating the BeaconProxy using Create2.
     * @param contractType The type of the contract for which to get the address.
     * @return The address that the contract will have if deployed by CREATE2.
     */
    function getAddress(
        bytes32 salt,
        ContractType contractType
    ) public view returns (address) {
        bytes memory bytecode = _getBytecode(contractType);

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), // a constant that prevents collisions with CREATE
                address(this),
                salt,
                keccak256(bytecode)
            )
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

    /**
     * @dev Gets the bytecode of the BeaconProxy based on the contract type.
     * @param contractType The type of the contract (NFT or SFT).
     * @return The bytecode of the BeaconProxy.
     */
    function _getBytecode(
        ContractType contractType
    ) internal view returns (bytes memory) {
        bytes memory bytecode = type(BeaconProxy).creationCode;

        if (contractType == ContractType.defaultSFT) {
            return
                abi.encodePacked(bytecode, abi.encode(address(sftBeacon), ""));
        } else {
            return
                abi.encodePacked(bytecode, abi.encode(address(nftBeacon), ""));
        }
    }

    /**
     * @dev Gets the initial deployment version of the collection.
     * @param proxy The BeaconProxy contract of the collection.
     * @return The initial deployment version.
     */
    function _getInitialDeploymentVersion(
        BeaconProxy proxy
    ) internal returns (string memory) {
        bytes memory versionData = abi.encodeWithSignature("getVersion()");
        (bool versionSuccess, bytes memory versionResult) = address(proxy).call(
            versionData
        );

        require(
            versionSuccess,
            "getVersion function not found in the contract, check that the beacon is properly setup"
        );

        return abi.decode(versionResult, (string));
    }
}