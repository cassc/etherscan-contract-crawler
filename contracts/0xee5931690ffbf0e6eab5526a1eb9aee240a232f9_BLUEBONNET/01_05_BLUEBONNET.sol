/// SPDX-License-Identifier: MIT
/// @title Bonnets Token
/// @author Blue Flower Development

pragma solidity ^0.8.17;

import "./ERC20.sol";

contract BLUEBONNET is ERC20 {
    constructor() ERC20("Blue Bonnets Token","BLUEBONNET") {
        //  Create 1 Trillion Tokens
        uint intitialTotalSupply = 1e30;
        // To start things off, because the The OA Can never Mint
        _mint(msg.sender, intitialTotalSupply);
    }

    receive()
    payable
    external
    {
        uint256 fallbackfail = 1;
        require(fallbackfail == 0, string(abi.encodePacked(name(), ": Do not send ETH!")));
    }

    fallback() external {}
}

