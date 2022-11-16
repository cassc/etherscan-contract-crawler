// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@rojiio/roji-smartcontracts-evm-core/contracts/nfts/ROJIStandardERC721ARentableBurnable.sol";


/// @title Roji Soulbound NFTs for corporate use
/// @author Martin Wawrusch for Roji Inc.
/// @custom:security-contact [email protected]
contract Roji is ROJIStandardERC721ARentableBurnable {
    constructor() 
                    ROJIStandardERC721ARentableBurnable( 0,
                                                       "Roji", 
                                                       "ROJI", 
                                                       "https://static.rojiapi.com/meta-roji/") {
   }
}