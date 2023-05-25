// SPDX-License-Identifier: MIT

/*
You wouldn't find the website here 
You wouldn't find twitter account
(However, You can make one if you want)

What are you doing here? - Me? Hmm, nothing, just hanging around...

                    THE TRUE DEGEN BEETLEJUICE STORY

And now the assignment folks:
    1. Post memes with Beetlejuice to twitter with your wallet address
    2. Fill the whole twitter with $BEETLE mentions 
        2.1 maybe worth mentioning the BEETLE ERC-20 address
    3. The most liked tweet will get some $BEETLE from the Deployer

Just some basic requirements here, you can go full degen mode here and do whatever you want 
#PEPEKILLER, mhm, what do you think? You can hang around as long as you want

And now listen, some sanity checks, yeah?
BEETLE DEPLOYER: 0xfc0cA001ad829E6F7fB168a00964788240F2A01E

Wanna check the contract?
Check the code below
                                                                                                                                     
                                           .^!7!~:.                                                 
                                         :?5PPPPPP5Y7:                                              
                                        ~5PP555555PGBG~                                             
                                       ^5555555PPPPPGGG:                                            
                                      .YP55PPGGGGPPPPGBY                                            
                                      !BGGPGBBGGPGGGGGGB!                                           
                                      ?BGGPPGGPGPPGGGGGGG^                                          
                                      ?#B5YY5PGGGGPPGGGGB?                                          
                                      :5P555GGPPPPPPPGGGG?                                          
                                       ~PPPGGPPPPPPPPGGGGY                                          
                                       .YPGGGGGPGGGGGGGGGG~                                         
                                        ^PBGGGPGGBBBBGGGGG5^                                        
                                         :?GGGGBBBGBBBGGG5557:.                                     
                                           :JGBBBGGBBBB5YJ?77!!~:.                                  
                                             :PBBBBBG5J?77!!7!!!!~^:.                               
                                            .:?55YJJ?777!!!!!!!~~~~~~^:                             
                                         .:^~!!!7777!!!!!!!!!!!!~~~~~~!~:.                          
                                       .:^~~!~~~!!!!!!!!!!!!!!!!~~~~~~~!!~^.                        
                                      .^~~~!!~~!!~~~~~!!!!!!7!!~~!!!~~~~~~!!^.                      
                                     .^~~~~!~~!!~~~~~~!!!!!?7!!!!!~~~~~~~~~~77                      
                                    .^~~~~7!!!!~~~~!!!!!!!J?!777!77!~~!~~~~~~?^                     
                                   .~~~~!7??!~~~~!!!!!!!!?Y?7777777!!!!!!!!~~!~                     
                                  .^~!!!77?7~~~~!!!!!!!!!JJ?7777777!!!!!!!!~~!~                     
                                  ^!!!!!~7J!!~~~!!!!!7777YJ77777?7!!!!!!!!!!!!~                     
                                 .~~~!!~7J!!!!!!!!!!!7777Y7777???7!!!!!!!!!!!!~.                    
                                 .~!!!7??!~~7?YJ77777777??777???77!!!!!!!!!!~!!:                    
                                 ^777777!!!7JJ5J777777??JJ77????77!!!!!!!!!!!!7^                    
                                .!!~!!!!7!7???5?7???77?JJJ7?JJ?777!!!!!!!!!!!~!~                    
                                :!!!!!!!!!7?Y55?7?JJ???JYJ??JJ?7777!!!!!!!!!!!!~                 
*/

pragma solidity ^0.8.9;
// What we see here?
// OpenZeppelin audited ERC20 smart contract
import "./ERC20.sol";

// Not ownable smart contract, nobody can change it
contract Beetlejuice is ERC20 {
    constructor() ERC20("Beetlejuice", "BEETLE") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}