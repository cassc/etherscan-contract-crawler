/* SPDX-License-Identifier: MIT

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                                                                
                                                                                
                                                                                
         (@@@@@@#   .@                                                          
     @@@@@@@@@@@@@@@@@@@*                                %@@@@#          (@@@@& 
  ,@@@@@@@&*..*&@@@@@@@@#                               .@@@@@@@@      @@@@@@@@,
 &@@@@@*     &@@@@@@@@@@@                                  %@@@@@@@%#@@@@@@@&   
 @@@@@    .@@@@@@@@#@@@@@/                                   .@@@@@@@@@@@@.     
*@@@@@  &@@@@@@@@   %@@@@%                                     #@@@@@@@@%       
 @@@@@@@@@@@@@(    .@@@@@.                                   @@@@@@@@@@@@@@.    
  @@@@@@@@@@     .@@@@@@,                                 %@@@@@@@&  %@@@@@@@&  
,@@@@@@@@@@@@@@@@@@@@@&                                 @@@@@@@@.       @@@@@@@@
  .@@@@@@@@@@@@@@@@&                                      &@@#            #@*/

pragma solidity 0.8.18;

/**
 *   @title AEW Wrestlers Collection
 *   @author Fr0ntier X <[email protected]>
 *   @notice ERC-721 token
 */

// IMX support
import "@imtbl/imx-contracts/contracts/Mintable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/// @custom:security-contact [email protected]
contract AEWWrestlers is ERC721, Pausable, Ownable, ERC721Burnable, Mintable {
  using Strings for uint256;

  // Base URL for the metadata
  string public baseURI = "";

  /**
    @dev Default constructor
     */
  constructor(address ownerInit, address imxInit) ERC721("AEWWrestlers", "AEWWRESTLERS") Mintable(ownerInit, imxInit) {}

  /**
    @dev Change the base URI for the metadata
    @param uri new base URI
     */
  function setBaseURI(string memory uri) external onlyOwner {
    baseURI = uri;
  }

  /**
    @dev Pause the contract
     */
  function pause() public onlyOwner {
    _pause();
  }

  /**
    @dev Unpause the contract
     */
  function unpause() public onlyOwner {
    _unpause();
  }

  // Called at the time of withdrawing a minted token from IMX L2 to Mainnet L1.
  function _mintFor(address to, uint256 id, bytes memory) internal override whenNotPaused {
    _safeMint(to, id);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}