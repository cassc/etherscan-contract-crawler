//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
//import "truffle/console.sol";
/**                                            
       
             ___           ___           ___                         ___           ___         ___           ___                   
     /\  \         /\__\         /\  \                       /\  \         /\  \       /\  \         /\  \                  
    |::\  \       /:/ _/_        \:\  \         ___         /::\  \       /::\  \     /::\  \       /::\  \         ___     
    |:|:\  \     /:/ /\__\        \:\  \       /\__\       /:/\:\  \     /:/\:\__\   /:/\:\  \     /:/\:\__\       /\__\    
  __|:|\:\  \   /:/ /:/ _/_   _____\:\  \     /:/  /      /:/ /::\  \   /:/ /:/  /  /:/  \:\  \   /:/ /:/  /      /:/  /    
 /::::|_\:\__\ /:/_/:/ /\__\ /::::::::\__\   /:/__/      /:/_/:/\:\__\ /:/_/:/  /  /:/__/ \:\__\ /:/_/:/__/___   /:/__/     
 \:\~~\  \/__/ \:\/:/ /:/  / \:\~~\~~\/__/  /::\  \      \:\/:/  \/__/ \:\/:/  /   \:\  \ /:/  / \:\/:::::/  /  /::\  \     
  \:\  \        \::/_/:/  /   \:\  \       /:/\:\  \      \::/__/       \::/__/     \:\  /:/  /   \::/~~/~~~~  /:/\:\  \    
   \:\  \        \:\/:/  /     \:\  \      \/__\:\  \      \:\  \        \:\  \      \:\/:/  /     \:\~~\      \/__\:\  \   
    \:\__\        \::/  /       \:\__\          \:\__\      \:\__\        \:\__\      \::/  /       \:\__\          \:\__\  
     \/__/         \/__/         \/__/           \/__/       \/__/         \/__/       \/__/         \/__/           \/__/  
       
       
                                                
**/

/**
 * @title MentaportVerify
 * @dev Contract allows function to be restricted to users that posess 
 * signed authorization from the owner of the contract. This signed
 * message includes the user to give permission to and the contract address to prevent
 * reusing the same authorization message on different contract with same owner. 
**/

contract MentaportVerify is AccessControl {

  /** @dev Mentaport role is only controlled by Mentaport */
  bytes32 public constant MENTAPORT_ADMIN = keccak256("MENTAPORT_ADMIN");
  bytes32 public constant MENTAPORT_ROLE = keccak256("MENTAPORT_ROLE");
  /** @dev Contract admin role is controlled by Mentaport + Owner
  *  - pause / unpause contract
  *  - Update token URIs (base and unrevealded)
  *  - reveal token URI
  **/
  bytes32 public constant CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");
  bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
 /** @dev Signature role is controlled by CONTRACT_ADMIN 
 *   Only accounts that its signature can be verified.
 */
  bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
  /** @dev Minter role to control minting outside minting payed function 
  *  - preMinting
  *  - mintByaddress
  * Controled by MENTAPORT_ADMIN
  **/
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
 
  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    // Admin role for mentaport and minter is mentaport admin
    _setRoleAdmin(MENTAPORT_ROLE, MENTAPORT_ADMIN);
    _setRoleAdmin(MINTER_ROLE, MENTAPORT_ADMIN);
    // Contract and signer role admin is owner()
    _setRoleAdmin(CONTRACT_ROLE, CONTRACT_ADMIN);
    _setRoleAdmin(SIGNER_ROLE, CONTRACT_ADMIN);
  }

  //----------------------------------------------------------------------------
  // Modifiers 
  /**
  * @dev Throws if called by any account other than contract admin role
  */
  modifier onlyContractAdmin() {
    _checkContractAdmin();
    _;
  }
  /**
  * @dev Throws if called by any account other than a minter role
  */
  modifier onlyMinter() {
    _checkMinter();
    _;
  }

  modifier onlyValidMessage(uint _timestamp, uint256 _rule, bytes memory _signature) 
  {
    require(isValidSigner(msg.sender, _timestamp, _rule, _signature), "Wrong signature");
    _;
  }

  modifier onlyValidSigner(address signer, uint _timestamp, uint256 _rule, bytes memory _signature)
  {
    require(isValidSigner(signer, _timestamp, _rule, _signature), "Invalid signer");
    _;
  }


  //----------------------------------------------------------------------------
  // Public functions that are View
  // Verifies if message was signed by owner to give access to _add for this contract.
  function isValidSigner(
    address _account,
    uint _timestamp,
    uint256 _rule,
    bytes memory _signature)
  view public returns (bool)
  {
    bytes32 hash = keccak256(abi.encodePacked(address(this), _account, _timestamp, _rule));
    bytes32 message = ECDSA.toEthSignedMessageHash(hash);

    (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(message, _signature);
    require(error == ECDSA.RecoverError.NoError, "Signature Error");
    return hasRole(SIGNER_ROLE, recovered);
  }

  //----------------------------------------------------------------------------
  // Internal functions
  /**
  * @dev Throws if the sender is not an admin.
  */
  function _checkContractAdmin() internal view {
    require(hasRole(CONTRACT_ROLE, msg.sender), "Caller is not contract admin");
  }
  /**
  * @dev Throws if the sender is not a minter.
  */
  function _checkMinter() internal view {
    require(hasRole(MINTER_ROLE, msg.sender), "Caller is not minter");
  }
}