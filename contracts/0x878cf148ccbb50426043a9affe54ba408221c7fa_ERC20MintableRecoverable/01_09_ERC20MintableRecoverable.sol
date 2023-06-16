// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract ERC20MintableRecoverable is Context, AccessControl, ERC20 {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initial
    ) public ERC20(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());

        _setupDecimals(_decimals);

        _mint(_msgSender(), _initial);
    }

    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), 'ERC20MintableRecoverable: must have minter role to mint');
        _mint(to, amount);
    }

    function recoverERC20(address token, uint256 amount) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'ERC20MintableRecoverable: must have admin role to recover');

        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            'ERC20MintableRecoverable: token amount should be less or equal of balance'
        );

        IERC20(token).transfer(_msgSender(), amount);
    }
}