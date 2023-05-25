// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/*//////////////////////////////////////////////////////////////
                         CUSTOM ERROR
//////////////////////////////////////////////////////////////*/

error ZeroAddress();

/*//////////////////////////////////////////////////////////////
                          CONTRACT
//////////////////////////////////////////////////////////////*/

/// @title STFX Token
/// @author 0xHessian (https://github.com/0xHessian)
/// @author 7811 (https://github.com/cranium7811)
contract STFX is ERC20("STFX", "STFX") {
    // Maximum supply of tokens
    uint256 public constant MAX_SUPPLY = 1_000_000_000e18;

    /// @dev Mints the max supply to the treasury.
    /// @dev Revert if the input address is address(0).
    /// @param _treasury Address of the treasury.
    constructor(address _treasury) {
        if (_treasury == address(0)) revert ZeroAddress();
        _mint(_treasury, MAX_SUPPLY);
    }
}