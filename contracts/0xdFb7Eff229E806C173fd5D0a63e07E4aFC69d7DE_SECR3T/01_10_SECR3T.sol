// SPDX-License-Identifier: MIT

/* 
 $$$$$$\  $$\      $$\   $$\  $$$$$$\     $$$$$$$$\$$$$$$$$\ $$\   $$\ 
$$  __$$\ $$ |     $$ |  $$ |$$  __$$\    $$  _____\__$$  __|$$ |  $$ |
$$ /  \__|$$ |     $$ |  $$ |$$ /  \__|   $$ |        $$ |   $$ |  $$ |
$$ |$$$$\ $$ |     $$$$$$$$ |$$ |         $$$$$\      $$ |   $$$$$$$$ |
$$ |\_$$ |$$ |     $$  __$$ |$$ |         $$  __|     $$ |   $$  __$$ |
$$ |  $$ |$$ |     $$ |  $$ |$$ |  $$\    $$ |        $$ |   $$ |  $$ |
\$$$$$$  |$$$$$$$$\$$ |  $$ |\$$$$$$  |$$\$$$$$$$$\   $$ |   $$ |  $$ |
 \______/ \________\__|  \__| \______/ \__\________|  \__|   \__|  \__|
*/

// For Blockchain Solutions contact our telegram: @xGL8x

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SECR3T is ERC1155, Ownable {

  // Contract Author
  string constant public author = "GLHC.eth";
    
  string public name;
  string public symbol;

  mapping(uint => string) public tokenURI;

  constructor() ERC1155("") {
    name = "SECR3T Collection";
    symbol = "SECR3T";
  }

  function mint(uint _id) external onlyOwner {
    _mint(msg.sender, _id, 1, "");
  }

  function burn(address _from, uint _id) external onlyOwner {
    _burn(_from, _id, 1);

  }

  function setURI(uint _id, string memory _uri) external onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }

}