// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MutantApeYachtClub
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                      //
//                                                                                                      //
//    pragma solidity 0.8.0;                                                                            //
//                                                                                                      //
//    import "https://github.com/0xcert/ethereum-erc721/src/contracts/tokens/nf-token-metadata.sol";    //
//    import "https://github.com/0xcert/ethereum-erc721/src/contracts/ownership/ownable.sol";           //
//                                                                                                      //
//    contract newNFT is NFTokenMetadata, Ownable {                                                     //
//     constructor() {                                                                                  //
//       //define nft name of choice and symbol                                                         //
//       nftName = "Mutant Ape Yacht CIub      ";                                                       //
//       nftSymbol = "BAYC";                                                                            //
//     }                                                                                                //
//                                                                                                      //
//     function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {          //
//       super._mint(_to, _tokenId);                                                                    //
//       super._setTokenUri(_tokenId, _uri);                                                            //
//     }                                                                                                //
//    }                                                                                                 //
//                                                                                                      //
//                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MAYC is ERC721Creator {
    constructor() ERC721Creator("MutantApeYachtClub", "MAYC") {}
}