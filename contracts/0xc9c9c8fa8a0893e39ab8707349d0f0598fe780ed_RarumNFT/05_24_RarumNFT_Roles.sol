//SPDX-License-Identifier: none

pragma solidity ^0.8.0;

import "./ERC1155/presets/ERC1155PresetMinterPauserUpgradeable.sol";

contract RarumNFT_Roles is ERC1155PresetMinterPauserUpgradeable {

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "RarumNFT: caller is not a MINTER");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "RarumNFT: caller is not an OPERATOR");
        _;
    }

    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), "RarumNFT: caller is not a BURNER");
        _;
    }
}