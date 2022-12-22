// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/*
                                     @@@@@@@@                                   
                                 @@@@@@@@@@@@@@@                                
                               @@@@@ @@ @  @ @@@@@                              
                              @@@@@@ @@ @  @ @@@@@@                             
                             @@@@ @@ @@ @  @ @@ @@@@                            
     @@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@ @@ @ #@ @@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@    
      @@@@@@@@@@@@@@@@@@@@@@@@@@@ @@ @@ @#@@ @@ @@@@@@@@@@@@@@@@@@@@@@@@@@@     
        @@@@@                @@@@ @@ @@ @@@@ @@ @@@@@                @@@@       
         @@@@@               @@@@*@@ @@ @@@@ @@ @@@@               @@@@@        
          #@@@@    /@@@@@     @@@@@@ @@ @@@@,@@ @@@(     @@@@@    @@@@@         
            @@@@     @@@@*    @@@@@@ @@[email protected]@@@@@@ @@@     @@@@     @@@@           
             @@@@&    &@@@     @@@@@ @@@@@@@@@@@@@     @@@@     @@@@            
               @@@@     @@@    #@@@@ @@@@@@@@@@@@@    @@@     @@@@@             
                @@@@     @@@    @@@@(@@@@@@@@@@@@    @@@     @@@@               
                 @@@@      @@    @@@@@@@@@@@@@@@@   @@      @@@@                
                   @@@      @@   @@@@@@@@@@@@@@@    @      @@@(                 
                    @@@@          @@@@@@@@@@@@@           @@@                   
                     @@@@         @@@@@@@@@@@@@         @@@@                    
                       @@@   &@@   @@@@@@@@@@@   @@@   @@@                      
                        @@@@@@@@,   @@@@@@@@@@   @@@@@@@@                       
                          @@@@@@@   @@@@@@@@@   @@@@@@@@                        
                              @@@@   @@@ @@@   @@@@                             
                               @@@@  @@@ @@@   @@@                              
                                @@@   @   @   @@@                               
                                  @@      @  @@@                                
                                   @@       [email protected]                                  
                                    @       @                                   
                                     @     @                                    
                                          @                                     
*/

import "../extensions/ERC721Airdroppable.sol";
import "../utils/Terms.sol";

/**
 * @dev This implements an optional extension of {ERC721Airdroppable}
 */
contract ScottiePippenSP33MysteryBox is ERC721Airdroppable, Terms {
    /**
     * @notice ScottiePippenSP33MysteryBox constructor.
     *
     * @param name The token name.
     * @param symbol The token symbol.
     */
    constructor(string memory name, string memory symbol)
        ERC721Airdroppable(name, symbol)
    {
        // Set the default termsURI
        termsURI = "ipfs://QmTVp9aDwZYG9mFoxvL2SZ9wJUSNiUjz5haSSsqTtdJX5q";

        // Initial maxSupply is 1100
        _maxSupply = 1100;

        // Initial token base URI
        _baseTokenURI = "https://api.orangecomet.io/collectible-metadata/scottie-pippen-sp33-mystery-box/";

        // Initial contract URI
        _contractURI = "https://api.orangecomet.io/collectible-contracts/scottie-pippen-sp33-mystery-box/opensea";
    }
}