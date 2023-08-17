// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LX_Debt is ERC20 {
    constructor() ERC20(unicode"凉兮债券FuckSEIFuckCyberConnectFuckCCFuckBTCFuckETH", unicode"凉兮债券") {
        uint256 tokenSupply = 10000000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}