// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./helpers/ERC20.sol";
import "./helpers/ERC20Capped.sol";
import "./helpers/ERC20Burnable.sol";
import "./helpers/ERC20Decimals.sol";
import "./helpers/ERC20Mintable.sol";
import "./helpers/ERC20Ownable.sol";

import "../service/MetacryptHelper.sol";
import "../service/MetacryptGeneratorInfo.sol";
import "./helpers/TokenRecover.sol";

contract Metacrypt_B_TR_MB_X is
    ERC20Decimals,
    ERC20Capped,
    ERC20Mintable,
    ERC20Burnable,
    ERC20Ownable,
    TokenRecover,
    MetacryptHelper,
    MetacryptGeneratorInfo
{
    constructor(
        address __metacrypt_target,
        string memory __metacrypt_name,
        string memory __metacrypt_symbol,
        uint8 __metacrypt_decimals,
        uint256 __metacrypt_cap,
        uint256 __metacrypt_initial
    )
        payable
        ERC20(__metacrypt_name, __metacrypt_symbol)
        ERC20Decimals(__metacrypt_decimals)
        ERC20Capped(__metacrypt_cap)
        MetacryptHelper("Metacrypt_B_TR_MB_X", __metacrypt_target)
    {
        require(__metacrypt_initial <= __metacrypt_cap, "ERC20Capped: cap exceeded");
        ERC20._mint(_msgSender(), __metacrypt_initial);
    }

    function decimals() public view virtual override(ERC20, ERC20Decimals) returns (uint8) {
        return super.decimals();
    }

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) onlyOwner {
        super._mint(account, amount);
    }

    function _finishMinting() internal override onlyOwner {
        super._finishMinting();
    }
}