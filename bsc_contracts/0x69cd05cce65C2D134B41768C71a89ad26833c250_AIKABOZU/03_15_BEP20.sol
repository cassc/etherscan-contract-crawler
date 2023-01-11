//SPDX-License-Identifier: UNLICENSED
// File: contracts/token/BEP20/lib/BEP20.sol



pragma solidity ^0.8.0;


/**
 * @title BEP20
 * @dev Implementation of the {IBEP20} interface.
 */
import "./Ownable.sol";
import "./ERC20.sol";
import "./IBEP20.sol";
abstract contract BEP20 is Ownable, ERC20, IBEP20 {
    /**
     * @dev See {IBEP20-getOwner}.
     */
    function getOwner() public view virtual override returns (address) {
        return owner();
    }
}