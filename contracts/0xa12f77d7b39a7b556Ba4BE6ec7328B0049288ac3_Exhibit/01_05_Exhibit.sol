// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Series.sol";


//  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓                    
//  ┃                              ┃                    
//  ┃                              ┃                    
//  ┃                              ┃                    
//  ┃          <exhibit>           ┃                    
//  ┃                              ┃                    
//  ┃                              ┃                    
//  ┃                              ┃                    
//  ┗━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━┛                    
//         │                                            
//         │                                            
//         │                       ...                  
//         │                   .::^^^^:::..             
//         │                 .::^^::^^^^^::::..         
//         └────────┐      .:^^^^:^^^^^^^^^^^^^^        
//                  │      ^~^^^^:^^^:::^^^^^~^::.      
//                  │     ^!^^^^^:::::.::::^^~!^^!:     
//                  │     !~~^^:::^^^:::::::^^^:^!!     
//                  │     ~~~^:::::::::::^^:::::~?7     
//                  │    .^^^^^^:::::::^^^^^~:^7JJ?     
//                  │   ~!!!7JYYY?!~~7?YJ?7!7~~JJJY7    
//                     !7?YPP??YPP7:^J5PJ7JYJ7!7JJJ:    
//                    :!?!^^^~!~^^^.:!!!~~^^~!77YY^     
//                    ~???!~^::::::..~~^:::^~7?7Y7      
//                    !J7J?!^^~!??!~~777~^^~7?7~?^      
//                    .^!!77!~^:~J555JJ?^^~77~~!7       
//                     ^7!~77~7YJJ?JYYJJY7!!!~!?J^      
//                      77!!???7!~~~!77!~~~77!?JJ?      
//                      .JY?!!^.::::..::..~777JJJY~     
//                        ?G5J?!~^^^~^^~~~?JJJJJ7!:     
//                        :BBGGGP5YJ55JYYYYJJJ?:        
//                         JBBBBBGGPPP5YYJJJJJ!.        
//                         .PBGBBGGP5YYYYYYYJ~.         
//                          ~BBBBBGP555555Y7^.         
//                           7PPPPPPP5YJ7~:             
//                             ...:....                                                                


contract Exhibit is Series {
    /**
     * @notice See {Series-constructor}
     */
    constructor(address implementation_, bytes memory initializeData) Series(implementation_, initializeData) {}

    /**
     * @notice Name-symbol metadata
     */
    function meta() external pure returns (string memory) {
        return "Exhibit by Highlight (EXHIBIT)";
    }
}