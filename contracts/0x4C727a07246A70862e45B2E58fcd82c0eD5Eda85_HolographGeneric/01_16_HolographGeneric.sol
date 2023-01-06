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
import "../abstract/Owner.sol";

import "../enum/HolographGenericEvent.sol";
import "../enum/InterfaceType.sol";

import "../interface/HolographGenericInterface.sol";
import "../interface/ERC165.sol";
import "../interface/Holographable.sol";
import "../interface/HolographedGeneric.sol";
import "../interface/HolographInterface.sol";
import "../interface/InitializableInterface.sol";
import "../interface/HolographInterfacesInterface.sol";
import "../interface/Ownable.sol";

/**
 * @title Holograph Bridgeable Generic Contract
 * @author CXIP-Labs
 * @notice A smart contract for creating custom bridgeable logic.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract HolographGeneric is Admin, Owner, Initializable, HolographGenericInterface {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.holograph')) - 1)
   */
  bytes32 constant _holographSlot = 0xb4107f746e9496e8452accc7de63d1c5e14c19f510932daa04077cd49e8bd77a;
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.sourceContract')) - 1)
   */
  bytes32 constant _sourceContractSlot = 0x27d542086d1e831d40b749e7f5509a626c3047a36d160781c40d5acc83e5b074;

  /**
   * @dev Configuration for events to trigger for source smart contract.
   */
  uint256 private _eventConfig;

  /**
   * @notice Only allow calls from bridge smart contract.
   */
  modifier onlyBridge() {
    require(msg.sender == _holograph().getBridge(), "GENERIC: bridge only call");
    _;
  }

  /**
   * @notice Only allow calls from source smart contract.
   */
  modifier onlySource() {
    address sourceContract;
    assembly {
      sourceContract := sload(_sourceContractSlot)
    }
    require(msg.sender == sourceContract, "GENERIC: source only call");
    _;
  }

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
    require(!_isInitialized(), "GENERIC: already initialized");
    InitializableInterface sourceContract;
    assembly {
      sstore(_ownerSlot, caller())
      sourceContract := sload(_sourceContractSlot)
    }
    (uint256 eventConfig, bool skipInit, bytes memory initCode) = abi.decode(initPayload, (uint256, bool, bytes));
    _eventConfig = eventConfig;
    if (!skipInit) {
      require(sourceContract.init(initCode) == InitializableInterface.init.selector, "GENERIC: could not init source");
    }
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  /**
   * @dev Allows for source smart contract to withdraw contract balance.
   */
  function sourceWithdraw(address payable destination) external onlySource {
    destination.transfer(address(this).balance);
  }

  /**
   * @dev Purposefully left empty, to prevent running out of gas errors when receiving native token payments.
   */
  receive() external payable {}

  /**
   * @notice Fallback to the source contract.
   * @dev Any function call that is not covered here, will automatically be sent over to the source contract.
   */
  fallback() external payable {
    assembly {
      calldatacopy(0, 0, calldatasize())
      mstore(calldatasize(), caller())
      let result := call(gas(), sload(_sourceContractSlot), callvalue(), 0, add(calldatasize(), 0x20), 0, 0)
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

  function _sourceCall(bytes memory payload) private returns (bool output) {
    assembly {
      let pos := mload(0x40)
      mstore(0x40, add(pos, 0x20))
      mstore(add(payload, add(mload(payload), 0x20)), caller())
      // offset memory position by 32 bytes to skip the 32 bytes where bytes length is stored
      // add 32 bytes to bytes length to include the appended msg.sender to calldata
      let result := call(
        gas(),
        sload(_sourceContractSlot),
        callvalue(),
        add(payload, 0x20),
        add(mload(payload), 0x20),
        0,
        0
      )
      returndatacopy(pos, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      output := mload(pos)
    }
  }

  /**
   * @dev Although EIP-165 is not required for ERC20 contracts, we still decided to implement it.
   *
   * This makes it easier for external smart contracts to easily identify a valid ERC20 token contract.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    HolographInterfacesInterface interfaces = HolographInterfacesInterface(_interfaces());
    ERC165 erc165Contract;
    assembly {
      erc165Contract := sload(_sourceContractSlot)
    }
    if (
      interfaces.supportsInterface(InterfaceType.GENERIC, interfaceId) || erc165Contract.supportsInterface(interfaceId) // check global interfaces // check if source supports interface
    ) {
      return true;
    } else {
      return false;
    }
  }

  function bridgeIn(uint32 fromChain, bytes calldata payload) external onlyBridge returns (bytes4) {
    if (_isEventRegistered(HolographGenericEvent.bridgeIn)) {
      require(
        _sourceCall(abi.encodeWithSelector(HolographedGeneric.bridgeIn.selector, fromChain, payload)),
        "HOLOGRAPH: bridge in failed"
      );
    }
    return Holographable.bridgeIn.selector;
  }

  function bridgeOut(
    uint32 toChain,
    address sender,
    bytes calldata payload
  ) external onlyBridge returns (bytes4 selector, bytes memory data) {
    if (_isEventRegistered(HolographGenericEvent.bridgeOut)) {
      bytes memory sourcePayload = abi.encodeWithSelector(
        HolographedGeneric.bridgeOut.selector,
        toChain,
        sender,
        payload
      );
      assembly {
        // it is important to add 32 bytes in order to accommodate the first 32 bytes being used for storing length of bytes
        mstore(add(sourcePayload, add(mload(sourcePayload), 0x20)), caller())
        let result := call(
          gas(),
          sload(_sourceContractSlot),
          callvalue(),
          // start reading data from memory position, plus 32 bytes, to skip bytes length indicator
          add(sourcePayload, 0x20),
          // add an additional 32 bytes to bytes length to include the appended caller address
          add(mload(sourcePayload), 0x20),
          0,
          0
        )
        // when reading back data, skip the first 32 bytes which is used to indicate bytes position in calldata
        // also subtract 32 bytes from returndatasize to accomodate the skipped first 32 bytes
        returndatacopy(data, 0x20, sub(returndatasize(), 0x20))
        switch result
        case 0 {
          revert(0, returndatasize())
        }
      }
    }
    return (Holographable.bridgeOut.selector, data);
  }

  /**
   * @dev Allows for source smart contract to emit events.
   */
  function sourceEmit(bytes calldata eventData) external onlySource {
    assembly {
      calldatacopy(0, eventData.offset, eventData.length)
      log0(0, eventData.length)
    }
  }

  function sourceEmit(bytes32 eventId, bytes calldata eventData) external onlySource {
    assembly {
      calldatacopy(0, eventData.offset, eventData.length)
      log1(0, eventData.length, eventId)
    }
  }

  function sourceEmit(
    bytes32 eventId,
    bytes32 topic1,
    bytes calldata eventData
  ) external onlySource {
    assembly {
      calldatacopy(0, eventData.offset, eventData.length)
      log2(0, eventData.length, eventId, topic1)
    }
  }

  function sourceEmit(
    bytes32 eventId,
    bytes32 topic1,
    bytes32 topic2,
    bytes calldata eventData
  ) external onlySource {
    assembly {
      calldatacopy(0, eventData.offset, eventData.length)
      log3(0, eventData.length, eventId, topic1, topic2)
    }
  }

  function sourceEmit(
    bytes32 eventId,
    bytes32 topic1,
    bytes32 topic2,
    bytes32 topic3,
    bytes calldata eventData
  ) external onlySource {
    assembly {
      calldatacopy(0, eventData.offset, eventData.length)
      log4(0, eventData.length, eventId, topic1, topic2, topic3)
    }
  }

  /**
   * @dev Get the source smart contract as bridgeable interface.
   */
  function SourceGeneric() private view returns (HolographedGeneric sourceContract) {
    assembly {
      sourceContract := sload(_sourceContractSlot)
    }
  }

  /**
   * @dev Get the interfaces contract address.
   */
  function _interfaces() private view returns (address) {
    return _holograph().getInterfaces();
  }

  function owner() public view override returns (address) {
    Ownable ownableContract;
    assembly {
      ownableContract := sload(_sourceContractSlot)
    }
    return ownableContract.owner();
  }

  function _holograph() private view returns (HolographInterface holograph) {
    assembly {
      holograph := sload(_holographSlot)
    }
  }

  function _isEventRegistered(HolographGenericEvent _eventName) private view returns (bool) {
    return ((_eventConfig >> uint256(_eventName)) & uint256(1) == 1 ? true : false);
  }
}