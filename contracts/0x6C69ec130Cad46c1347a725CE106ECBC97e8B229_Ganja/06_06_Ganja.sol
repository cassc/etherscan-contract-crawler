//                  |
//                  |.|
//                  |.|
//                 |\./|
//                 |\./|
// .               |\./|               .
//  \^.\          |\\.//|          /.^/
//   \--.|\       |\\.//|       /|.--/
//     \--.| \    |\\.//|    / |.--/
//      \---.|\    |\./|    /|.---/
//         \--.|\  |\./|  /|.--/
//            \ .\  |.|  /. /
//  _ -_^_^_^_-  \ \\ // /  -_^_^_^_- _
//    - -/_/_/- ^ ^  |  ^ ^ -\_\_\- -
// Ganja Token
// Website: https://ganjalaboratory.net
// Twitter: https://twitter.com/GanjaLaboratory

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Ganja is Context, ERC20, Ownable {
    
    constructor() ERC20("Ganja Laboratory", "GANJA") {
        // Total circulating supply is capped at 420 billion GANJA tokens
        _mint(_msgSender(), 420_000_000_000 * (10 ** decimals()));
    }
}