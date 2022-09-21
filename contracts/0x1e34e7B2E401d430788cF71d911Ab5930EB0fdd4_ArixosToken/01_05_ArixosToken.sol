pragma solidity ^0.8.0;

/**
 * This token represents the shares of the Arixos Verwaltuns Ltd.
 * Company register number 04793613
 *
 * Source code deployed by CPI Technologies GmbH
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ArixosToken is ERC20 {
    uint8 private _decimals;
    address private _initialReceiver;

    constructor(
        string memory name,
        string memory symbol,
        uint256 amount,
        uint8 decimals,
        address initialReceiver
    )
    ERC20(name, symbol)
    public {
        _decimals = decimals;
        _initialReceiver = initialReceiver;
        _mint(initialReceiver, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}