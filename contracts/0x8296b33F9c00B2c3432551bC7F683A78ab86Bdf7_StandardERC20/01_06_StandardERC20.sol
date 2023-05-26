pragma solidity ^0.8.0;

import "./ERC20Decimals.sol";


/**
 * @title StandardERC20
 * @dev Implementation of the StandardERC20
 */
contract StandardERC20 is ERC20Decimals {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialBalance_
    )
        payable
        ERC20(name_, symbol_)
        ERC20Decimals(decimals_)
    {
        require(initialBalance_ > 0, "MUSKERS: supply cannot be zero");

        _mint(_msgSender(), initialBalance_);
    }

    function decimals() public view virtual override returns (uint8) {
        return super.decimals();
    }
}