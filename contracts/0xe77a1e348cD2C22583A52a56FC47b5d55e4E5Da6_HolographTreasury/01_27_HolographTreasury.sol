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

import "./interface/HolographERC20Interface.sol";
import "./interface/HolographERC721Interface.sol";
import "./interface/HolographInterface.sol";
import "./interface/HolographTreasuryInterface.sol";
import "./interface/HolographFactoryInterface.sol";
import "./interface/HolographOperatorInterface.sol";
import "./interface/HolographRegistryInterface.sol";
import "./interface/InitializableInterface.sol";

import "./struct/DeploymentConfig.sol";
import "./struct/Verification.sol";

/**
 * @title Holograph Treasury
 * @author https://github.com/holographxyz
 * @notice This contract holds and manages the protocol treasury
 * @dev As of now this is an empty zero logic contract and is still a work in progress
 */
contract HolographTreasury is Admin, Initializable, HolographTreasuryInterface {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.bridge')) - 1)
   */
  bytes32 constant _bridgeSlot = 0xeb87cbb21687feb327e3d58c6c16d552231d12c7a0e8115042a4165fac8a77f9;
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.holograph')) - 1)
   */
  bytes32 constant _holographSlot = 0xb4107f746e9496e8452accc7de63d1c5e14c19f510932daa04077cd49e8bd77a;
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.operator')) - 1)
   */
  bytes32 constant _operatorSlot = 0x7caba557ad34138fa3b7e43fb574e0e6cc10481c3073e0dffbc560db81b5c60f;
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
    (address bridge, address holograph, address operator, address registry) = abi.decode(
      initPayload,
      (address, address, address, address)
    );
    assembly {
      sstore(_adminSlot, origin())

      sstore(_bridgeSlot, bridge)
      sstore(_holographSlot, holograph)
      sstore(_operatorSlot, operator)
      sstore(_registrySlot, registry)
    }
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  /**
   * @notice Get the address of the Holograph Bridge module
   * @dev Used for beaming holographable assets cross-chain
   */
  function getBridge() external view returns (address bridge) {
    assembly {
      bridge := sload(_bridgeSlot)
    }
  }

  /**
   * @notice Update the Holograph Bridge module address
   * @param bridge address of the Holograph Bridge smart contract to use
   */
  function setBridge(address bridge) external onlyAdmin {
    assembly {
      sstore(_bridgeSlot, bridge)
    }
  }

  /**
   * @notice Get the Holograph Protocol contract
   * @dev This contract stores a reference to all the primary modules and variables of the protocol
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
   * @notice Get the address of the Holograph Operator module
   * @dev All cross-chain Holograph Bridge beams are handled by the Holograph Operator module
   */
  function getOperator() external view returns (address operator) {
    assembly {
      operator := sload(_operatorSlot)
    }
  }

  /**
   * @notice Update the Holograph Operator module address
   * @param operator address of the Holograph Operator smart contract to use
   */
  function setOperator(address operator) external onlyAdmin {
    assembly {
      sstore(_operatorSlot, operator)
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

  function _bridge() private view returns (address bridge) {
    assembly {
      bridge := sload(_bridgeSlot)
    }
  }

  function _holograph() private view returns (address holograph) {
    assembly {
      holograph := sload(_holographSlot)
    }
  }

  function _operator() private view returns (address operator) {
    assembly {
      operator := sload(_operatorSlot)
    }
  }

  function _registry() private view returns (address registry) {
    assembly {
      registry := sload(_registrySlot)
    }
  }

  /**
   * @dev Purposefully left empty to ensure ether transfers use least amount of gas possible
   */
  receive() external payable {}

  /**
   * @dev Purposefully reverts to prevent any calls to undefined functions
   */
  fallback() external payable {
    revert();
  }
}