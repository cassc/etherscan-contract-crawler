// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@rojiio/roji-smartcontracts-evm-core/contracts/nfts/ROJIStandardERC721ARentableBurnableTransferFilter.sol";

/// @title The Convergence Drop
/// @author Martin Wawrusch for Roji Inc.
/// @custom:security-contact [email protected]
contract ConvergenceArtGallery is ROJIStandardERC721ARentableBurnableTransferFilter {
    constructor() 
                    ROJIStandardERC721ARentableBurnableTransferFilter( 
                                                        750,
                                                       "Convergence Art Gallery", 
                                                       "CONVERGENCE", 
                                                       "https://static.rojiapi.com/meta-convergence-art-gallery/") {
   }
}