// contracts/Token.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract Token is ERC20 {
    bool public transferCapEnabled;

    address constant DEPLOYER = 0xC01781CA6fE707bB5881982126558cCE8AfDeA99;

    string constant TOKEN_NAME = "BDSM Token";
    string constant TOKEN_SYMBOL = "BDSM";
    uint8 constant TOKEN_DECIMALS = 18;

    uint256 constant TOTAL_SUPPLY = 69000000000 * 10**18;
    uint256 constant TRANSFER_CAP_AMOUNT = 69000000 * 10**18;
    address constant UNISWAP_TEMP_HOLDER = 0x452DD852c697Cf9721406F76661fbC011a87E1bC;

    constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS) {
        transferCapEnabled = true;
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function disableTransferCap() external {
        require(msg.sender == DEPLOYER, "Only deployer can disable transfer cap");
        transferCapEnabled = false;
    }

    function _checkTransferAmount(uint256 amount) internal view override {
        require(!transferCapEnabled || amount <= TRANSFER_CAP_AMOUNT || tx.origin == DEPLOYER || tx.origin == UNISWAP_TEMP_HOLDER, "Transfer cap exceeded");
    }
}