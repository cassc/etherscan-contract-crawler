//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import './ProxyApprovable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

/** @title LiquidationManager */
contract ProtocolExecutionManager is 
  ProxyApprovable, 
  Ownable 
{
  mapping(address => bool) whitelistedProtocols;
  mapping(address => mapping(bytes4 => bool)) whitelistedProtocolMethods;

  modifier onlySafeProtocols(
    address protocolAddress, 
    bytes[] calldata encodedProtocolCalls
  ) {
    require(
      protocolAddress != address(this),
      "Recursive calls not allowed"
    );
    require(
      whitelistedProtocols[protocolAddress], 
      "Only whitelisted protocols allowed"
    );

    for (uint256 i=0; i<encodedProtocolCalls.length; i++) {
      bytes calldata encodedCalldata = encodedProtocolCalls[i];
      require(
        encodedCalldata.length >= 4, 
        'Protocol calldata requires valid method'
      );
      require(
        whitelistedProtocolMethods[protocolAddress][bytes4(encodedCalldata[:4])],
        'Only whitelisted methods for protocol'
      );
    }
    _;
  }

  struct ProtocolExecutionParams {
    address protocolAddress;
    bytes[] encodedProtocolCalls;
  }

  function whitelistProtocol(address protocolAddress) public onlyOwner {
    whitelistedProtocols[protocolAddress] = true;
  }

  function whitelistMethodForProtocol(address protocolAddress, bytes4 sighash) public onlyOwner {
    whitelistedProtocolMethods[protocolAddress][sighash] = true;
  }

  /**
   * @dev Allow a proxy to withdraw payment token from contract
   *
   * @param proxyAddress        The address of the proxy that needs approvals
   * @param tokenAddress        The token address of the payment currency
   */
  function allowProxyToWithdrawPayment(address proxyAddress, address tokenAddress) public onlyOwner {
    checkAndSetProxyApprovalERC20(proxyAddress, tokenAddress);
  }

  function bulkExecuteProtocols(
    ProtocolExecutionParams[] calldata protocols
  ) internal {

    for (uint256 i=0; i<protocols.length; i++) {
      executeProtocolCalls(protocols[i]);
    }
  }

  function executeProtocolCalls(
    ProtocolExecutionParams calldata protocolExecution
  ) private 
    onlySafeProtocols(
      protocolExecution.protocolAddress,
      protocolExecution.encodedProtocolCalls
    )
  {

    for (uint256 i=0; i<protocolExecution.encodedProtocolCalls.length; i++) {
      bytes calldata encodedCalldata = protocolExecution.encodedProtocolCalls[i];
      executeProtocolCall(protocolExecution.protocolAddress, encodedCalldata);
    }
  }

  function executeProtocolCall(
    address protocolAddress,
    bytes calldata encodedCalldata
  ) private
  {
    (bool success, bytes memory result) = protocolAddress.call(encodedCalldata);
    if (success == false) {
        assembly {
          revert(add(result,32), mload(result))
        }
    }
  }

}