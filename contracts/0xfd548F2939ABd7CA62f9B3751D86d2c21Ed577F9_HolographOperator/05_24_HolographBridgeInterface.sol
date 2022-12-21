// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

/**
 * @title Holograph Bridge
 * @author https://github.com/holographxyz
 * @notice Beam any holographable contracts and assets across blockchains
 * @dev The contract abstracts all the complexities of making bridge requests and uses a universal interface to bridge any type of holographable assets
 */
interface HolographBridgeInterface {
  /**
   * @notice Receive a beam from another chain
   * @dev This function can only be called by the Holograph Operator module
   * @param fromChain Holograph Chain ID where the brigeOutRequest was created
   * @param holographableContract address of the destination contract that the bridgeInRequest is targeted for
   * @param hToken address of the hToken contract that wrapped the origin chain native gas token
   * @param hTokenRecipient address of recipient for the hToken reward
   * @param hTokenValue exact amount of hToken reward in wei
   * @param doNotRevert boolean used to specify if the call should revert
   * @param bridgeInPayload actual abi encoded bytes of the data that the holographable contract bridgeIn function will receive
   */
  function bridgeInRequest(
    uint256 nonce,
    uint32 fromChain,
    address holographableContract,
    address hToken,
    address hTokenRecipient,
    uint256 hTokenValue,
    bool doNotRevert,
    bytes calldata bridgeInPayload
  ) external payable;

  /**
   * @notice Create a beam request for a destination chain
   * @dev This function works for deploying contracts and beaming supported holographable assets across chains
   * @param toChain Holograph Chain ID where the beam is being sent to
   * @param holographableContract address of the contract for which the bridge request is being made
   * @param gasLimit maximum amount of gas to spend for executing the beam on destination chain
   * @param gasPrice maximum amount of gas price (in destination chain native gas token) to pay on destination chain
   * @param bridgeOutPayload actual abi encoded bytes of the data that the holographable contract bridgeOut function will receive
   */
  function bridgeOutRequest(
    uint32 toChain,
    address holographableContract,
    uint256 gasLimit,
    uint256 gasPrice,
    bytes calldata bridgeOutPayload
  ) external payable;

  /**
   * @notice Do not call this function, it will always revert
   * @dev Used by getBridgeOutRequestPayload function
   *      It is purposefully inverted to always revert on a successful call
   *      Marked as external and not private to allow use inside try/catch of getBridgeOutRequestPayload function
   *      If this function does not revert and returns a string, it is the actual revert reason
   * @param sender address of actual sender that is planning to make a bridgeOutRequest call
   * @param toChain holograph chain id of destination chain
   * @param holographableContract address of the contract for which the bridge request is being made
   * @param bridgeOutPayload actual abi encoded bytes of the data that the holographable contract bridgeOut function will receive
   */
  function revertedBridgeOutRequest(
    address sender,
    uint32 toChain,
    address holographableContract,
    bytes calldata bridgeOutPayload
  ) external returns (string memory revertReason);

  /**
   * @notice Get the payload created by the bridgeOutRequest function
   * @dev Use this function to get the payload that will be generated by a bridgeOutRequest
   *      Only use this with a static call
   * @param toChain Holograph Chain ID where the beam is being sent to
   * @param holographableContract address of the contract for which the bridge request is being made
   * @param gasLimit maximum amount of gas to spend for executing the beam on destination chain
   * @param gasPrice maximum amount of gas price (in destination chain native gas token) to pay on destination chain
   * @param bridgeOutPayload actual abi encoded bytes of the data that the holographable contract bridgeOut function will receive
   * @return samplePayload bytes made up of the bridgeOutRequest payload
   */
  function getBridgeOutRequestPayload(
    uint32 toChain,
    address holographableContract,
    uint256 gasLimit,
    uint256 gasPrice,
    bytes calldata bridgeOutPayload
  ) external returns (bytes memory samplePayload);

  /**
   * @notice Get the fees associated with sending specific payload
   * @dev Will provide exact costs on protocol and message side, combine the two to get total
   * @param toChain holograph chain id of destination chain for payload
   * @param gasLimit amount of gas to provide for executing payload on destination chain
   * @param gasPrice maximum amount to pay for gas price, can be set to 0 and will be chose automatically
   * @param crossChainPayload the entire packet being sent cross-chain
   * @return hlgFee the amount (in wei) of native gas token that will cost for finalizing job on destiantion chain
   * @return msgFee the amount (in wei) of native gas token that will cost for sending message to destiantion chain
   * @return dstGasPrice the amount (in wei) that destination message maximum gas price will be
   */
  function getMessageFee(
    uint32 toChain,
    uint256 gasLimit,
    uint256 gasPrice,
    bytes calldata crossChainPayload
  )
    external
    view
    returns (
      uint256 hlgFee,
      uint256 msgFee,
      uint256 dstGasPrice
    );

  /**
   * @notice Get the address of the Holograph Factory module
   * @dev Used for deploying holographable smart contracts
   */
  function getFactory() external view returns (address factory);

  /**
   * @notice Update the Holograph Factory module address
   * @param factory address of the Holograph Factory smart contract to use
   */
  function setFactory(address factory) external;

  /**
   * @notice Get the Holograph Protocol contract
   * @dev Used for storing a reference to all the primary modules and variables of the protocol
   */
  function getHolograph() external view returns (address holograph);

  /**
   * @notice Update the Holograph Protocol contract address
   * @param holograph address of the Holograph Protocol smart contract to use
   */
  function setHolograph(address holograph) external;

  /**
   * @notice Get the latest job nonce
   * @dev You can use the job nonce as a way to calculate total amount of bridge requests that have been made
   */
  function getJobNonce() external view returns (uint256 jobNonce);

  /**
   * @notice Get the address of the Holograph Operator module
   * @dev All cross-chain Holograph Bridge beams are handled by the Holograph Operator module
   */
  function getOperator() external view returns (address operator);

  /**
   * @notice Update the Holograph Operator module address
   * @param operator address of the Holograph Operator smart contract to use
   */
  function setOperator(address operator) external;

  /**
   * @notice Get the Holograph Registry module
   * @dev This module stores a reference for all deployed holographable smart contracts
   */
  function getRegistry() external view returns (address registry);

  /**
   * @notice Update the Holograph Registry module address
   * @param registry address of the Holograph Registry smart contract to use
   */
  function setRegistry(address registry) external;
}