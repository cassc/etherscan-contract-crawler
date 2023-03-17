// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@rojiio/roji-smartcontracts-evm-core/contracts/nfts/ROJIStandardERC721ARentableBurnableWithMinterPaidTransferFilter.sol";

/// @title The Flowers For Hope Patron Drop
/// @author Martin Wawrusch for Roji Inc.
/// @custom:security-contact [email protected]
contract FlowersForHopePatron is ROJIStandardERC721ARentableBurnableWithMinterPaidTransferFilter {
    constructor() 
                    ROJIStandardERC721ARentableBurnableWithMinterPaidTransferFilter( 
                      0.038 ether,
                      100,
                      1380,
                                                        750,
                                                       "Flowers For Hope Patron", 
                                                       "FFHPATRON", 
                                                       "") {

   }
}