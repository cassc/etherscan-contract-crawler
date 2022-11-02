// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    CallExecutorV2.sol :: 0x6FE756B9C61CF7e9f11D96740B096e51B64eBf13
 *    etherscan.io verified 2022-11-01
 */ 

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @dev Used as a proxy for call execution to obscure msg.sender of the
 * caller. msg.sender will be the address of the CallExecutor contract.
 *
 * Instances of Proxy (user account contracts) use CallExecutor to execute
 * unsigned data calls without exposing themselves as msg.sender. Users can
 * sign messages that allow public unsigned data execution via CallExecutor
 * without allowing public calls to be executed directly from their Proxy
 * contract.
 *
 * This is implemented specifically for swap calls that allow unsigned data
 * execution. If unsigned data was executed directly from the Proxy contract,
 * an attacker could make a call that satisfies the swap required conditions
 * but also makes other malicious calls that rely on msg.sender. Forcing all
 * unsigned data execution to be done through a CallExecutor ensures that an
 * attacker cannot impersonate the users's account.
 *
 * ReentrancyGuard is implemented here to revert on callbacks to any verifier
 * functions that use CallExecutorV2.proxyCall()
 * 
 * CallExecutorV2 is modified from https://github.com/brinktrade/brink-verifiers/blob/985900cb405e4d59e37258416d68f36ac443481f/contracts/External/CallExecutor.sol
 * This version adds ReentrancyGuard and removes the data return so that the
 * nonReentrant modifier always unlocks the guard at the end of the function
 *
 */
contract CallExecutorV2 is ReentrancyGuard {

  constructor () ReentrancyGuard() {}

  /**
   * @dev A payable function that executes a call with `data` on the
   * contract address `to`
   *
   * Sets value for the call to `callvalue`, the amount of Eth provided with
   * the call
   */
  function proxyCall(address to, bytes memory data) external payable nonReentrant() {
    // execute `data` on execution contract address `to`
    assembly {
      let result := call(gas(), to, callvalue(), add(data, 0x20), mload(data), 0, 0)
      returndatacopy(0, 0, returndatasize())
      if eq(result, 0) { revert(0, returndatasize()) }
    }
  }
}