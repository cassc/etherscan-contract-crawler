// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.7.4;

import "./common/CanReclaimTokens.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract StandardToken is ERC20, AccessControl, ERC20Burnable, CanReclaimTokens {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol) CanReclaimTokens(_msgSender()) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());

        _setupDecimals(decimals);
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function addMinter(address _newMinter) onlyMinter external {
        grantRole(MINTER_ROLE, _newMinter);
        grantRole(DEFAULT_ADMIN_ROLE, _newMinter);
    }

    function renounceMinter() onlyMinter external {
        renounceRole(MINTER_ROLE, _msgSender());
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address account, uint256 amount) onlyMinter public returns (bool) {
        _mint(account, amount);
        return true;
    }
}