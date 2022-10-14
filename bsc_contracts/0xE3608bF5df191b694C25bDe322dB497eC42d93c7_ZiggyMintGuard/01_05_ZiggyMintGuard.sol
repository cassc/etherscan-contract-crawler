// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract ZiggyMintGuard {
    address public constant Ziggy = 0x73E86FE8fF0ba37a213461397825aF31dD12f868;
    address public constant PaymentReceiver = 0xcc226cfB33133BcBcdEa63C638AfEa480Ee7E656;
    uint256 public constant MaxSupply = 2500;
    uint256 public constant Price = 0.25 ether;

    receive() external payable {
        uint256 currentSupply = IERC721Enumerable(Ziggy).totalSupply();
        uint256 amount = msg.value / Price;
        require((currentSupply + amount) <= MaxSupply, "Exceeds MaxSupply");
        Address.sendValue(payable(PaymentReceiver), msg.value);
    }
}