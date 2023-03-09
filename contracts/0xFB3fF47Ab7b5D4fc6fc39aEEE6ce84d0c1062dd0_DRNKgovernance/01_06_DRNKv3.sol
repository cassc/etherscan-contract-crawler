/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';

contract DRNKgovernance is ERC20, Ownable {

    address public _admin;

    constructor() ERC20('Drunk Governance Token v3', 'DRNK') {
        _mint(msg.sender, 1 * (10 ** 18));
        _admin = msg.sender;
    }

    function mintDRNK(address to, uint amount) external {
        _mint(to, amount);
    }

    function burnDRNK(uint amount) external {
        _burn(msg.sender, amount * (10 ** 18));
    }

}