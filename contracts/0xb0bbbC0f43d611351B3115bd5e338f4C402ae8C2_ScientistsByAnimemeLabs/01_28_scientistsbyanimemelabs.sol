// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@rojiio/roji-smartcontracts-evm-core/contracts/nfts/ROJIStandardERC721AWithMinterPaid.sol";

contract ScientistsByAnimemeLabs is ROJIStandardERC721AWithMinterPaid {
    constructor( string memory domainVerifierAppName_,
                 string memory domainVerifierAppVersion_,
                 address allowlistSignerAddress_) 
                    ROJIStandardERC721AWithMinterPaid( 0.1 ether, 
                                                       1,
                                                       655, // added 1 for animemelabs test
                                                       750, 
                                                       "Scientists by Animeme Labs", 
                                                       "SCIENTISTS", 
                                                       "https://static.rojiapi.com/meta-animemelabs-scientists/",
                                                        domainVerifierAppName_,
                                                        domainVerifierAppVersion_,
                                                        allowlistSignerAddress_) {
   }
}