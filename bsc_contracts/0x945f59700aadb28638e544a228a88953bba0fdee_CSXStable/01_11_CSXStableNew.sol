// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract CSXStable is AccessControl,ERC20Burnable {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _adminAddress) ERC20("CSX$", "CSX$") {
        require(
            _adminAddress != address(0),
            "CSX$: reserve wallet zero address"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _adminAddress);
        _setupRole(MINTER_ROLE,_msgSender());
    }

    modifier onlyAllowed() {
        require(
            hasRole(MINTER_ROLE, _msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "CSX$: not admin or not minter role"
        );
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(address account, uint256 amount) external onlyAllowed {
        require(amount > 0, "CSX$: invalid amount");
        _mint(account, amount);
    }
}