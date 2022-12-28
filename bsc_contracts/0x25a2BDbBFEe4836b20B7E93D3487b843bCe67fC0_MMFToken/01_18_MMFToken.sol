// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract MMFToken is ERC20PresetMinterPauser, Ownable{

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE"); // Other roles can be assigned dinamically by the account having DEFAULT_ADMIN_ROLE role, by calling AccessControl.grantRole().

    constructor(string memory name_, string memory symbol_, uint256 initialSupply) ERC20PresetMinterPauser(name_, symbol_) {
        _mint(msg.sender, initialSupply * 10**18);
        grantRole(BURNER_ROLE, msg.sender);
    }

    function burn(uint256 value) public onlyRole(BURNER_ROLE) override {
      super._burn(msg.sender, value);
    }
}