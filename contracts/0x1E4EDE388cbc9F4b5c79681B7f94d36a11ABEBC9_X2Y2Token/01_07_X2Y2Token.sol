// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

import {IMintableERC20} from './IMintableERC20.sol';

contract X2Y2Token is ERC20, Ownable, IMintableERC20 {
    uint256 private immutable _SUPPLY_CAP;

    constructor(
        address _premintReceiver,
        uint256 _premintAmount,
        uint256 _cap
    ) ERC20('X2Y2Token', 'X2Y2') {
        require(_cap > _premintAmount, 'Premint exceeds cap');
        // Transfer the sum of the premint to address
        _mint(_premintReceiver, _premintAmount);
        _SUPPLY_CAP = _cap;
    }

    function mint(address account, uint256 amount)
        external
        override
        onlyOwner
        returns (bool status)
    {
        if (totalSupply() + amount <= _SUPPLY_CAP) {
            _mint(account, amount);
            return true;
        }
        return false;
    }

    /**
     * @notice View supply cap
     */
    function SUPPLY_CAP() external view override returns (uint256) {
        return _SUPPLY_CAP;
    }
}