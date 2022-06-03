/*

                                                                   
                                                                    [email protected]&Y.                                                                  
                                                                   ^[email protected]@#&G^                                                                 
                                                                  7&@@@##&B!                                                                
                                                                 [email protected]@@@@#####J.                                                              
                                                               :[email protected]@@@@@#####&P:                                                             
                                                              !#@@@@@@@######&B!                                                            
                                                             [email protected]@@@@@@@@#########J                                                           
                                                           :[email protected]@@@@@@@@@#########&P:                                                         
                                                          ~#@@@@@@@@@@@##########&B~                                                        
                                                         [email protected]@@@@@@@@@@@@#############?                                                       
                                                       :[email protected]@@@@@@@@@@@@@#############&5:                                                     
                                                      :[email protected]@@@@@@@@@@@@@@##############&G:                                                    
                                                       7B&&&@@@@@@@@@@@###########BBBG7                                                     
                                                        ^P&####&&&@@@@@######BBBBGGBP^                                                      
                                                         .Y#########&&&#BBBBGGGGGBBY.                                                       
                                                           7#&#########BGGGGGGGGBG7                                                         
                                                            ^G&########BGGGGGGBBP~                                                          
                                                             .Y&#######BGGGGGBBY:                                                           
                                                               7#######BGGGGBB?                                                             
                                                                ~G&####BGGBBP~                                                              
                                                                 .5&###BGBB5:                                                               
                                                                   ?###BBB?                                                                 
                                                                    ~B#BG!                                                                  
                                                                     :P5:                                                                   
           .^!J5PGGGGP5J!.                                             .                                                                    
        ^?G##B5J7~^^::[email protected]@#^                                                                                                                 
     :[email protected]~!PY?:    ^#@@&^                                                               ::.                                               
   :[email protected]@G#J  [email protected]@@G  .?&@@G^                                                               [email protected]&#~                                              
  7&@#~ :: [email protected]@@B::?#@&P~                                                                 [email protected]@&^                                              
  [email protected]&:   [email protected]@@B?5&&P7:                                                                   .^~^                                               
  :?7   ^[email protected]@@@@@@#PJ!.      :!?YJ?~.JJ7.   !JJ7:    :YP!    ^7JYJ7.!YJ~    7YJ^  ^?JJ^  YG5!      .~?YY?!.?Y?^   .JJ7:   :7Y5J:   .!JPP5P5^ 
       7&@@BJ?!^::[email protected]@&?   ~P&@#J~!#[email protected]@@Y   [email protected]@@#:    [email protected] [email protected]@P!^Y##@@@^   [email protected]@[email protected]@@7 [email protected]@@#.   :Y#@@5!~GB&@@#.  [email protected]@@5 ~5P#@@@~  ?#@B?^[email protected] 
      [email protected]@@5.  .^^ [email protected]@@# [email protected]@@Y.   [email protected]@@&^  .#@@@&:   [email protected]^~#@@#~   [email protected]@@@5   [email protected]@@@[email protected]@J ^#@@@7   ?&@@G:   [email protected]@@@?  :#@@&YPP!Y&@@Y  [email protected]@#:  [email protected] 
     [email protected]@&J^[email protected]@@&[email protected]@@7    [email protected]@@#^   [email protected]@@@5    [email protected][email protected]@@G:   [email protected]@@Y   [email protected]@@&? [email protected]@5 :#@@&7   [email protected]@@5    :#@@@7  [email protected]@@&G! [email protected]@@5   ^&@@#?:~^   
     J&@#557^  :[email protected]@@G~ [email protected]@@?    !&@@B:  [email protected]@@@&^  :P&!:&@@#:   [email protected]@@J  .?&@@#~  :?J^:[email protected]@&!  :[email protected]@@P    :[email protected]@&!  :[email protected]@@#7  [email protected]@@Y   7BP~J#@#Y:   
     ^BB!.   [email protected]@@G!  .#@@G   :[email protected]@@G. ~PBY&@@@Y .?#G^ [email protected]@@!   [email protected]@@? .?#@@@B^       [email protected]@&~ ^5B&@@&:  .?#@@&~ :Y&@@@Y.  [email protected]@@5  7GG7~~  [email protected]@5   
    .#@~.^75#@@BJ^     [email protected]@[email protected]@@Y?GB?..&@@@J?GP~   ~&@@[email protected]@&[email protected]@@B:       .#@@B7PBY:[email protected]@&7!YGP&@@G7P&@@@B~    [email protected]@@?JBG!:[email protected]?.^[email protected]^   
     ~JY5PG5J!:         !J5YJ!. !Y55J~    ~Y5Y?!:      :?Y5Y?^ .?55Y7::5P5^         :?Y5Y!.   ^J55J7: ^J55Y!~Y5?.     .75P5J^  :G#PPGY~       

*/

