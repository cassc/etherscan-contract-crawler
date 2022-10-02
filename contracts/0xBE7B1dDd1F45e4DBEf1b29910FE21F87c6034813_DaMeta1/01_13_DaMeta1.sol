pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";

contract DaMeta1 is ERC20PresetMinterPauser, ERC20Capped{

    constructor(string memory name, string memory symbol, uint256 maxSupply, address wallet) public ERC20PresetMinterPauser(name,symbol) ERC20Capped(maxSupply * 10**18) {
        _mint(wallet, maxSupply * 10**18);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20PresetMinterPauser, ERC20Capped) {
        super._beforeTokenTransfer(from, to, amount);
    }
}