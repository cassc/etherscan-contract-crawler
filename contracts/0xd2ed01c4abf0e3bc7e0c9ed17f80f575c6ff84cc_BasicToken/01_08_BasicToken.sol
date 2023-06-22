// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/CopyrightToken.sol";
import "../services/FeeProcessor.sol";

/**
 * @dev BasicToken: Simple ERC20 implementation
 */
contract BasicToken is ERC20, CopyrightToken, FeeProcessor {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_,
        address payable feeReceiver_
    )
        payable
        ERC20(name_, symbol_)
        CopyrightToken("2.0")
        FeeProcessor(feeReceiver_, 0x557e307fa628c1ac98f985df1611392092f7032ac3b6956cc0856d25cb9e6ebc)
    {
        require(initialSupply_ > 0, "BasicToken: initial supply cannot be zero");
        _mint(_msgSender(), initialSupply_);
    }
}