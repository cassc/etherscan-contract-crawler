// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20Capped} from './ERC20Capped.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';

contract MillionaireGameToken is AccessControl, ERC20Capped {
    // AccessControl roles
    bytes32 public constant MINT_ROLE = keccak256('MINT_ROLE');

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _maxSupply
    ) ERC20Capped(_name, _symbol, _decimals, _maxSupply) {
        // AccessControl initialization
        address deployer = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, deployer);
        _setupRole(MINT_ROLE, deployer);
    }

    function mint(address to, uint256 value) public virtual onlyRole(MINT_ROLE) {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual onlyRole(MINT_ROLE) {
        _burn(from, value);
    }
}