/*

__________                       ___________.__               ________                      __   
\______   \ ____ ______   ____   \__    ___/|  |__   ____    /  _____/______   ____ _____ _/  |_ 
 |     ___// __ \\____ \_/ __ \    |    |   |  |  \_/ __ \  /   \  __\_  __ \_/ __ \\__  \\   __\
 |    |   \  ___/|  |_> >  ___/    |    |   |   Y  \  ___/  \    \_\  \  | \/\  ___/ / __ \|  |  
 |____|    \___  >   __/ \___  >   |____|   |___|  /\___  >  \______  /__|    \___  >____  /__|  
               \/|__|        \/                  \/     \/          \/            \/     \/      




WEB: https://pepethegreat.com
TG:  https://t.me/PepetheGreatPortal
TW:  https://twitter.com/Pepe_the_Great_
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepeTheGreat is ERC20 {
    constructor() ERC20("Pepe the Great", "KINGPE") {
        _mint(msg.sender, 69_420_000_000 * 10**18);
    }
}