// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract ColorsOfFreedom is ERC1155, Ownable {
    
  string public name;
  string public symbol;

  uint256 public constant ROYALTY_BASE = 100;
  uint256 public constant ROYALTY_PERCENTAGE = 5;  // 5%

  mapping(uint => string) public tokenURI;

constructor() ERC1155("") Ownable(msg.sender) {
    name = "ColorsOfFreedom";
    symbol = "COF";
}

  function mint(address _to, uint _id, uint _amount) external onlyOwner {
    _mint(_to, _id, _amount, "");
  }

  function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external onlyOwner {
    _mintBatch(_to, _ids, _amounts, "");
  }

  function burn(uint _id, uint _amount) external {
    _burn(msg.sender, _id, _amount);
  }

  function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
    _burnBatch(msg.sender, _ids, _amounts);
  }

  function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external onlyOwner {
    _burnBatch(_from, _burnIds, _burnAmounts);
    _mintBatch(_from, _mintIds, _mintAmounts, "");
  }

  function setURI(uint _id, string memory _uri) external onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }

function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    receiver = owner();  // Owner of the contract receives the royalties
    royaltyAmount = (_salePrice * ROYALTY_PERCENTAGE) / ROYALTY_BASE;
}
}