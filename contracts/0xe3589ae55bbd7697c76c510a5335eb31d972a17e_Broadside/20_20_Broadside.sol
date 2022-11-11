// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ERC721PartnerSeaDropBurnable
} from "../extensions/ERC721PartnerSeaDropBurnable.sol";

/*
  .~?JJJJJJJJJJJJJJJJJJJJJ?!^.                                                                      :~7?JJJJJJJJJJJJJJJJJJJJJ7:                                     
  !&@@@@@@@@@@@@@@@@@@@@@@@@&G?:                                                                 .!5#&@@@@@@@@@@@@@@@@@@@@@@@@P.                                    
  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@B~                                                               .Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@B:                                                              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@&~                                                              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@@@@@@&&&&&&&&&&&&G^..............................................................J#&&&&&&&&&@@@@@@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@@@&#BB############BGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGB#########BBB#@@@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@@#G#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BG&@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@#P&@@@@@@@@@@@@@@@@@@@@@@@###@@##&@&##&&##@@&##@@@&###@@@@@@@##&@@&##&@@@@@@@@@@@@@@@@@@@@@@@@@&P&@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@&5&@@@@@@@@@@@@@@@@@@@@@@@@?:^GB^:Y&!:^B7:[email protected]@5:^##J~::^[email protected]@@@&!:J&J^^^^7#@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@G. 77  ^J. ?&! ~BBJ :B7      :[email protected]@@&^ ?G. ~5YP#@@@@@@@@@@@@@@@@@@@@@@@@@5#@@@@@@@@@@@@G.                                    
  ~&@@@@@@@@@@P#@@@@@@@@@@@@@@@@@@@@@@@@@@?  .   . ^#@! .^^: :B~       [email protected]@@&^ ?&P7^:~J#@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@5                                     
  .Y&@@@@@@@@@5&@@@@@@@@@@@@@@@@@@@@@@@@@@B:  ^7  [email protected]@! ~BBJ :B7      :[email protected]@@&^ ?&PJ5?  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@B^                                     
   .7G&@@@@@@@5&@@@@@@@@@@@@@@@@@@@@@@@@@@@J::5B^:7&@@7:[email protected]@5:^##J~::^[email protected]@@@&!:J#?^^^^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@#Y^                                      
     .~?5GGGG5?&@@@@@@@@@@@@@@@@@@@@@@@@@@@&##&@##&@@@###@@&##@@@&###@@@@@@@##&@@&###&@@@@@@@@@@@@@@@@@@@@@@@@@@B~7YPGGGPY!:                                        
         .... ~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B.   ...                                            
              ~&@@@BBBB&@@#BB#@@&BBBB&@#BBBB&@@@@&BBBBBB#&@@@BBB#@@@&BBB#@#BBBBBBBBB&@@@@#BBBB#@@@@&BBBBB#&@@@@@B.                                                  
              ~&@@&[email protected]&!..~#@Y...^#B^....?&@@@G:.....:~5&#^[email protected]@@B:..J&!........^#@@@#~....!&@@@#:....:~?G&@@B.                                                  
              ~&@@@P.  ^#P.   5#^   Y&7     [email protected]@@G.       .P#:  [email protected]@@B.  ?&~  .?????J&@@@J     [email protected]@@B:       .?&@B.                                                  
              ~&@@@&7   ?~    ^J   ~&P.      ~#@@G.        5#:  ~GGG5.  ?&~  :PGGG#@@@@G:      ^[email protected]@B:         [email protected]                                                  
              ~&@@@@G.  .      .  .G#^        [email protected]@G.      .7##:   ...    ?&~   [email protected]@@&!        7&@B:         [email protected]                                                  
              ~&@@@@@?     :^     ?&J         :[email protected]     :P&@#:  ^JJJ?.  ?&~  :[email protected]@@5.        [email protected]:         [email protected]                                                  
              ~&@@@@@B:    YP.   ^#G:  :J557   !&G.  7^  7#@#:  [email protected]@@B.  ?&~  :5PPPPP&B^  .J55?   ~#B:        ^[email protected]                                                  
              ~&@@@@@@J   ^#&~  .Y&!  [email protected]@@#~  .5G.  YP:  !##:  [email protected]@@B.  ?&~        :B?   ?&@@&!   JB:     .^[email protected]@B.                                                  
              ~&@@@@@@&[email protected]@B55P&&555P&@@@@B555G#[email protected]&[email protected]@@&[email protected]#P555&@@@@#555P&55555PG#@@@@B.                                                  
              ~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B.                                                  
              ~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B.                                                  
              ~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G5YJY5B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B.                                                  
              ~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G~.     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B.                                                  
              ~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y~^^J57   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B.                                                  
              ~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&##P7  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B.                                                  
              ^&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P^. :7P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B.                                                  
              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y                                                   
               ~#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BGG#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G:                                                   
                ^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&7^^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P^                                                    
                 .7G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G7.                                                     
                   .~?PB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BPJ~.                                                       
                       .~Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#?:                                                          
        .:^^:..       :7G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&5~. :7G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G7.       .:^^::.                                          
     ^?PB#&&#BPJ~.  :?B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#5~.     .!P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G?:  :75G##&##GY!.                                       
   :Y#@@@@@@@@@@&5^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5^          [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@&G!                                      
  [email protected]@@@@@@@@@@@@@BY&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#^      .      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G5&@@@@@@@@@@@@@&!                                     
  [email protected]@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@5~:.:!5BJ^..:[email protected]@@@@@@@@@@@@@@@@@@BP&@@@@@@@@@@@@@@@J#@@@@@@@@@@@@@@@P.                                    
  [email protected]@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@&#B#&@@@&BB#&@@@@@@@@@@@@@@@@@@@B^.~5&@@@@@@@@@@@@@J#@@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@@@@@YG#####&&@@@@#Y^  :[email protected]@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@B~   .~5#@@@&&######J#@@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@@@@@#GBBBBBGGPGBJ^     .?G&@@@@@@@@@&@@@@@@@@@@B. [email protected]@@@@@@@@@@@@@@@@@@@&BY^       ^YGGPGBBBBBBG&@@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@#P~        .^!J&@@@@&[email protected]@@@@@@@@B. [email protected]@@@@@@@@[email protected]@@@@P!~:         .?B&@@@@@@@@@@@@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@#7          ^&@@@@&^ ~&@@@@@@@@B. [email protected]@@@@@@@@5  [email protected]@@@@J           :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@#^         [email protected]@@@&^ ~&@@@@@@@@B. [email protected]@@@@@@@@5  [email protected]@@@#~           [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@&~          :5&@@&^ ~&@@@@@@@@B. [email protected]@@@@@@@@5  [email protected]@@B!            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@P.           .~YGB^ ~#&&&&&&&&G. 7&&&&&&&&&Y  YB57:             7&@@@@@@@@@@@@@@@@@@@@@@@@@@@@G.                                    
  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@&5:               .:  .^~~~~~~~~^  :~~~~~~~~~:  ..                .7#@@@@@@@@@@@@@@@@@@@@@@@@@@@G.                                    
  ~B&@@@@@@@@@@@@@@@@@@@@&&#BY~.                                                                  :?P#&&&@@@@@@@@@@@@@@@@@@@&&Y                                     
   :~!!!!!!!!!!!!!!!!!!!!~~:.                                                                       .:^~!!!!!!!!!!!!!!!!!!!!~^.                                     
*/

/**
 * @notice This contract uses ERC721PartnerSeaDropBurnable,
 *         an ERC721A token contract that is compatible with SeaDrop,
 *         along with a burn function only callable by the token owner.
 */
contract Broadside is ERC721PartnerSeaDropBurnable {
    /**
     * @notice Deploy the token contract with its name, symbol,
     *         administrator, and allowed SeaDrop addresses.
     */
    constructor(
        string memory name,
        string memory symbol,
        address administrator,
        address[] memory allowedSeaDrop
    )
        ERC721PartnerSeaDropBurnable(
            name,
            symbol,
            administrator,
            allowedSeaDrop
        )
    {}
}