//SPDX-License-Identifier: MIT
//Creator: Sergey K. / 24acht GmbH 


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
@title Non-Fungible Bavarians Genesis Token Contract 
@author Sergey K. / 24acht GmbH
@notice This ERC721 smart contract mints the team owners tokens and sets the specific IPFS-URI's accordingly. 
The list owners and the token uri's can be read from outside.
@dev Contract build on ERC721 openzepplin implementation
**/

contract GenesisNFBToken is ERC721 {

  /*
    Array of the owners' chosen wallet addresses in following order:
    1. Björn
    2. Manu
    3. Chris
    4. Tom
    5. Dominic
    6. Dimitres
    7. Kilian
    8. Leander
    9. Sergey K.
    10. Anna
    11. Peter
  */
  address[11] public owners = [
    0x16D2462cCD6104536c2a2EE3BB1fd998bE5C10A4,
    0x70F754869F66874513722001CDFfFd1b42182082,
    0x27148f5434dee32B36A569579133590f2EEF82d8,
    0x79da143f4C00d478712C5ea118A3a8e961A78EB4,
    0x29adE4a7e6eBF34CBd66F67BF66B65f127257FaF,
    0x7390a047Ef77781638874CC68BA7950be89B7622,
    0x960C6307A073dBC8346b7A0a057216300d8cf3BB,
    0x696696A44Ae7C5dB8Fe5c2cBfcFFC9875Eee42C2,
    0xe1A0894FEFA69C5041AEdcC445c994964Dc9Ec56,
    0x8d4Cbdd0D4f08790DCD077F1f4B392A8b5749234,
    0xa838c28201aBb6613022eC02B97fcF6828B0862B
    ];
    
  
  //string containing the IPFS-URI of the tokens JSON metadata
  string private _tokenBaseURI = "ipfs://bafybeifnjklyzfqz2wvpc562hcxpouombfiff46xkpifup4xgezwuhyfhm/";

  /**
  @notice The tokens name is "Genesis Non-Fungible Bavarians". The token symbol is gNFB (to differentiate it from normal NFB's).
  @dev Mint one token for each owner wallet.
  **/
  constructor() ERC721("Genesis Non-Fungible Bavarians", "gNFB") {
    for(uint8 i = 0; i < owners.length; i++) {
      _mint(owners[i], i+1);
    }
  }


  /**
  Function to update the tokens metadat URI.
  @notice Only the orginial founders of the token (Björn, Manuel and Chris) can call this function!
  @dev The founders addresses are the first three entries in the owners-array.
   */
  function setNewURI(string memory _newURI) external {
    require(msg.sender == owners[0] || msg.sender == owners[1] || msg.sender == owners[2], "Only the tokens original founders can change the tokens metadata URI!");
    _tokenBaseURI = _newURI;
  }

  /** 
  @dev define base uri, which will later be used to create the full uri
  **/
  function _baseURI() override internal view returns(string memory) {
    return _tokenBaseURI;
  }

  /**
  * @dev Returns an URI for a given token ID
  */
  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    return string(abi.encodePacked(
        _baseURI(),
        Strings.toString(tokenId),
        ".json"
    ));
  }

}