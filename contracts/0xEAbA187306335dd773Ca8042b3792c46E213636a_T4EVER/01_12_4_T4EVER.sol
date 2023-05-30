// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0/contracts/presets/ERC20PresetMinterPauser.sol";

contract T4EVER is ERC20PresetMinterPauser {
    constructor() public ERC20PresetMinterPauser("Temporary 4EVER Token", "T-4EVER") {
        super._setupDecimals(18);
    }
}