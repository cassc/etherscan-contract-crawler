//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";

abstract contract HasSecondarySaleFees is ERC165StorageUpgradeable {
    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint256[] bps);

    function getFeeRecipients(uint256 id) external view virtual returns (address[] memory);

    function getFeeBps(uint256 id) external view virtual returns (uint32[] memory);

    function _initialize() internal initializer {
        _registerInterface(_INTERFACE_ID_FEES);
    }
}