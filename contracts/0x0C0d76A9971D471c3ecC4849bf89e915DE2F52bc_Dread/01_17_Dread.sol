//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract Dread is ERC20PresetMinterPauser("Dreadfulz", "DREAD") {
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addMinter(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, _address);
    }

    function addPauser(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(PAUSER_ROLE, _address);
    }
}