// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RightsHub is Ownable {  

  /**
   * @dev Emitted when rights are declared for tokens of contract `contractAddr`
   */
  event RightsDeclaration(address indexed contractAddr, address indexed declarer, address indexed registrar, string rightsManifest);

  // Indicates if allow list is active or not
  bool private _useAllowlist;
  
  // List of contract addresses that can call this contract
  mapping(address => bool) _allowlist;

  constructor() {
    _useAllowlist = true;
  }
 
  /*
   * Returns a boolean indicating if allow list is enabled
   */
  function useAllowlist() public view returns (bool) {
    return _useAllowlist;
  }

  /*
   * Disable allow list 
   */
  function disableAllowlist() public onlyOwner {
    _useAllowlist = false;
  }

  /*
   * Enable allowlist 
   */
  function enableAllowlist() public onlyOwner {
    _useAllowlist = true;
  }

  /*
   * Add address to allowed list
   */
  function addAllowed(address addr) public onlyOwner {
    _allowlist[addr] = true;
  }
  
  /*
   * Remove address from allowed list
   */
  function removeAllowed(address addr) public onlyOwner {
    _allowlist[addr] = false;
  }

  /*
   * Throws error if caller is not in the allowed list
   */
  modifier onlyAllowed() {
    if (_useAllowlist) {
      require(_allowlist[msg.sender] == true || _allowlist[tx.origin] == true, "RightsHub: caller is not in allow list");
    }
    _;
  }

  /*
   * Declare Rights for NFTs in the Smart Contract
   */
  function declareRights(address contractAddr, address declarer, string calldata rightsManifest) public onlyAllowed {
    require(tx.origin != msg.sender, "RightsHub: declareRights() can only be called by Smart Contracts");
    require(bytes(rightsManifest).length > 0, "RightsHub: Rights Manifest can not be empty");
    
    // Emit event
    emit RightsDeclaration(contractAddr, declarer, msg.sender, rightsManifest);
  }
}