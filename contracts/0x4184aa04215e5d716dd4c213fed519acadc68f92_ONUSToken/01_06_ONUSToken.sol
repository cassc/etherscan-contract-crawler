pragma solidity 0.6.12;

import "./libs/ERC20.sol";
import "./libs/ERC20Burnable.sol";


contract ONUSToken is ERC20Burnable {

    constructor() public ERC20("ONUS", "ONUS") {
        ERC20._mint(_msgSender(), 40000000 * 10 ** 18);
    }

}