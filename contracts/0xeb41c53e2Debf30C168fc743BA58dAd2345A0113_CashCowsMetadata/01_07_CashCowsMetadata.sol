// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//-------------------------------------------------------------------------------------------
//
//   /$$$$$$                      /$$              /$$$$$$                                   
//  /$$__  $$                    | $$             /$$__  $$                                  
// | $$  \__/  /$$$$$$   /$$$$$$$| $$$$$$$       | $$  \__/  /$$$$$$  /$$  /$$  /$$  /$$$$$$$
// | $$       |____  $$ /$$_____/| $$__  $$      | $$       /$$__  $$| $$ | $$ | $$ /$$_____/
// | $$        /$$$$$$$|  $$$$$$ | $$  \ $$      | $$      | $$  \ $$| $$ | $$ | $$|  $$$$$$ 
// | $$    $$ /$$__  $$ \____  $$| $$  | $$      | $$    $$| $$  | $$| $$ | $$ | $$ \____  $$
// |  $$$$$$/|  $$$$$$$ /$$$$$$$/| $$  | $$      |  $$$$$$/|  $$$$$$/|  $$$$$/$$$$/ /$$$$$$$/
//  \______/  \_______/|_______/ |__/  |__/       \______/  \______/  \_____/\___/ |_______/
//
//-------------------------------------------------------------------------------------------
//
// Moo.

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IMetadata.sol";
import "./IRoyaltySplitter.sol";

// ============ Contract ============

contract CashCowsMetadata is Ownable, IMetadata {
  using Strings for uint256;

  // ============ Errors ============

  error InvalidCall();

  // ============ Storage ============

  //base URI
  string private _baseTokenURI;
  //maps stage # to limit
  //ex. stage 0 -> less than 0.001 eth
  mapping(uint256 => uint256) private _stages;
  //we need the splitter to determine which cow to show
  IRoyaltySplitter private _treasury;
  
  // ============ Read Methods ============

  /**
   * @dev Returns the stage given the token id
   */
  function stage(uint256 tokenId) public view returns(uint256) {
    if (address(_treasury) == address(0)) revert InvalidCall();
    //get releaseable
    uint256 releaseable = _treasury.releaseable(tokenId);
    //loop through stages
    for(uint256 i; true; i++) {
      if (_stages[i] == 0) return i == 0 ? i : i - 1;
      if (releaseable < _stages[i]) return i;
    }

    return 0;
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(
    uint256 tokenId
  ) external view returns(string memory) {
    //if no base URI
    if (bytes(_baseTokenURI).length == 0) revert InvalidCall();

    return string(
      abi.encodePacked(
        _baseTokenURI, 
        tokenId.toString(), 
        "_", 
        stage(tokenId).toString(), 
        ".json"
      )
    );
  }
  
  // ============ Write Methods ============

  /**
   * @dev Sets stage limit ex. stage 0 -> less than 0.001 eth
   */
  function setStage(uint256 number, uint256 limit) external onlyOwner {
    _stages[number] = limit;
  }

  /**
   * @dev Setting base token uri would be acceptable if using IPFS CIDs
   */
  function setBaseURI(string memory uri) external onlyOwner {
    _baseTokenURI = uri;
  }

  /**
   * @dev Sets the royalty splitter so we know what cow to show
   */
  function setTreasury(
    IRoyaltySplitter treasury
  ) external onlyOwner {
    _treasury = treasury;
  }
}