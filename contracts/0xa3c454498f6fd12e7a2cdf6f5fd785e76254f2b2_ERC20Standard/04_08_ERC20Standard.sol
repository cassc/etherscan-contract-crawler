// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./Ownable.sol";

/**
 * After PCD drug sales of each year and as a token of our appreciation, 
 * we have decided to distribute 30% of the sales profit generated from PCD drug 
 * to every owner of PCD crypto through a USDT airdrop. This dividend distribution will occur annually, 
 * based on the company's gross profit from the sale of PCD drug. 
 * This initiative serves as a gesture of gratitude to each participant of the PCD crypto owner.
 */

contract ERC20Standard is ERC20, Ownable {
    using Address for address;
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeMath for uint;

    uint8 private __decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 _decimals,
        uint256 supply,
        address owner
    ) ERC20 (name, symbol) {
        __decimals = _decimals;
        _mint(owner, supply * 10**_decimals);
        transferOwnership(owner);
    }

    function decimals() public view override returns(uint8){
        return __decimals;
    }
}