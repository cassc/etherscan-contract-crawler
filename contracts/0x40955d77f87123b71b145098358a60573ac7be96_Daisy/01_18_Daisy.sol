// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Daisy is AccessControlEnumerable, ERC20Capped, ERC20Burnable, ERC20Permit {
    uint public constant MAX_SUPPLY = 1_000_000_000 * 10**18;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(uint initialSupply) ERC20("DAISY", "DAISY") ERC20Capped(MAX_SUPPLY) ERC20Permit("DAISY") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        ERC20._mint(msg.sender, initialSupply);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20Capped, ERC20) {
        require(hasRole(MINTER_ROLE, _msgSender()), "Daisy: MUST_HAVE_MINTER_ROLE_TO_MINT");
        super._mint(account, amount);
    }

}