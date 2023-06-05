// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Royalties/ERC2981/IERC2981Royalties.sol';
import '../Royalties/RaribleSecondarySales/IRaribleSecondarySales.sol';
import '../Royalties/FoundationSecondarySales/IFoundationSecondarySales.sol';

/// @dev This is a contract used for royalties on various platforms
/// @author Simon Fremaux (@dievardump)
interface IERC721WithRoyalties is
    IERC2981Royalties,
    IRaribleSecondarySales,
    IFoundationSecondarySales
{

}