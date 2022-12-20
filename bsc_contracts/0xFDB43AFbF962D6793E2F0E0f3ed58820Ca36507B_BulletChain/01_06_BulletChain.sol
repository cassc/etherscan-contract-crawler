// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BulletChain is ERC20, Ownable {

    address public burner;

    constructor(address _burner) ERC20("BulletChain", "BCN") {
        _mint(msg.sender, 2100000000 * 10 ** decimals());
        burner = _burner;
    }

    /**
     * @dev Destroys `amount` tokens from the `addr`. Requires burner role.
     */
    function burn(address addr, uint256 amount) public virtual {
        require(_msgSender() == burner, "Caller is not burner");
        _burn(addr, amount);
    }

    /**
     * @dev Set burner role
     */
    function setBurner(address _burner) onlyOwner public{
        require(_burner != address(0), "Burner can not be address 0!");
        require(_burner != burner, "Can not set to the current burner address");
        burner = _burner;
    }

}