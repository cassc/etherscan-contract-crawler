// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ROJIStandardERC721ARentableBurnableTransferFilter } from  "@rojiio/roji-smartcontracts-evm-core/contracts/v4/nfts/ROJIStandardERC721ARentableBurnableTransferFilter.sol";


/// @title cs_devCoins / common.space
/// @author Martin Wawrusch for Roji Inc.
/// @custom:security-contact [email protected]
contract cs_devCoins is ROJIStandardERC721ARentableBurnableTransferFilter {
    constructor() 
                    ROJIStandardERC721ARentableBurnableTransferFilter( 1000,
                                                       "cs_devCoins", 
                                                       "CSDEVCOINS", 
                                                       "ipfs://QmSxYtapMTzEQzw3UHQDAmgpxt4pfoxCP4DnBiCZkzYrZM/") {
   }
}