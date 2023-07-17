// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**

 _____      _    ______            _    ___  ___           _
|  __ \    | |   | ___ \          | |   |  \/  |          (_)
| |  \/ ___| |_  | |_/ / ___ _ __ | |_  | .  . | __ _ _ __ _  ___
| | __ / _ \ __| | ___ \/ _ \ '_ \| __| | |\/| |/ _` | '__| |/ _ \
| |_\ \  __/ |_  | |_/ /  __/ | | | |_  | |  | | (_| | |  | | (_) |
 \____/\___|\__| \____/ \___|_| |_|\__| \_|  |_/\__,_|_|  |_|\___/


We have had enough of his face. Time to fund a movement to stop him from Twitter.

*/
contract GetBentMario is ERC20, Ownable {
    constructor() ERC20("Get Bent Mario", "FMARIO") {
        _mint(msg.sender, 1_000_000 * 1e18);
    }

    function burnToTheGround(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
}