// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract OogearERC20 is ERC20, Ownable {

    address public gameContract;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) Ownable() {

    }

    function setGameContract(address gameContract_) external onlyOwner {
         gameContract = gameContract_;
    }   

    function mint(address account, uint256 amount) external {
        require(msg.sender == gameContract, "E1");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        require(msg.sender == gameContract, "E2");
        _burn(account, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount || msg.sender == gameContract, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);

        return true;
    }

}