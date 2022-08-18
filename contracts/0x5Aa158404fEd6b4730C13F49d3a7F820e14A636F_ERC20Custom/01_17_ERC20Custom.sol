pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract ERC20Custom is ERC20PresetMinterPauser {

    /**
     * @dev Allows overriding the name, symbol & decimal of the base ERC20 contract
     */
    constructor(string memory name, string memory symbol) public ERC20PresetMinterPauser(name, symbol) {
    }

    function grantMinterRole(address minterAddress) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not admin");
        _grantRole(MINTER_ROLE, minterAddress);
    }

    function grantPauserRole(address minterAddress) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not admin");
        _grantRole(MINTER_ROLE, minterAddress);
    }
}