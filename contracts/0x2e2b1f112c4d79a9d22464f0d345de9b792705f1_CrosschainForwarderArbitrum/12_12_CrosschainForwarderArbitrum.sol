// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {IInbox} from 'governance-crosschain-bridges/contracts/dependencies/arbitrum/interfaces/IInbox.sol';
import {IL2BridgeExecutor} from 'governance-crosschain-bridges/contracts/interfaces/IL2BridgeExecutor.sol';

/**
 * @title A generic executor for proposals targeting the arbitrum v3 pool
 * @author BGD Labs
 * @notice You can **only** use this executor when the arbitrum payload has a `execute()` signature without parameters
 * @notice You can **only** use this executor when the arbitrum payload is expected to be executed via `DELEGATECALL`
 * @notice This contract assumes to be called via AAVE Governance V2
 * @notice This contract will assume the SHORT_EXECUTOR will be topped up with enough funds to fund the short executor
 * @dev This executor is a generic wrapper to be used with Arbitrum Inbox (https://developer.offchainlabs.com/arbos/l1-to-l2-messaging)
 * It encodes a parameterless `execute()` with delegate calls and a specified target.
 * This encoded abi is then send to the Inbox to be synced executed on the arbitrum network.
 * Once synced the ARBITRUM_BRIDGE_EXECUTOR will queue the execution of the payload.
 */
contract CrosschainForwarderArbitrum {
  IInbox public constant INBOX =
    IInbox(0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f);
  address public constant ARBITRUM_BRIDGE_EXECUTOR =
    AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR;
  address public constant ARBITRUM_GUARDIAN =
    0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb;

  // amount of gwei to overpay on basefee for fast submission
  uint256 public constant BASE_FEE_MARGIN = 10 gwei;

  /**
   * @dev returns the amount of gas needed for relaying the message based on current basefee
   * @param bytesLength the payload bytes length (usually 580)
   */
  function getRequiredGas(uint256 bytesLength) public view returns (uint256) {
    return
      INBOX.calculateRetryableSubmissionFee(
        bytesLength,
        block.basefee + BASE_FEE_MARGIN
      );
  }

  /**
   * @dev checks if the short executor is topped up with enough eth for proposal execution
   * with current basefee
   * @param bytesLength the payload bytes length (usually 580)
   */
  function hasSufficientGasForExecution(uint256 bytesLength)
    public
    view
    returns (bool)
  {
    return (AaveGovernanceV2.SHORT_EXECUTOR.balance >=
      getRequiredGas(bytesLength));
  }

  /**
   * @dev encodes the queue call which is forwarded to arbitrum
   * @param l2PayloadContract the address of the arbitrum payload
   */
  function getEncodedPayload(address l2PayloadContract)
    public
    pure
    returns (bytes memory)
  {
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
    return
      abi.encodeWithSelector(
        IL2BridgeExecutor.queue.selector,
        targets,
        values,
        signatures,
        calldatas,
        withDelegatecalls
      );
  }

  /**
   * @dev this function will be executed once the proposal passes the mainnet vote.
   * @param l2PayloadContract the arbitrum contract containing the `execute()` signature.
   */
  function execute(address l2PayloadContract) public {
    bytes memory queue = getEncodedPayload(l2PayloadContract);
    uint256 maxSubmission = getRequiredGas(queue.length);
    INBOX.unsafeCreateRetryableTicket{value: maxSubmission}(
      ARBITRUM_BRIDGE_EXECUTOR,
      0, // l2CallValue
      maxSubmission, // maxSubmissionCost
      address(ARBITRUM_BRIDGE_EXECUTOR), // excessFeeRefundAddress
      address(ARBITRUM_GUARDIAN), // callValueRefundAddress
      0, // gasLimit
      0, // maxFeePerGas
      queue
    );
  }
}