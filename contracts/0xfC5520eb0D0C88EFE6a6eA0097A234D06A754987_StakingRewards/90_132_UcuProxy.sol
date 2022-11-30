// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ImplementationRepository as Repo} from "./ImplementationRepository.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC173} from "../../../interfaces/IERC173.sol";

/// @title User Controlled Upgrade (UCU) Proxy
///
/// The UCU Proxy contract allows the owner of the proxy to control _when_ they
/// upgrade their proxy, but not to what implementation.  The implementation is
/// determined by an externally controlled {ImplementationRepository} contract that
/// specifices the upgrade path. A user is able to upgrade their proxy as many
/// times as is available until they're reached the most up to date version
contract UcuProxy is IERC173, Proxy {
  /// @dev Storage slot with the address of the current implementation.
  /// This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
  bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  // defined here: https://eips.ethereum.org/EIPS/eip-1967
  // result of `bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)`
  bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  // result of `bytes32(uint256(keccak256('eipxxxx.proxy.repository')) - 1)`
  bytes32 private constant _REPOSITORY_SLOT = 0x007037545499569801a5c0bd8dbf5fccb13988c7610367d129f45ee69b1624f8;

  // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////

  /// @param _repository repository used for sourcing upgrades
  /// @param _owner owner of proxy
  /// @dev reverts if either `_repository` or `_owner` is null
  constructor(Repo _repository, address _owner) public {
    require(_owner != address(0), "bad owner");
    _setOwner(_owner);
    _setRepository(_repository);
    // this will validate that the passed in repo is a contract
    _upgradeToAndCall(_repository.currentImplementation(), "");
  }

  /// @notice upgrade the proxy implementation
  /// @dev reverts if the repository has not been initialized or if there is no following version
  function upgradeImplementation() external onlyOwner {
    _upgradeImplementation();
  }

  /// @inheritdoc IERC173
  function transferOwnership(address newOwner) external override onlyOwner {
    _setOwner(newOwner);
  }

  /// @inheritdoc IERC173
  function owner() external view override returns (address) {
    return _getOwner();
  }

  /// @notice Returns the associated {Repo}
  ///   contract used for fetching implementations to upgrade to
  function getRepository() external view returns (Repo) {
    return _getRepository();
  }

  // ///////////////////////// INTERNAL //////////////////////////////////////////////////////////////////////

  function _upgradeImplementation() internal {
    Repo repo = _getRepository();
    address nextImpl = repo.nextImplementationOf(_implementation());
    bytes memory data = repo.upgradeDataFor(nextImpl);
    _upgradeToAndCall(nextImpl, data);
  }

  /// @dev Returns the current implementation address.
  function _implementation() internal view override returns (address impl) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(_IMPLEMENTATION_SLOT)
    }
  }

  /// @dev Upgrades the proxy to a new implementation.
  //
  /// Emits an {Upgraded} event.
  function _upgradeToAndCall(address newImplementation, bytes memory data) internal virtual {
    _setImplementationAndCall(newImplementation, data);
    emit Upgraded(newImplementation);
  }

  /// @dev Stores a new address in the EIP1967 implementation slot.
  function _setImplementationAndCall(address newImplementation, bytes memory data) internal {
    require(Address.isContract(newImplementation), "no upgrade");

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(_IMPLEMENTATION_SLOT, newImplementation)
    }

    if (data.length > 0) {
      (bool success, ) = newImplementation.delegatecall(data);
      if (!success) {
        assembly {
          // This assembly ensure the revert contains the exact string data
          let returnDataSize := returndatasize()
          returndatacopy(0, 0, returnDataSize)
          revert(0, returnDataSize)
        }
      }
    }
  }

  function _setRepository(Repo newRepository) internal {
    require(Address.isContract(address(newRepository)), "bad repo");
    // solhint-disable-next-line security/no-inline-assembly
    assembly {
      sstore(_REPOSITORY_SLOT, newRepository)
    }
  }

  function _getRepository() internal view returns (Repo repo) {
    // solhint-disable-next-line security/no-inline-assembly
    assembly {
      repo := sload(_REPOSITORY_SLOT)
    }
  }

  function _getOwner() internal view returns (address adminAddress) {
    // solhint-disable-next-line security/no-inline-assembly
    assembly {
      adminAddress := sload(_ADMIN_SLOT)
    }
  }

  function _setOwner(address newOwner) internal {
    address previousOwner = _getOwner();
    // solhint-disable-next-line security/no-inline-assembly
    assembly {
      sstore(_ADMIN_SLOT, newOwner)
    }
    emit OwnershipTransferred(previousOwner, newOwner);
  }

  // /////////////////////// MODIFIERS ////////////////////////////////////////////////////////////////////////
  modifier onlyOwner() {
    /// @dev NA: not authorized. not owner
    require(msg.sender == _getOwner(), "NA");
    _;
  }

  // /////////////////////// EVENTS ///////////////////////////////////////////////////////////////////////////

  /// @dev Emitted when the implementation is upgraded.
  event Upgraded(address indexed implementation);
}