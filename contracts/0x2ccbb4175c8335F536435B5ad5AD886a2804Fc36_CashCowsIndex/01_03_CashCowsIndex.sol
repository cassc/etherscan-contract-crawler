// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Supply is IERC721 {
  /**
   * @dev Returns the total amount of tokens stored by the contract.
   */
  function totalSupply() external view returns (uint256);
}

contract CashCowsIndex {
  /**
   * @dev Returns all the owner's tokens. This is an incredibly 
   * ineffecient method and should not be used by other contracts.
   * It's recommended to call this on your dApp then call `ownsAll`
   * from your other contract instead.
   */
  function ownerTokens(
    IERC721Supply collection,
    address owner
  ) external view returns(uint256[] memory) {
    //get the balance
    uint256 balance = collection.balanceOf(owner);
    //if no balance
    if (balance == 0) {
      //return empty array
      return new uint256[](0);
    }
    //this is how we can fix the array size
    uint256[] memory tokenIds = new uint256[](balance);
    //next get the total supply
    uint256 supply = collection.totalSupply();
    //next declare the array index
    uint256 index;
    //loop through the supply
    for (uint256 i = 1; i <= supply; i++) {
      try collection.ownerOf(i) 
      returns (address tokenOwner) {
        //if we found a token owner ows
        if (owner == tokenOwner) {
          //add it to the token ids
          tokenIds[index++] = i;
          //if the index is equal to the balance
          if (index == balance) {
            //break out to save time
            break;
          }
        }
      } catch (bytes memory) {}
    }
    //finally return the token ids
    return tokenIds;
  }
}