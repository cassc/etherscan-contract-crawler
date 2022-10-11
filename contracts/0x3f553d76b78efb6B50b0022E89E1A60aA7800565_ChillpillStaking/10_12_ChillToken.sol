// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.15;

/*
  /$$$$$$ /$$   /$$/$$$$$$/$$      /$$      /$$$$$$$ /$$$$$$/$$      /$$      
 /$$__  $| $$  | $|_  $$_| $$     | $$     | $$__  $|_  $$_| $$     | $$      
| $$  \__| $$  | $$ | $$ | $$     | $$     | $$  \ $$ | $$ | $$     | $$      
| $$     | $$$$$$$$ | $$ | $$     | $$     | $$$$$$$/ | $$ | $$     | $$      
| $$     | $$__  $$ | $$ | $$     | $$     | $$____/  | $$ | $$     | $$      
| $$    $| $$  | $$ | $$ | $$     | $$     | $$       | $$ | $$     | $$      
|  $$$$$$| $$  | $$/$$$$$| $$$$$$$| $$$$$$$| $$      /$$$$$| $$$$$$$| $$$$$$$$
 \______/|__/  |__|______|________|________|__/     |______|________|________/                                                                                                                                                                                                                               
*/

/// ============ Imports ============

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ChillToken is ERC20 {
    /// @notice address permissioned to mint new $CHILL tokens
    address public immutable minter;

    constructor(address _minter) ERC20("CHILL", "CHILL") {
        minter = _minter;
    }

    /// @notice only minter modifier
    modifier onlyMinter() {
        require(
            msg.sender == minter,
            "not authorized to mint new $CHILL tokens"
        );

        _;
    }

    /// @notice mints new $CHILL token
    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }
}