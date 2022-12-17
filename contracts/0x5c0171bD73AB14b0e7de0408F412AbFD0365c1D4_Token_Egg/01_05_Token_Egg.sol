// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token_Egg is ERC20 {
    constructor(address _castleAddress, address _teamWallet) ERC20("$TALE", "$TALE") {
        // 1,000,000 initial supply
        _mint(_castleAddress, 5_000);
        _mint(_teamWallet, 495_000);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}