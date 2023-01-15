// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @custom:security-contact [email protected]
contract StrategToken is ERC20, ERC20Permit, ERC20FlashMint, AccessControl {

    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bool nonTransferable;

    constructor(address _multisig) ERC20("Strateg Token", "STRAT") ERC20Permit("Strateg Token") {
        _mint(_multisig, 100000000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, _multisig);
        _grantRole(TRANSFER_ROLE, _multisig);
        nonTransferable = true;
    }

    function setTransferable() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Forbiden');
        nonTransferable = false;
    }

    function _beforeTokenTransfer(address, address, uint256)
        internal
        view
        override
    {
        if(nonTransferable) 
            require(hasRole(TRANSFER_ROLE, msg.sender), 'Forbiden');
    }
}