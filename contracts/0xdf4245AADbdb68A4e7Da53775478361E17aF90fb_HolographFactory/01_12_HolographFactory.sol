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

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./enforcer/Holographer.sol";

import "./interface/Holographable.sol";
import "./interface/HolographFactoryInterface.sol";
import "./interface/HolographRegistryInterface.sol";
import "./interface/InitializableInterface.sol";

import "./struct/DeploymentConfig.sol";
import "./struct/Verification.sol";

/**
 * @title Holograph Factory
 * @author https://github.com/holographxyz
 * @notice Deploy holographable contracts
 * @dev The contract provides methods that allow for the creation of Holograph Protocol compliant smart contracts, that are capable of minting holographable assets
 */
contract HolographFactory is Admin, Initializable, Holographable, HolographFactoryInterface {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.holograph')) - 1)
   */
  bytes32 constant _holographSlot = 0xb4107f746e9496e8452accc7de63d1c5e14c19f510932daa04077cd49e8bd77a;
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.registry')) - 1)
   */
  bytes32 constant _registrySlot = 0xce8e75d5c5227ce29a4ee170160bb296e5dea6934b80a9bd723f7ef1e7c850e7;

  /**
   * @dev Constructor is left empty and init is used instead
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address holograph, address registry) = abi.decode(initPayload, (address, address));
    assembly {
      sstore(_adminSlot, origin())
      sstore(_holographSlot, holograph)
      sstore(_registrySlot, registry)
    }
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  /**
   * @notice Deploy holographable contract via bridge request
   * @dev This function directly forwards the calldata to the deployHolographableContract function
   *      It is used to allow for Holograph Bridge to make cross-chain deployments
   */
  function bridgeIn(
    uint32, /* fromChain*/
    bytes calldata payload
  ) external returns (bytes4) {
    (DeploymentConfig memory config, Verification memory signature, address signer) = abi.decode(
      payload,
      (DeploymentConfig, Verification, address)
    );
    HolographFactoryInterface(address(this)).deployHolographableContract(config, signature, signer);
    return Holographable.bridgeIn.selector;
  }

  /**
   * @notice Deploy holographable contract via bridge request
   * @dev This function directly returns the calldata
   *      It is used to allow for Holograph Bridge to make cross-chain deployments
   */
  function bridgeOut(
    uint32, /* toChain*/
    address, /* sender*/
    bytes calldata payload
  ) external pure returns (bytes4 selector, bytes memory data) {
    return (Holographable.bridgeOut.selector, payload);
  }

  /**
   * @notice Deploy a holographable smart contract
   * @dev Using this function allows to deploy smart contracts that have the same address across all EVM chains
   * @param config contract deployement configurations
   * @param signature that was created by the wallet that created the original payload
   * @param signer address of wallet that created the payload
   */
  function deployHolographableContract(
    DeploymentConfig memory config,
    Verification memory signature,
    address signer
  ) external {
    address registry;
    address holograph;
    assembly {
      holograph := sload(_holographSlot)
      registry := sload(_registrySlot)
    }
    /**
     * @dev the configuration is encoded and hashed along with signer address
     */
    bytes32 hash = keccak256(
      abi.encodePacked(
        config.contractType,
        config.chainType,
        config.salt,
        keccak256(config.byteCode),
        keccak256(config.initCode),
        signer
      )
    );
    /**
     * @dev the hash is validated against signature
     *      this is to guarantee that the original creator's configuration has not been altered
     */
    require(_verifySigner(signature.r, signature.s, signature.v, hash, signer), "HOLOGRAPH: invalid signature");
    /**
     * @dev check that this contract has not already been deployed on this chain
     */
    bytes memory holographerBytecode = type(Holographer).creationCode;
    address holographerAddress = address(
      uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), hash, keccak256(holographerBytecode)))))
    );
    require(!_isContract(holographerAddress), "HOLOGRAPH: already deployed");
    /**
     * @dev convert hash into uint256 which will be used as the salt for create2
     */
    uint256 saltInt = uint256(hash);
    address sourceContractAddress;
    bytes memory sourceByteCode = config.byteCode;
    assembly {
      /**
       * @dev deploy the user created smart contract first
       */
      sourceContractAddress := create2(0, add(sourceByteCode, 0x20), mload(sourceByteCode), saltInt)
    }
    assembly {
      /**
       * @dev deploy the Holographer contract
       */
      holographerAddress := create2(0, add(holographerBytecode, 0x20), mload(holographerBytecode), saltInt)
    }
    /**
     * @dev initialize the Holographer contract
     */
    require(
      InitializableInterface(holographerAddress).init(
        abi.encode(abi.encode(config.chainType, holograph, config.contractType, sourceContractAddress), config.initCode)
      ) == InitializableInterface.init.selector,
      "initialization failed"
    );
    /**
     * @dev update the Holograph Registry with deployed contract address
     */
    HolographRegistryInterface(registry).setHolographedHashAddress(hash, holographerAddress);
    /**
     * @dev emit an event that on-chain indexers can easily read
     */
    emit BridgeableContractDeployed(holographerAddress, hash);
  }

  /**
   * @notice Get the Holograph Protocol contract
   * @dev Used for storing a reference to all the primary modules and variables of the protocol
   */
  function getHolograph() external view returns (address holograph) {
    assembly {
      holograph := sload(_holographSlot)
    }
  }

  /**
   * @notice Update the Holograph Protocol contract address
   * @param holograph address of the Holograph Protocol smart contract to use
   */
  function setHolograph(address holograph) external onlyAdmin {
    assembly {
      sstore(_holographSlot, holograph)
    }
  }

  /**
   * @notice Get the Holograph Registry module
   * @dev This module stores a reference for all deployed holographable smart contracts
   */
  function getRegistry() external view returns (address registry) {
    assembly {
      registry := sload(_registrySlot)
    }
  }

  /**
   * @notice Update the Holograph Registry module address
   * @param registry address of the Holograph Registry smart contract to use
   */
  function setRegistry(address registry) external onlyAdmin {
    assembly {
      sstore(_registrySlot, registry)
    }
  }

  /**
   * @dev Internal function used for checking if a contract has been deployed at address
   */
  function _isContract(address contractAddress) private view returns (bool) {
    bytes32 codehash;
    assembly {
      codehash := extcodehash(contractAddress)
    }
    return (codehash != 0x0 && codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
  }

  /**
   * @dev Internal function used for verifying a signature
   */
  function _verifySigner(
    bytes32 r,
    bytes32 s,
    uint8 v,
    bytes32 hash,
    address signer
  ) private pure returns (bool) {
    if (v < 27) {
      v += 27;
    }
    if (v != 27 && v != 28) {
      return false;
    }
    // prevent signature malleability by checking if s-value is in the upper range
    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      // if s-value is in upper range, calculate a new s-value
      s = bytes32(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - uint256(s));
      // flip the v-value
      if (v == 27) {
        v = 28;
      } else {
        v = 27;
      }
      // check if s-value is still in upper range
      if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
        return false;
      }
    }
    /**
     * @dev signature is checked against EIP-191 first, then directly, to support legacy wallets
     */
    return (signer != address(0) &&
      (ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == signer ||
        ecrecover(hash, v, r, s) == signer));
  }

  /**
   * @dev Purposefully reverts to prevent having any type of ether transfered into the contract
   */
  receive() external payable {
    revert();
  }

  /**
   * @dev Purposefully reverts to prevent any calls to undefined functions
   */
  fallback() external payable {
    revert();
  }
}