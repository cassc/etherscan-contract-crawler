// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20Base.sol";
import "../features/ERC20BurnFeature.sol";
import "../features/ERC20MintFeature.sol";

contract BurnMintTemplate is ERC20Base, ERC20BurnFeature, ERC20MintFeature {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 amount_
    ) public initializer {
        __ERC20Base_init(name_, symbol_, decimals_, amount_);
        __ERC20MintFeature_init_unchained();
    }
}