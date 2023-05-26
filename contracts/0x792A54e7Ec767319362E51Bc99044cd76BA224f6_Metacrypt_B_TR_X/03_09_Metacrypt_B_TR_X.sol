// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./helpers/ERC20.sol";

import "./helpers/ERC20Decimals.sol";

import "../service/MetacryptHelper.sol";
import "../service/MetacryptGeneratorInfo.sol";
import "./helpers/TokenRecover.sol";

contract Metacrypt_B_TR_X is ERC20Decimals, TokenRecover, MetacryptHelper, MetacryptGeneratorInfo {
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
        MetacryptHelper("Metacrypt_B_TR_X", __metacrypt_target)
    {
        require(__metacrypt_initial > 0, "ERC20: supply cannot be zero");

        _mint(_msgSender(), __metacrypt_initial);
    }
}