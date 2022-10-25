pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0-only
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface ISageStorage is IAccessControl {
    // Getters
    function getAddress(bytes32 _key) external view returns (address);

    function ARTIST_ROLE() external returns (bytes32);

    function ADMIN_ROLE() external returns (bytes32);

    function MINTER_ROLE() external returns (bytes32);

    function BURNER_ROLE() external returns (bytes32);

    function multisig() external view returns (address);
}