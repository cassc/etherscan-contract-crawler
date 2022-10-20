// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICrossDomainMessenger} from 'governance-crosschain-bridges/contracts/dependencies/optimism/interfaces/ICrossDomainMessenger.sol';
import {IL2BridgeExecutor} from 'governance-crosschain-bridges/contracts/interfaces/IL2BridgeExecutor.sol';

interface ICanonicalTransactionChain {
  function enqueueL2GasPrepaid() external view returns (uint256);
}

/**
 * @title A generic executor for proposals targeting the optimism v3 pool
 * @author BGD Labs
 * @notice You can **only** use this executor when the optimism payload has a `execute()` signature without parameters
 * @notice You can **only** use this executor when the optimism payload is expected to be executed via `DELEGATECALL`
 * @notice You can **only** execute payloads on optimism with up to prepayed gas which is specified in `enqueueL2GasPrepaid` gas.
 * Prepaid gas is the maximum gas covered by the bridge without additional payment.
 * @dev This executor is a generic wrapper to be used with Optimism CrossDomainMessenger (https://etherscan.io/address/0x25ace71c97b33cc4729cf772ae268934f7ab5fa1)
 * It encodes and sends via the L2CrossDomainMessenger a message to queue for execution an action on L2, in the Aave OPTIMISM_BRIDGE_EXECUTOR.
 */
contract CrosschainForwarderOptimism {
  /**
   * @dev The L1 Cross Domain Messenger contract sends messages from L1 to L2, and relays messages
   * from L2 onto L1. In this contract it's used by the governance SHORT_EXECUTOR to send the encoded L2 queuing over the bridge.
   */
  address public constant L1_CROSS_DOMAIN_MESSENGER_ADDRESS =
    0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;

  /**
   * @dev The optimism bridge executor is a L2 governance execution contract.
   * This contract allows queuing of proposals by allow listed addresses (in this case the L1 short executor).
   * https://optimistic.etherscan.io/address/0x7d9103572bE58FfE99dc390E8246f02dcAe6f611
   */
  address public constant OPTIMISM_BRIDGE_EXECUTOR =
    0x7d9103572bE58FfE99dc390E8246f02dcAe6f611;

  /**
   * @dev The CTC contract is an append only log of transactions which must be applied to the rollup state.
   * It also holds configurations like the currently prepayed amount of gas which is what this contract is utilizing.
   * https://etherscan.io/address/0x5e4e65926ba27467555eb562121fac00d24e9dd2#code
   */
  ICanonicalTransactionChain public constant CANONICAL_TRANSACTION_CHAIN =
    ICanonicalTransactionChain(0x5E4e65926BA27467555EB562121fac00D24E9dD2);

  /**
   * @dev this function will be executed once the proposal passes the mainnet vote.
   * @param l2PayloadContract the optimism contract containing the `execute()` signature.
   */
  function execute(address l2PayloadContract) public {
    address[] memory targets = new address[](1);
    targets[0] = l2PayloadContract;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    string[] memory signatures = new string[](1);
    signatures[0] = 'execute()';
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = '';
    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = true;

    bytes memory queue = abi.encodeWithSelector(
      IL2BridgeExecutor.queue.selector,
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls
    );
    ICrossDomainMessenger(L1_CROSS_DOMAIN_MESSENGER_ADDRESS).sendMessage(
      OPTIMISM_BRIDGE_EXECUTOR,
      queue,
      uint32(CANONICAL_TRANSACTION_CHAIN.enqueueL2GasPrepaid())
    );
  }
}