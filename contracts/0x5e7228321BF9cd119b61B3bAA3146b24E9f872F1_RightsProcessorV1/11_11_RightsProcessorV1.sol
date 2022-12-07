// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RightsDeclarationForwarder.sol";
import "./RightsHub.sol";

contract RightsProcessorV1 is ERC2771Context, Ownable {  

  // Address of RightsHub contract
  address internal _hub;

  // Indicates if allow list is active or not
  bool private _useAllowlist;
  
  // List of addresses that can declare rights using this contract
  mapping(address => bool) _allowlist;

  /*
   * Constructor
   * Initialize trusted forwarder
   */
  constructor(RightsDeclarationForwarder forwarder, address hub_)
    ERC2771Context(address(forwarder)) {
    _hub = hub_;
    _useAllowlist = true;
  }

  /*
   * It's necessary to override this function because it's present in more than one ancestor
   */
  function _msgSender() internal view override(Context, ERC2771Context)
    returns (address sender) {
    sender = ERC2771Context._msgSender();
  }

  /*
   * It's necessary to override this function because it's present in more than one ancestor
   */
  function _msgData() internal view override(Context, ERC2771Context)
    returns (bytes calldata) {
    return ERC2771Context._msgData();
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
   * Enable allow list 
   */
  function enableAllowlist() public onlyOwner {
    _useAllowlist = true;
  }

  /*
   * Add address to the allow list
   */
  function addAllowed(address addr) public onlyOwner {
    _allowlist[addr] = true;
  }

  /*
   * Remove address from the allow list
   */
  function removeAllowed(address addr) public onlyOwner {
    _allowlist[addr] = false;
  }
  
  /*
   * Throws error if initiator of transaction (`tx.origin`) is not in the allow list
   */
  modifier onlyAllowed() {
    if (_useAllowlist) {
      require(_allowlist[tx.origin] == true, "RightsProcessorV1: caller is not in allow list");
    }
    _;
  }
  
  /*
   * Declare rights for tokens in a NFT Smart Contract
   * _msgSender() = Declarer (signer of the transaction or signer of meta-transaction) 
   */
  function declareRights(address contractAddr, string calldata rightsURI_) public onlyAllowed {
    RightsHub(_hub).declareRights(contractAddr, _msgSender(), rightsURI_);
  }
}