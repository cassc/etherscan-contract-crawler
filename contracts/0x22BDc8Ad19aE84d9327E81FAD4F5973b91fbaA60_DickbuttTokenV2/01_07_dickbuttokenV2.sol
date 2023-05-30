//SPDX-License-Identifier: UNLICENSED
/*                                                                                     
                                      ........                                              
                              .:^~~~~~^^^::^^^~~~~~^:.                                      
                          :~!~^^:..               .:^^~~~:.                                 
                      .^!7~^.                           .^~~^.                              
                    :77~.       :^7?Y555$dick5YYJ7~^.       :~~^                            
                  ^?7:      :~7JJ??!~^:... ...:^~7J5P5?^.      ^!~.                         
                ^?7.      :!~^:.          :^^:      .^?5PY~      :!~                        
              .??.      .!57          ^!JJ?7!?5Y^       .7PG7.     ^7:                      
             :Y~       7PJ:       ?GBBG7       [email protected]         ^5B7     .7~                     
            ^Y:      ~G5:        [email protected]@@Y7P~ ~JJJ!.BP           ^GP:     !!                    
           ^5.      J&!          ?B75BP5^[email protected]@@P?PBY             Y#~     !!                   
          .5:      Y&^          [email protected]!              [email protected]~     7^                  
          J7      [email protected]~          J#.  .:^~~~~~^  G#.               J&:    .J.                 
         :P      ^@Y          ?#:             [email protected]~                 #P     ~!                 
         !#?     [email protected]^         :@~        .5:7 :&7          ^^:     [email protected]:    .?                 
         [email protected]@B~   B#          :#.        ?JJP GJ         7P7:G~    ^@!     7                 
         [email protected]@@&^ .##          :#.        5?P !&^^~!~:  !PJ. 7Y.    .&7     !                 
         [email protected]@@@G^ #&.         :#:       77G: 7G!!Y77YPY?. ~57      ^@!     ?                 
         [email protected]@@@@? [email protected]!          P?     :!7~Y:   :?Y??5#!  Y#!       [email protected]:    .?                 
         [email protected]@@@7 ^@B          ~&^    :7JY?~     ~^ .~BP.:7Y?     .#5     ~!                 
          [email protected]@@#:  [email protected]          7G7:    .      ^!..   :@^ !5      7#:     J.                 
           [email protected]@G    [email protected]      :~: .G5Y?~:.      :!    ^JP?77!     ^G~     7~                  
           [email protected]@7    [email protected]    7J!7J?7J!??JJYJ.^!~~!^7J?^         :J~     !!                   
            [email protected]#.    ^^      ?^!J?^   !PY#?~G~!77!^.        ^!^!:     !!                    
              [email protected]            !?^     ^&7.:5:             ~J?:      .7~                     
               !BB~          .:        ^PJJ:          .^?Y?:       ~?:                      
                .?BY:       .~BGY7^.     :       .:~?JY?^        ~?~                        
                  :JGY^       .~?5PGGP5YJ?JJJJY555Y?~:        .~?~.                         
                    .!55J~.         .^^!!!!!!~^:.          .^77~                            
                       :7YPPY?7!^::~^~^:               .:~!7~.                              
                          .^75G&@@@@@@@@&##PY^   .:^^!!7!^.                                 
                               .^!?J5PGBBBB##P!77!!~^.                                      
                                                                                                    
                                                                                                    
                                                                                                    
                                                                

                                Dickbutt Token V2
*/
pragma solidity ^0.8.0;
import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract DickbuttTokenV2 is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Dickbutt Token (V2)", "$dick") {
        _mint(msg.sender, 6969420420 * 10 ** decimals());
    }
}