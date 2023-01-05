// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/BEP20Base.sol";
import "../libraries/BEP20Burnable.sol";
import "../services/FeeProcessor.sol";

/**
 * @dev BEP20Token implementation with Burn capabilities
 */
contract BEP20Token is BEP20Base, BEP20Burnable, Ownable, FeeProcessor {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address payable feeReceiver_
    )
        payable
        BEP20Base(name_, symbol_, decimals_)
        FeeProcessor(feeReceiver_, 0x62f82bfb12293508c21ea2c2b41d3c4c151c0c8953e36abdb802cfcf09f9aa26)
    {
        require(initialSupply_ > 0, "BEP20Token: initial supply cannot be zero");
        _mint(_msgSender(), initialSupply_);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     * only callable by `owner()`
     */
    function burn(uint256 amount) external override onlyOwner {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     * only callable by `owner()`
     */
    function burnFrom(address account, uint256 amount) external override onlyOwner {
        _burnFrom(account, amount);
    }
}