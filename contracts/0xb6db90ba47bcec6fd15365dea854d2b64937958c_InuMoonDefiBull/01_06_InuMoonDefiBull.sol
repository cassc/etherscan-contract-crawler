// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**

██╗███╗   ███╗██████╗ ██████╗
██║████╗ ████║██╔══██╗██╔══██╗
██║██╔████╔██║██║  ██║██████╔╝
██║██║╚██╔╝██║██║  ██║██╔══██╗
██║██║ ╚═╝ ██║██████╔╝██████╔╝
╚═╝╚═╝     ╚═╝╚═════╝ ╚═════╝

IMDB: Inu Moon Defi Bull
*/

contract InuMoonDefiBull is ERC20, Ownable {
    constructor() ERC20("Inu Moon Defi Bull", "IMDB") {
        _mint(msg.sender, 69_420_000 * 1e18);
    }

    function burn(uint256 amt) external {
        _burn(msg.sender, amt);
    }
}