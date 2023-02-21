// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/UnknownMetadata.sol";

/**

  / / / /___  / /______  ____ _      ______  /   |  _____/ /_
 / / / / __ \/ //_/ __ \/ __ \ | /| / / __ \/ /| | / ___/ __/
/ /_/ / / / / ,< / / / / /_/ / |/ |/ / / / / ___ |/ /  / /_  
\____/_/ /_/_/|_/_/ /_/\____/|__/|__/_/ /_/_/  |_/_/   \__/

@title UnknownArt
@author UnknownArt
@notice Renders Something Unknown
*/

contract UnknownArt is Ownable, ERC721A {
  uint256 MAX_MINT = 10000;
  uint256 mintPrice = 0.005 ether;

  constructor() ERC721A("UnknownArt", "UNKNOWN") {
    _mint(msg.sender, 1);
  }

  function mint(uint256 quantity) external payable {
    require(quantity < 10, 'Exceeds Max Mint');
    require(_totalMinted() < MAX_MINT, "Exceeds total collection amount");
    require(
      mintPrice * quantity == msg.value,
      "Ether value sent is too low"
    );
    _mint(msg.sender, quantity);
  }

  function tokenURI(uint256 _tokenId) public pure override returns (string memory) {
    return UnknownMetadata.tokenURI(_tokenId);
  }

  //Why is this here?
  function burn(uint256 _tokenId) external {
	  _burn(_tokenId, true);
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}