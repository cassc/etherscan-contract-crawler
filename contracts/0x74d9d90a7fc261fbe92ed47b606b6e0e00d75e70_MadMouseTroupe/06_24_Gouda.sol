// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Gouda is ERC20, AccessControl {
    bytes32 constant MINT_AUTHORITY = keccak256('MINT_AUTHORITY');
    bytes32 constant BURN_AUTHORITY = keccak256('BURN_AUTHORITY');
    bytes32 constant TREASURY = keccak256('TREASURY');

    address public multiSigTreasury = 0xFB79a928C5d6c5932Ba83Aa8C7145cBDCDb9fd2E;

    constructor(address madmouse) ERC20('Gouda', 'GOUDA') {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(MINT_AUTHORITY, madmouse);
        _setupRole(BURN_AUTHORITY, madmouse);
        _setupRole(TREASURY, multiSigTreasury);

        _mint(multiSigTreasury, 200_000 * 1e18);
    }

    /* ------------- Restricted ------------- */

    function mint(address user, uint256 amount) external onlyRole(MINT_AUTHORITY) {
        _mint(user, amount);
    }

    /* ------------- ERC20Burnable ------------- */

    function burnFrom(address account, uint256 amount) public {
        if (!hasRole(BURN_AUTHORITY, msg.sender)) _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }
}