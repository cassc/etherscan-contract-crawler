pragma solidity ^0.6.0;

import "./ERC20Blockable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract TapToken is ERC20PresetMinterPauser, ERC20Capped, ERC20Blockable {
    constructor (string memory name, string memory symbol, uint256 cap) public ERC20PresetMinterPauser(name, symbol) ERC20Capped(cap) {}

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20PresetMinterPauser, ERC20Capped, ERC20Blockable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}