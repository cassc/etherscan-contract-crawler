// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@rojiio/roji-smartcontracts-evm-core/contracts/nfts/ROJIStandardERC721ARentableBurnableWithMinterPaidTransferFilter.sol";

/// @title The Flowers For Hope Premier Drop
/// @author Martin Wawrusch for Roji Inc.
/// @custom:security-contact [email protected]
contract FlowersForHopePremier is ROJIStandardERC721ARentableBurnableWithMinterPaidTransferFilter {
    constructor() 
                    ROJIStandardERC721ARentableBurnableWithMinterPaidTransferFilter( 
                      0.38 ether,
                      100,
                      380,
                                                        750,
                                                       "Flowers For Hope Premier", 
                                                       "FFHPREMIER", 
                                                       "") {
   }
}