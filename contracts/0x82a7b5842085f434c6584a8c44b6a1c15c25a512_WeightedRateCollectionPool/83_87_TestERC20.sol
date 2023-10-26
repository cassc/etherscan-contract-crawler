// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

/**
 * @title Test ERC20 Token
 */
contract TestERC20 is ERC20PresetFixedSupply {
    /**************************************************************************/
    /* Properties */
    /**************************************************************************/

    uint8 private _decimals;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice TestERC20 constructor
     * @notice name Token name
     * @notice symbol Token symbol
     * @notice decimals Token decimals
     * @notice initialSupply Initial supply
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 initialSupply
    ) ERC20PresetFixedSupply(name, symbol, initialSupply, msg.sender) {
        _decimals = decimals_;
    }

    /**************************************************************************/
    /* Overrides */
    /**************************************************************************/

    /**
     * @inheritdoc ERC20
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}