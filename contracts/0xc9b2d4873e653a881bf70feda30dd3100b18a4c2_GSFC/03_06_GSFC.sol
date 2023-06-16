// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./SafeMath.sol";

contract GSFC is ERC20 {
    using SafeMath for uint256;

    uint taxDivisor = 20;
    address private creatorAddress = 0xfbB9c97a5C8F0873E473D86B70719862E1F370F8;

    constructor() ERC20("Terrier Oriole", "GSFC") {
        //Pre-mint to creatorAddres
        _mint(creatorAddress, 40000000 * 10 ** decimals());

         //mint tokens to the deployer   
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function transfer(address to, uint amount) public override returns (bool) {
        uint balanceSender = balanceOf(msg.sender);
        require(balanceSender >= amount, "ERC20: Not enough balance for transfer");

        uint taxAmount = amount / taxDivisor;
        uint transferAmount = amount - taxAmount;

        _transfer(msg.sender, to, transferAmount);
        _transfer(msg.sender, creatorAddress, taxAmount);

        return true;
    }

}