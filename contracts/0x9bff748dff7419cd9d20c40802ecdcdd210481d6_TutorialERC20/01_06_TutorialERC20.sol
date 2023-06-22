pragma solidity =0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TutorialERC20 is ERC20, Ownable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 amt
    ) ERC20(name_, symbol_) {
        mint(msg.sender, amt);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}