// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Camly is ERC20, Ownable {

    constructor(address creator) ERC20("Camly Coin", "CAMLY") {
        _mint(creator, 999999999999 * 10 ** decimals());
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 3;
    }

    function burn(uint256 amount) external onlyOwner returns(bool) {
        _burn(msg.sender, amount);
        return true;
    }

}