// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "./ERC20.sol";

contract Bitconnect20 is ERC20 {

    uint256 private constant _MAX_SUPPLY = 420_690_000_000_000 ether;

    /// @dev Transfer to zero address.
    error TransferZeroAddress();

    /// @dev Transfer zero amount.
    error TransferZeroAmount();

    constructor(address _recipient) {
        _mint(_recipient, _MAX_SUPPLY);
    }

    /// @dev Returns the name of the token.
    function name() public pure override returns (string memory) {
        return "BitConnect 2.0";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public pure override returns (string memory) {
        return "BITCONNECT2.0";
    }

    function _beforeTokenTransfer(address, address to, uint256 amount) internal override virtual {
        if (to == address(0)) revert TransferZeroAddress();
        if (amount == 0) revert TransferZeroAmount();
    }
}
