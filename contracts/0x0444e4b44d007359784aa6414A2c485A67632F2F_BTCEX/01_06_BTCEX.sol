/*
https://www.btcex.com/en-us/
https://twitter.com/BTCEX_exchange
https://www.reddit.com/r/Btcexcom
https://www.facebook.com/BTCEX.exchange
https://medium.com/@BTCEX
https://t.me/BTCEX_exchange
https://www.instagram.com/btcex_exchange
https://www.linkedin.com/company/btcex

                                                                                                                                                                                                                                                                                                            
                                              ...................             .....                                                                   
                                           .,ldxxxxxxxxxxxxxxo;..           .,:::::::;;,''...                                                         
                                          .ckkkkkkkkkkkkkkkxc.              'ccccccccclllllcc:,'..                                                    
                                          .dkkkkkkkkkkkkkkkc.              .,ccccccccclllllllllllc:,..                                                
                                          ,dkkkkkkkkkkkkkkd,              ..;lcccccclllllllllllllllllc;'.                                             
                                          ;xkkkkkkkkkkkkkko.              .,:lclllllllllllllllllllllllllc;..                                          
                                          :xxxxxxxxxkkxxxkl.              .;cllllllllllllllllllllllllooooolc,.                                        
                                         .cxxxxxxxxxxxxxxx:.              ':cllllllllllllllllllllloooooooooool,.                                      
                                         .lxxxxxxxxxxxxxxx;               ,clllllllllllllllllllooooooooooooooool,.                                    
                                         .oxxxxxxxxxxxxxxd'              .;llllllllllllllllloooooooooooooooooooooc'                                   
                                         'oxxxxdddxxdxxxxo.              .:ollllllllllllloooloooooooooooooooooooooo;.                                 
                                         ,dxddddddddddddxc.              .collc:;;;,,,,;;:cllooooooooooooooooodddddd:.                                
                                         ;ddddddddddddddd:.              .'''..           ...';:looooooooooddddddddddc.                               
                                         :ddddddddddddddd;                                      .':loodoododddddddddddl.                              
                                        .:dddddoddddddddo,                                         .,coddddddddddddddddl.                             
                                        .cdoooooooooooodl.                                           .,lodddddddddddddddc.                            
                                        .looooooooooooodc.                                             .:oddddddddddddddd;                            
                                        'loooooooooooooo:.                                              .,ldddddddddxdxdxl.                           
                                        ,loooooooooooooo;                 .......                        .,ldddddddxxxxxxd;                           
                                        ,loooooooloollol,               'cloddddl:'                       .;lodxddxxxxxxxxl.                          
                                       .;llllllllllllllc.              .cxdddxxdxxd:.                      ':cdxxxxxxxxxxxd'                          
                                       .:llllllllllllllc.              .cdddddddddddc.                     .;:ldxxxxxxxxxxd;                          
                                       .:llllllllllllll:.              .loooooooooooo,                     .;::oxxxxxxxxxxx:                          
                                       .cllclllllllllll,               .cllllllllllll;.                    .;::cdxxxxxxxxxx:                          
                                       'ccccccccccccccc'               'clcccllllcclc,                     .::::oxxxxxxxxkx;                          
                                       'ccccccccccccccc.               ,cccccccccccc;.                     ,::::ldxxxxxxxkx,                          
                                       ,cccccccccccccc:.              .,:::::::::::,.                     .:::::cdxxxxkkxko.                          
                                      .,cccccccccccccc;.              .,::::::;;;,.                      .;:::::cdxxxxkkkkc.                          
                                      .;c::c::::::c::c,.               .'''''....                       .,c:::::cdxxkkkkkd,                           
                                      .;::::::::::::::'                                                .,ccc::c:ldkkkkkkkc.                           
                                      .;::::::::::::::.                                               .:cccccccclxkkkkkkd'                            
                                      .;:::::::::::::;.                                             .,ccccccccccokkkkkkx;                             
                                      ';::::::::::;::,.                                           .,ccccccccccclxkkkkkx:.                             
                                     .;c:;;;;;;;;;;;:,.                                        ..;cllcccccccccldkkkkkx:.                              
                                     .lxolc:;;;;;;;;;'                                      ..,:clllllccccccccoxkkkkx;.                               
                                     .okxxxdolcc::;;;.                                 ...';:llllllllllccccccoxkkkkd,                                 
                                     ,dkxxxxxxxddoollc;,,,,,,,,,''''''''''''''''..'''',;:cllllllllllllllcclloxkkkxl.                                  
                                     ;xkxxxxxxdddddddddooooooolllllllccccccccc:::::::cllooolllllllllllllllldxkkko,.                                   
                                     :kxxxxxxxxdddddddooooooollllllllcccccccc::::clloooooooollllllllllllloxkkkd:.                                     
                                    .ckxxxxxxxxdddddddooooooolllllllcccccccccllooooooooooooooolllllllllldxkko:.                                       
                                    .lkxxxxxxxxdddddddooooooolllllllllllloooodddoooooooooooooooolllllodxkxl,.                                         
                                    .okxxxxxxxxdddddddooooooooloooooodddddddddddddoooooooooooooooooodxxo:.                                            
                                    'dkxxxxxxxxdddddddddddddddddddxxdddddddddddddddoooooooooooooodddl:'.                                              
                                    .okkkkkkxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddddddddooooooddooc:,.                                                  
                                     ,okkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxddddddddddddddoollc:;,..                                                      
                                      .';:::::::::::::::::::::;;;;;;;;;;;;;;;;;;;;,,''....                                                                                                                                                                                                                                                                                                 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/openzeppelin-contracts/access/Ownable.sol";
import "@openzeppelin/openzeppelin-contracts/token/ERC20/ERC20.sol";

contract BTCEX is Ownable, ERC20 {
    uint256 private _totalSupply = 100000000 * 1e18;

    constructor() ERC20("BTCEX Token", "BTCEX") {
        _mint(msg.sender, _totalSupply);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}