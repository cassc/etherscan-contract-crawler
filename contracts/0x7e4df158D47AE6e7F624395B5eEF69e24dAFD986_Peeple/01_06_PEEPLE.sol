// SPDX-License-Identifier: MIT
//
//
//                                                                                                                                   
//                                                        
//                                                                                                         
//                                                                                                        
//                   PPPPPPPPPPPPPPPPP                                                             lllllll                     
//                    P::::::::::::::::P                                                            l:::::l                     
//                    P::::::PPPPPP:::::P                                                           l:::::l                     
//                    PP:::::P     P:::::P                                                          l:::::l                     
//                    P::::P     P:::::P  eeeeeeeeeeee        eeeeeeeeeeee    ppppp   ppppppppp    l::::l     eeeeeeeeeeee    
//                    P::::P     P:::::Pee::::::::::::ee    ee::::::::::::ee  p::::ppp:::::::::p   l::::l   ee::::::::::::ee  
//                   P::::PPPPPP:::::Pe::::::eeeee:::::ee e::::::eeeee:::::eep:::::::::::::::::p  l::::l  e::::::eeeee:::::ee
//                    P:::::::::::::PPe::::::e     e:::::ee::::::e     e:::::epp::::::ppppp::::::p l::::l e::::::e     e:::::e
//                    P::::PPPPPPPPP  e:::::::eeeee::::::ee:::::::eeeee::::::e p:::::p     p:::::p l::::l e:::::::eeeee::::::e
//                    P::::P          e:::::::::::::::::e e:::::::::::::::::e  p:::::p     p:::::p l::::l e:::::::::::::::::e 
//                    P::::P          e::::::eeeeeeeeeee  e::::::eeeeeeeeeee   p:::::p     p:::::p l::::l e::::::eeeeeeeeeee  
//                    P::::P          e:::::::e           e:::::::e            p:::::p    p::::::p l::::l e:::::::e           
//                    PP::::::PP        e::::::::e          e::::::::e           p:::::ppppp:::::::pl::::::le::::::::e          
//                   P::::::::P         e::::::::eeeeeeee   e::::::::eeeeeeee   p::::::::::::::::p l::::::l e::::::::eeeeeeee  
//                    P::::::::P          ee:::::::::::::e    ee:::::::::::::e   p::::::::::::::pp  l::::::l  ee:::::::::::::e  
//                   PPPPPPPPPP            eeeeeeeeeeeeee      eeeeeeeeeeeeee   p::::::pppppppp    llllllll    eeeeeeeeeeeeee  
//                                                                            p:::::p                                        
//                                                                            p:::::p                                        
//                                                                            p:::::::p              https://t.me/PeepleETH                         
//                                                                            p:::::::p              https://twitter.com/PeepleETH                           
//                                                                            p:::::::p                                       
//                                                                            ppppppppp                                       
                                                                                                          

                                                                                                         

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Peeple is ERC20, Ownable {
    constructor() ERC20("Peeple", "PEEPLE") {
        _mint(msg.sender, 690000000 * 10 ** decimals());
    }
}