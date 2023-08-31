// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @title: JCDVTokenURIContract
/// @author: white lights & sidewaysDAO

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDataCompiler.sol";
import "./ITokenURISupplier.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                ,,                                //
//                                              ╓φ░░░░φ                             //
//                                          ╓φ▒░░░░░░░╠▒                            //
//                                  ,,╓╔φ▒▒░░░░░░░░░▒╠╣▒                            //
//                          ,╓φφ▒▒░░░░░░░░░░░░░░▒▒╠╬╬╩                              //
//                      ╓φ╠░░░░░░░░░░░░░▒▒▒▒▒▒╠╠╬╬╣╩                                //
//                    φ╠╩░░░░░░░░░░▒▒▒▒▒╠╠╠╬╬╣╝╩╙`                                  //
//                  ;╠╩░░░░░░░░░░░░╚╚╚╚╚╚╚╚╚╚╚░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒φ╓    //
//                  ╔╠▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╠▒  //
//    ,╬╠▒▒▒φφσ╓,╓╬╠▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒╠╬   //
//    ╔╠▒╚╚╠╠╠╠╠╠╠╩▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╠╠╠╬╩   //
//  φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒╠╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╚╙╙╙╙╙╙╙└       //
//  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╠╠ε                               //
//  «░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒╠                              //
//  φ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒╠╩                              //
//  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒╠`                               //
//  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╠ε                               //
//  ╚░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒╠░                               //
//  ]▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░▒╠╩                                //
//  ╠▒▒╠╠╠╠╠╠╠╠╠╠╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╬╙                                  //
//  `╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╬▒                                   //
//    ╚╬╬╬╬╬╬╬╬╬╬╬╬╣╣╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠╠╠╠╠╠╠╬╬╬╬                                    //
//      `╚╣╣╣╝╩╩╙╙└`  ╙╚╝╣╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╩                                    //
//                          ╙╙╙╙╩╩╩╩╩╩╩╩╙╙╙                                         //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////

contract JCDVTokenURIContract is ITokenURISupplier, Ownable {
  mapping(uint256 => address) public tokenURIContracts;
  string public BASE = "https://arweave.net/bouiC3If6Ro4-UKd7UgRbkd6NTnLpsbtyyAevrF0LL8/";
  IDataCompiler private dataCompiler =
    IDataCompiler(0xc458129ECA3a3857E50E426107C631f0e99F211c);

  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
    return interfaceId == type(ITokenURISupplier).interfaceId;
  }

  function setTokenURIContractOverride(uint256 tokenId, address _tokenURIContract) public onlyOwner {
    tokenURIContracts[tokenId] = _tokenURIContract;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    BASE = baseURI;
  }

  function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
    // if the tokenURI has been overriden for a given tokenID, return that
    if (tokenURIContracts[tokenId] != address(0)) {
      return ITokenURISupplier(tokenURIContracts[tokenId]).tokenURI(tokenId);
    }

    return string(abi.encodePacked(BASE, dataCompiler.uint2str(tokenId), ".json"));
  }
}