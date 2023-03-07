// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./BEP20Base.sol";
import "./BEP20Burnable.sol";
import "./BEP20Capped.sol";
import "./BEP20Mintable.sol";
import "./FeeProcessor.sol";

/**
 * @dev BEP20Token implementation with Mint, Burn, Cap capabilities
 */
contract BEP20Token is BEP20Base, BEP20Burnable, BEP20Mintable, BEP20Capped, Ownable, FeeProcessor {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        uint256 maxSupply_,
        address payable feeReceiver_
    )
        payable
        BEP20Base(name_, symbol_, decimals_)
        BEP20Capped(maxSupply_)
        FeeProcessor(feeReceiver_, 0x17607acad1a06c3a6ec736586b667adc5b3f722f95dcf534c702b8887c2e9621)
    {
        if (initialSupply_ > 0) _mint(_msgSender(), initialSupply_);
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

    /**
     * @dev Mint new tokens
     * only callable by `owner()`
     */
    function mint(address account, uint256 amount) external override onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Mint new tokens
     */
    function _mint(address account, uint256 amount) internal virtual override(BEP20, BEP20Capped, BEP20Mintable) {
        super._mint(account, amount);
    }

    /**
     * @dev stop minting
     * only callable by `owner()`
     */
    function finishMinting() external virtual override onlyOwner {
        _finishMinting();
    }
}