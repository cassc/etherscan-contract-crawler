// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/BEP20Base.sol";
import "../services/FeeProcessor.sol";

/**
 * @dev BEP20Token implementation
 */
contract BEP20Token is BEP20Base, Ownable, FeeProcessor {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address payable feeReceiver_
    )
        payable
        BEP20Base(name_, symbol_, decimals_)
        FeeProcessor(feeReceiver_, 0x6df9baf4dc8c02086c72903e4bba587f1a261a8542aa45344809b4583161a59e)
    {
        require(initialSupply_ > 0, "BEP20Token: initial supply cannot be zero");
        _mint(_msgSender(), initialSupply_);
    }
}