// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract PreUranoERC777 is ERC777 {

    // solhint-disable-next-line
    constructor()
        ERC777("PRE URANO ECOSYSTEM", "PRE-URANO", new address[](0))
    {
        _mint(msg.sender, (50 * 10 ** 9) * ( 10 ** 18), "", "");
    }
}