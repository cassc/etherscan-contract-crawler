pragma solidity ^0.5.8;

import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract SoraToken is ERC20Burnable, ERC20Detailed, Ownable {

    uint256 public constant INITIAL_SUPPLY = 0;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() public ERC20Detailed("Sora Token", "XOR", 18) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mintTokens(address beneficiary, uint256 amount) public onlyOwner {
        _mint(beneficiary, amount);
    }

}
