/*

                                                                                                               
                                                                                                               
     000000000                         lllllll                                                         lllllll 
   00:::::::::00                       l:::::l                                                         l:::::l 
 00:::::::::::::00                     l:::::l                                                         l:::::l 
0:::::::000:::::::0                    l:::::l                                                         l:::::l 
0::::::0   0::::::0xxxxxxx      xxxxxxx l::::l    ooooooooooo yyyyyyy           yyyyyyyaaaaaaaaaaaaa    l::::l 
0:::::0     0:::::0 x:::::x    x:::::x  l::::l  oo:::::::::::ooy:::::y         y:::::y a::::::::::::a   l::::l 
0:::::0     0:::::0  x:::::x  x:::::x   l::::l o:::::::::::::::oy:::::y       y:::::y  aaaaaaaaa:::::a  l::::l 
0:::::0 000 0:::::0   x:::::xx:::::x    l::::l o:::::ooooo:::::o y:::::y     y:::::y            a::::a  l::::l 
0:::::0 000 0:::::0    x::::::::::x     l::::l o::::o     o::::o  y:::::y   y:::::y      aaaaaaa:::::a  l::::l 
0:::::0     0:::::0     x::::::::x      l::::l o::::o     o::::o   y:::::y y:::::y     aa::::::::::::a  l::::l 
0:::::0     0:::::0     x::::::::x      l::::l o::::o     o::::o    y:::::y:::::y     a::::aaaa::::::a  l::::l 
0::::::0   0::::::0    x::::::::::x     l::::l o::::o     o::::o     y:::::::::y     a::::a    a:::::a  l::::l 
0:::::::000:::::::0   x:::::xx:::::x   l::::::lo:::::ooooo:::::o      y:::::::y      a::::a    a:::::a l::::::l
 00:::::::::::::00   x:::::x  x:::::x  l::::::lo:::::::::::::::o       y:::::y       a:::::aaaa::::::a l::::::l
   00:::::::::00    x:::::x    x:::::x l::::::l oo:::::::::::oo       y:::::y         a::::::::::aa:::al::::::l
     000000000     xxxxxxx      xxxxxxxllllllll   ooooooooooo        y:::::y           aaaaaaaaaa  aaaallllllll
                                                                    y:::::y                                    
                                                                   y:::::y                                     
                                                                  y:::::y                                      
                                                                 y:::::y                                       
                                                                yyyyyyy                                        
                                                                                                               
                                                                                                               

                                   
*/
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Loyal is Context, ERC20, ERC20Burnable, Ownable {
    
    constructor() ERC20("0xLoyal", "0xLoyal") {
        _mint(_msgSender(), 100000000 * (10 ** decimals())); 
    }
}