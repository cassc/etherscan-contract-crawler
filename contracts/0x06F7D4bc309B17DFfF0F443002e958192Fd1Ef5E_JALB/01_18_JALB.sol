// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./OnchainERC721JM.sol";
import "./interfaces/IPixArtNFT.sol";

/**                                 
                                 █████████
                              ███████████████
                              ███████████████
                              ███████████████
                                 █████████
                                    ███
                     █████████████████████████████████
                  ▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒█████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓
                  ▓▓▓            █████████                        ▓▓▓
         ░░░      ▓▓▓            ███████████████                  ▓▓▓
      ░░░         ▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███▒▒▒▒▒▒███▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓         ░░░
░░░   ░░░         ▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███▒▒▒▒▒▒███▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓      ░░░   ░░░
   ░░░      ░░░   ▓▓▓░░░            ███      ███               ▒▒▒▓▓▓      ░░░
   ░░░      ░░░   ▓▓▓░░░            ███      █████▌    JALB    ▒▒▒▓▓▓      ░░░
*/

/// @title JALB
/// @author justalittlebit.me
/// @notice JALB is a collection of 1010 unique NFTs.
contract JALB is OnchainERC721JM {
    constructor(
        string memory tokenName,
        string memory symbol,
        uint256 collectionSize,
        uint256 devReserved,
        uint256 _royalties,
        address[] memory _beneficiary
    ) OnchainERC721JM(tokenName, symbol, collectionSize, devReserved, _royalties, _beneficiary) {
        ERC721JM.price = 0.03 ether;
    }
}