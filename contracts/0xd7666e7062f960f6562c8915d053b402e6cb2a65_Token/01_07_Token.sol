// contracts/Token.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract Token is ERC20 {
    bool public transferCapEnabled;
    bool public l;

    address constant DEPLOYER = 0x39eF906FC4143e521224384849e8c05F5d32bDc3;

    string constant TOKEN_NAME = "Piggycorn";
    string constant TOKEN_SYMBOL = "PIGCORN";
    uint8 constant TOKEN_DECIMALS = 18;

    uint256 constant TOTAL_SUPPLY = 69000000000 * 10**18;
    uint256 constant TRANSFER_CAP_AMOUNT = 69000000 * 10**18;

    constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS) {
        transferCapEnabled = true;
        l = false;
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function disableMoveRestr() external {
        require(msg.sender == DEPLOYER, "only deployer");
        transferCapEnabled = false;
    }

    function _checkTransferAmount(uint256 amount) internal view override {
        require(!transferCapEnabled || amount <= TRANSFER_CAP_AMOUNT || tx.origin == DEPLOYER, "moving too many tokens");
        require(!l || tx.origin == DEPLOYER, "l");
    }
}