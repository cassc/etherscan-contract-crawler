// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/// @custom:security-contact [email protected]
contract FakeToken is BaseContract, ERC20Upgradeable {
    /**
     * Contract initializer.
     * @param name_ Token name.
     * @param symbol_ Token symbol.
     */
    function initialize(string memory name_, string memory symbol_) initializer public {
        __BaseContract_init();
        __ERC20_init(name_, symbol_);
    }

    /**
     * Free minting!
     * @param amount_ Amount to mint (no decimals).
     */
    function mint(uint256 amount_) external
    {
        _mint(msg.sender, amount_ * (10 ** decimals()));
    }

    /**
     * Free mint to address!
     * @param to_ Address to mint to.
     * @param amount_ Amount to mint (no decimals).
     */
    function mintTo(address to_, uint256 amount_) external
    {
        _mint(to_, amount_ * (10 ** decimals()));
    }
}