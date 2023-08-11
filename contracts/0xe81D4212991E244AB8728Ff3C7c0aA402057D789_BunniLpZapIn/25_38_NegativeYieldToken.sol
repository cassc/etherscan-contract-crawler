// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {Gate} from "./Gate.sol";
import {BaseERC20} from "./lib/BaseERC20.sol";

/// @title NegativeYieldToken
/// @author zefram.eth
/// @notice The ERC20 contract representing negative yield tokens
contract NegativeYieldToken is BaseERC20 {
    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(Gate gate_, address vault_)
        BaseERC20(
            gate_.negativeYieldTokenName(vault_),
            gate_.negativeYieldTokenSymbol(vault_),
            gate_,
            vault_
        )
    {}
}