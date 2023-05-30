// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./helpers/ERC20.sol";
import "./helpers/ERC20Burnable.sol";
import "./helpers/ERC20Decimals.sol";
import "./helpers/ERC20Mintable.sol";
import "./helpers/TokenRecover.sol";

import "../service/MetacryptHelper.sol";

contract Metacrypt_B_TR_MB_US_NC_X is ERC20Decimals, ERC20Mintable, ERC20Burnable, TokenRecover, MetacryptHelper {
    constructor(
        address __metacrypt_target,
        string memory __metacrypt_name,
        string memory __metacrypt_symbol,
        uint8 __metacrypt_decimals,
        uint256 __metacrypt_initial
    )
        payable
        ERC20(__metacrypt_name, __metacrypt_symbol)
        ERC20Decimals(__metacrypt_decimals)
        MetacryptHelper("Metacrypt_B_TR_MB_US_NC_X", __metacrypt_target)
    {
        _mint(_msgSender(), __metacrypt_initial);
    }

    function decimals() public view virtual override(ERC20, ERC20Decimals) returns (uint8) {
        return super.decimals();
    }

    function _mint(address account, uint256 amount) internal override onlyOwner {
        super._mint(account, amount);
    }

    function _finishMinting() internal override onlyOwner {
        super._finishMinting();
    }
}