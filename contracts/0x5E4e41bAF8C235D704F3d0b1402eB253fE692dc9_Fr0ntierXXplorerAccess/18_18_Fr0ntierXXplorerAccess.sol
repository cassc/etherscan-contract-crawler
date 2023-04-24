/* SPDX-License-Identifier: MIT

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                                                                
                                                                                
                                                                                
         (@@@@@@#   [email protected]                                                          
     @@@@@@@@@@@@@@@@@@@*                                %@@@@#          (@@@@& 
  ,@@@@@@@&*..*&@@@@@@@@#                               [email protected]@@@@@@@      @@@@@@@@,
 &@@@@@*     &@@@@@@@@@@@                                  %@@@@@@@%#@@@@@@@&   
 @@@@@    [email protected]@@@@@@@#@@@@@/                                   [email protected]@@@@@@@@@@@.     
*@@@@@  &@@@@@@@@   %@@@@%                                     #@@@@@@@@%       
 @@@@@@@@@@@@@(    [email protected]@@@@.                                   @@@@@@@@@@@@@@.    
  @@@@@@@@@@     [email protected]@@@@@,                                 %@@@@@@@&  %@@@@@@@&  
,@@@@@@@@@@@@@@@@@@@@@&                                 @@@@@@@@.       @@@@@@@@
  [email protected]@@@@@@@@@@@@@@@&                                      &@@#            #@*/

pragma solidity ^0.8.12;

/**
 *   @title Fr0ntierX Investor Access
 *   @author Fr0ntier X <[email protected]>
 *   @notice ERC-721 token for the Fr0ntierX Investor Access
 */

// IMX support
import "@imtbl/imx-contracts/contracts/Mintable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/// @custom:security-contact [email protected]
contract Fr0ntierXXplorerAccess is ERC721, Pausable, Ownable, ERC721Burnable, Mintable {
  using Strings for uint256;

  // Base URL for the metadata
  string public baseURI = "";

  /**
    @dev Default constructor
     */
  constructor(address _owner, address _imx) ERC721("Fr0ntierX Xplorer Access", "XPLORER") Mintable(_owner, _imx) {}

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