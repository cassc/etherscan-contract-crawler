// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './SummonUtils.sol';

contract Summon is SummonUtils {
  address public owner;
  address public SummonManager;
  // mapping(bytes => address) public storedTokens; // lender => (contract,tokenID) 

  // constructor(address _owner ) {
  //     owner = _owner;
  //     SummonFactory = msg.sender;
  // }



function init(address _owner) external {
    require(owner == address(0) && SummonManager == address(0));
    owner = _owner;
    SummonManager = msg.sender;
}




  function safeWithdraw(address tokenAddress, uint256 tokenId, address lender) public returns(bool success, bytes memory data) {
    require(msg.sender == SummonManager, "can only be called by Summon Manager");
    (success, data) = tokenAddress.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)",address(this),lender,tokenId));
    require(success, "call failed");
  }


  function isValidSignature(
    bytes32 _hash,
    bytes calldata _signature
  ) external view returns (bytes4) {
   // Validate signatures
   if ((recoverSigner(_hash, _signature)) == owner) {
     return 0x1626ba7e;
   } else {
     return 0xffffffff;
   }
  }


}