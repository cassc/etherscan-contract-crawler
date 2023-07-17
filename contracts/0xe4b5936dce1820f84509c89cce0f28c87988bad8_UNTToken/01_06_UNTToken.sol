pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract UNTToken is ERC20Burnable{

    constructor (string memory name_, string memory symbol_, address receiver, uint256 total)
    ERC20(name_, symbol_){
        _mint(receiver, total);
    }

}