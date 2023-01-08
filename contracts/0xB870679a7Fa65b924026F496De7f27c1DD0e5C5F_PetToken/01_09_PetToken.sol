// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract PetToken is ERC20Burnable, ReentrancyGuard {

    uint256 private constant MAX_SUPPLY = 2 * (10 ** 8) * (10 ** 18);

    constructor(address account) ERC20('Pet Token', 'PET') {
        _mint(account, MAX_SUPPLY);
    }
}