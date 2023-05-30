// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract TEST is ERC721Enumerable {
  
  constructor() ERC721("TEST", "TEST"){
  }

  function mint() public {
    _safeMint(msg.sender, totalSupply());
  }

  function tokenURI(uint256 _tokenId) public view override returns(string memory) {
    return "just testing fren ;D";
  }

  function burn(uint256 tokenId) public virtual {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "a");
      _burn(tokenId);
  }

}//end