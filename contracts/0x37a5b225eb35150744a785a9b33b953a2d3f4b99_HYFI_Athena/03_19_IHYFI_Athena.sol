// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

// solhint-disable-next-line contract-name-camelcase
interface IHYFI_Athena is IAccessControlUpgradeable {
    // solhint-disable-next-line func-name-mixedcase
    function MINTER_ROLE() external view returns (bytes32);

    // solhint-disable-next-line func-name-mixedcase
    function BURNER_ROLE() external view returns (bytes32);
}