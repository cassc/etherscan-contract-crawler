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

import "../abstract/Admin.sol";
import "../abstract/Initializable.sol";

import "../interface/HolographInterface.sol";
import "../interface/HolographerInterface.sol";
import "../interface/HolographRegistryInterface.sol";
import "../interface/InitializableInterface.sol";

/**
 * @dev This contract is a binder. It puts together all the variables to make the underlying contracts functional and be bridgeable.
 */
contract Holographer is Admin, Initializable, HolographerInterface {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.originChain')) - 1)
   */
  bytes32 constant _originChainSlot = 0xd49ffd6af8249d6e6b5963d9d2b22c6db30ad594cb468453047a14e1c1bcde4d;
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.holograph')) - 1)
   */
  bytes32 constant _holographSlot = 0xb4107f746e9496e8452accc7de63d1c5e14c19f510932daa04077cd49e8bd77a;
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.contractType')) - 1)
   */
  bytes32 constant _contractTypeSlot = 0x0b671eb65810897366dd82c4cbb7d9dff8beda8484194956e81e89b8a361d9c7;
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.sourceContract')) - 1)
   */
  bytes32 constant _sourceContractSlot = 0x27d542086d1e831d40b749e7f5509a626c3047a36d160781c40d5acc83e5b074;
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.blockHeight')) - 1)
   */
  bytes32 constant _blockHeightSlot = 0x9172848b0f1df776dc924b58e7fa303087ae0409bbf611608529e7f747d55de3;

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
    require(!_isInitialized(), "HOLOGRAPHER: already initialized");
    (bytes memory encoded, bytes memory initCode) = abi.decode(initPayload, (bytes, bytes));
    (uint32 originChain, address holograph, bytes32 contractType, address sourceContract) = abi.decode(
      encoded,
      (uint32, address, bytes32, address)
    );
    assembly {
      sstore(_adminSlot, caller())
      sstore(_blockHeightSlot, number())
      sstore(_contractTypeSlot, contractType)
      sstore(_holographSlot, holograph)
      sstore(_originChainSlot, originChain)
      sstore(_sourceContractSlot, sourceContract)
    }
    (bool success, bytes memory returnData) = HolographRegistryInterface(HolographInterface(holograph).getRegistry())
      .getReservedContractTypeAddress(contractType)
      .delegatecall(abi.encodeWithSelector(InitializableInterface.init.selector, initCode));
    bytes4 selector = abi.decode(returnData, (bytes4));
    require(success && selector == InitializableInterface.init.selector, "HOLOGRAPH: initialization failed");
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  /**
   * @dev Returns the contract type that is used for loading the Enforcer
   */
  function getContractType() external view returns (bytes32 contractType) {
    assembly {
      contractType := sload(_contractTypeSlot)
    }
  }

  /**
   * @dev Returns the block height of when the smart contract was deployed. Useful for retrieving deployment config for re-deployment on other EVM-compatible chains.
   */
  function getDeploymentBlock() external view returns (uint256 deploymentBlock) {
    assembly {
      deploymentBlock := sload(_blockHeightSlot)
    }
  }

  /**
   * @dev Returns a hardcoded address for the Holograph smart contract.
   */
  function getHolograph() external view returns (address holograph) {
    assembly {
      holograph := sload(_holographSlot)
    }
  }

  /**
   * @dev Returns a hardcoded address for the Holograph smart contract that controls and enforces the ERC standards.
   */
  function getHolographEnforcer() public view returns (address) {
    HolographInterface holograph;
    bytes32 contractType;
    assembly {
      holograph := sload(_holographSlot)
      contractType := sload(_contractTypeSlot)
    }
    return HolographRegistryInterface(holograph.getRegistry()).getReservedContractTypeAddress(contractType);
  }

  /**
   * @dev Returns the original chain that contract was deployed on.
   */
  function getOriginChain() external view returns (uint32 originChain) {
    assembly {
      originChain := sload(_originChainSlot)
    }
  }

  /**
   * @dev Returns a hardcoded address for the custom secure storage contract deployed in parallel with this contract deployment.
   */
  function getSourceContract() external view returns (address sourceContract) {
    assembly {
      sourceContract := sload(_sourceContractSlot)
    }
  }

  /**
   * @dev Purposefully left empty, to prevent running out of gas errors when receiving native token payments.
   */
  receive() external payable {}

  /**
   * @dev This takes the Enforcer's source code, runs it, and uses current address for storage slots.
   */
  fallback() external payable {
    address holographEnforcer = getHolographEnforcer();
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), holographEnforcer, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}