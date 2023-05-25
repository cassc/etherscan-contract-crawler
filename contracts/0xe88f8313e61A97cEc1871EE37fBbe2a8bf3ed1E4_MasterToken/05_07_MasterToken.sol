pragma solidity ^0.5.8;

import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract MasterToken is ERC20Burnable, ERC20Detailed, Ownable {

    /**
     * @dev Constructor that gives the specified address all of existing tokens.
     */
    constructor(string memory name, string memory symbol, uint8 decimals, address beneficiary, uint256 supply) public ERC20Detailed(name, symbol, decimals) {
        _mint(beneficiary, supply);
    }

    function mintTokens(address beneficiary, uint256 amount) public onlyOwner {
        _mint(beneficiary, amount);
    }

}
