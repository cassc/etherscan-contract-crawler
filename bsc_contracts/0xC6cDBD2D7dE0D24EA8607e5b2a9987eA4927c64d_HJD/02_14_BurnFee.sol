// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Owned.sol";
import "./ERC20.sol";

abstract contract BurnFee is Owned, ERC20 {
    uint256 constant burnFee = 1;

    function _takeBurn(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 burnAmount = (amount * burnFee) / 100;
        super._transfer(sender, address(0xdead), burnAmount);
        return burnAmount;
    }
}