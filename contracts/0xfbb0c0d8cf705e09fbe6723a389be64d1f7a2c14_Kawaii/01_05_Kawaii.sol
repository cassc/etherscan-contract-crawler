// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Website: https://kawaii20.wtf/
// Twitter: https://twitter.com/CoinKawaii69
// Telegram: https://t.me/+8IOvbVd0TtYwZTM5

// KKKKKKKKK    KKKKKKK                                                                          iiii    iiii  
// K:::::::K    K:::::K                                                                         i::::i  i::::i 
// K:::::::K    K:::::K                                                                          iiii    iiii  
// K:::::::K   K::::::K                                                                                        
// KK::::::K  K:::::KKK  aaaaaaaaaaaaawwwwwww           wwwww           wwwwwwwaaaaaaaaaaaaa   iiiiiii iiiiiii 
//   K:::::K K:::::K     a::::::::::::aw:::::w         w:::::w         w:::::w a::::::::::::a  i:::::i i:::::i 
//   K::::::K:::::K      aaaaaaaaa:::::aw:::::w       w:::::::w       w:::::w  aaaaaaaaa:::::a  i::::i  i::::i 
//   K:::::::::::K                a::::a w:::::w     w:::::::::w     w:::::w            a::::a  i::::i  i::::i 
//   K:::::::::::K         aaaaaaa:::::a  w:::::w   w:::::w:::::w   w:::::w      aaaaaaa:::::a  i::::i  i::::i 
//   K::::::K:::::K      aa::::::::::::a   w:::::w w:::::w w:::::w w:::::w     aa::::::::::::a  i::::i  i::::i 
//   K:::::K K:::::K    a::::aaaa::::::a    w:::::w:::::w   w:::::w:::::w     a::::aaaa::::::a  i::::i  i::::i 
// KK::::::K  K:::::KKKa::::a    a:::::a     w:::::::::w     w:::::::::w     a::::a    a:::::a  i::::i  i::::i 
// K:::::::K   K::::::Ka::::a    a:::::a      w:::::::w       w:::::::w      a::::a    a:::::a i::::::ii::::::i
// K:::::::K    K:::::Ka:::::aaaa::::::a       w:::::w         w:::::w       a:::::aaaa::::::a i::::::ii::::::i
// K:::::::K    K:::::K a::::::::::aa:::a       w:::w           w:::w         a::::::::::aa:::ai::::::ii::::::i
// KKKKKKKKK    KKKKKKK  aaaaaaaaaa  aaaa        www             www           aaaaaaaaaa  aaaaiiiiiiiiiiiiiiii

pragma solidity ^0.8.0;

contract Kawaii is ERC20 {
    constructor(uint256 _totalSupply) ERC20("KAWAII", "KAWAII") {
        _mint(msg.sender, _totalSupply);
    }
}