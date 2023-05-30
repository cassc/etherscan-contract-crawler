// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract CRCLToken is ERC20, Pausable, AccessControlEnumerable, ERC20Permit, ERC20Votes {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("CRCL Token", "CRCL") ERC20Permit("CRCL Token") {
        _mint(msg.sender, 6630000000 * 10 ** decimals());
        _mint(0x64274945d4b069053c0f07971472c30fcB580402, 468000000 * 10 ** decimals());
        _mint(0x296dDaa619F09D45888Bd839E45D5f79623f39A1, 312000000 * 10 ** decimals());
        _mint(0xCC005fc413c333E642671087B8E0233f65CA062D, 234000000 * 10 ** decimals());
        _mint(0x5BBB643ff1264D429acbc7a93faE21de6E60DC0b, 156000000 * 10 ** decimals());
        _setupRole(DEFAULT_ADMIN_ROLE, 0x64274945d4b069053c0f07971472c30fcB580402);
        _setupRole(PAUSER_ROLE, 0x64274945d4b069053c0f07971472c30fcB580402);
        _setupRole(MINTER_ROLE, 0x64274945d4b069053c0f07971472c30fcB580402);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
    
}