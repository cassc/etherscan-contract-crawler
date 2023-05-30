// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract wGoo is ERC20("wGoo", "wGOO"), Ownable {
    address public wGooMinter;

    error Unauthorized();

    constructor() {
    }

    modifier onlywGooMinter() {
        if (msg.sender != wGooMinter) revert Unauthorized();
        _;
    }

    function mint(address to, uint256 amount) external onlywGooMinter {
        _mint(to, amount);
    }

    function burn(uint256 amount) external onlywGooMinter {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external onlywGooMinter {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        require(allowance(account_, msg.sender) >= amount_, "Insufficent allowance.");
        uint256 decreasedAllowance_;
        unchecked {
            decreasedAllowance_ = allowance(account_, msg.sender) - amount_;
        }
        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }

    function changeMinter(address newMinter) external onlyOwner {
        wGooMinter = newMinter;
    }

}