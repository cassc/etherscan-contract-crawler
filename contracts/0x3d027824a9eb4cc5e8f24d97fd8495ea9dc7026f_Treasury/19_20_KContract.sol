// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "../core/IKEI.sol";

import "./KLibrary.sol";
import "./IKContract.sol";

abstract contract KContract is IKContract, Pausable, Multicall, AccessControl {

    bytes32 public constant MANAGE_ROLE = keccak256('MANAGE_ROLE');
    bytes32 public constant PAUSE_ROLE = keccak256('PAUSE_ROLE');

    IKEI public immutable K = KLibrary.K;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IKContract).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return super.hasRole(role, account) || K.master() == account;
    }

    function pause() external virtual override onlyRole(PAUSE_ROLE) {
        _pause();
    }

    function unpause() external virtual override onlyRole(PAUSE_ROLE) {
        _unpause();
    }

    function _core() internal view returns (IKEI.Core memory) {
        return K.core();
    }

    function _snapshot() internal view returns (IKEI.Snapshot memory) {
        return K.snapshot();
    }

    function _services() internal view returns (IKEI.Services memory) {
        return K.services();
    }
}