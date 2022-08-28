// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Dummy is ERC721AQueryable, ERC2981 {
 
  // Number of tokens that will be preminted to the contract owner
  uint16 public constant PREMINT_TOKEN_COUNT = 2;

   constructor() ERC721A("Testing", "Test") {
    // Check for plausible input

    // Set the royalties to the owner
    _setDefaultRoyalty(msg.sender, 750);

    // Premint the first tokens to the owner
    _safeMint(msg.sender, PREMINT_TOKEN_COUNT);

  }

  
  /**
   * @dev Override support interface for ERC721A and ERC2981
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC721A, ERC721A, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @notice Prevent users from sending eth directly to the contract
   */
  receive() external payable {
    revert();
  }

}