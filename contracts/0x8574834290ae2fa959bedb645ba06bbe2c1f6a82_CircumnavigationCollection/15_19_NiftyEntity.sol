pragma solidity 0.8.4;

/**
 * @dev Authenticator of state mutating operations for Nifty Gateway contracts. 
 *
 * addresses for stateful operations. 
 *
 * Rinkeby: 0xCefBf44ff649B6E0Bc63785699c6F1690b8cF73b
 * Mainnet: 0x6e53130dDfF21E3BC963Ee902005223b9A202106
 */
contract NiftyEntity {
   
   // Address of {NiftyRegistry} contract. 
   address internal immutable niftyRegistryContract;
   
   /**
    * @dev Determines whether accounts are allowed to invoke state mutating operations on child contracts.
    */
    modifier onlyValidSender() {
        NiftyRegistry niftyRegistry = NiftyRegistry(niftyRegistryContract);
        bool isValid = niftyRegistry.isValidNiftySender(msg.sender);
        require(isValid, "NiftyEntity: Invalid msg.sender");
        _;
    }
    
   /**
    * @param _niftyRegistryContract Points to the repository of authenticated
    */
    constructor(address _niftyRegistryContract) {
        niftyRegistryContract = _niftyRegistryContract;
    }
}

/**
 * @dev Defined to mediate interaction with externally deployed {NiftyRegistry} dependency. 
 */
interface NiftyRegistry {
   function isValidNiftySender(address sending_key) external view returns (bool);
}