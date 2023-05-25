// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;


/// Openzeppelin imports
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';


/**
 * Implementation of Fasttoken.
 * Fasttoken is a standard ERC20 burnable token.
 */
contract Fasttoken is ERC20Burnable {

    uint256 public constant INITIALSUPPLY = 1000000000 * (10 ** 18);

    constructor()
            ERC20('Fasttoken', 'FTN') {

        _mint(msg.sender, INITIALSUPPLY);
    }
}