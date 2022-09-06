// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Hootenani is ERC20, Ownable {

    constructor(address creator) ERC20("Hootenani", "Hoot") {
        _mint(creator, 1500000000 * 10 ** decimals());
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function burn(uint256 amount) external onlyOwner returns(bool) {
        _burn(msg.sender, amount);
        return true;
    }

}