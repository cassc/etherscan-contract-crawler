// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BSTN is ERC20 {

    /// @notice EIP-20 token name for this token
    string public constant name = "Bastion";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "BSTN";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /**
     * @notice Construct a new BSTN token
     * @param account The initial account to grant all the tokens
     */
    constructor(address account) public {
	    _mint(account, 5000000000e18);
    }
}