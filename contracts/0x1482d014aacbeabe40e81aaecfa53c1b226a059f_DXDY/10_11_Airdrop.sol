// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Airdrop is ERC20, Ownable {
    function airdrop(address[] memory recipients, uint[] memory values) public onlyOwner {
        uint length = recipients.length;
        require(length >= 1 && values.length == length);
        for(uint i = 0 ; i < length; i++){
            _transfer(_msgSender(), recipients[i], values[i]);
        }
    }
}