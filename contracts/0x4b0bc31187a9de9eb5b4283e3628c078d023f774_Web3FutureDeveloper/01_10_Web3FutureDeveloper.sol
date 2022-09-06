// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/**
  這是一個 Web3 Future 開發者的 ERC1155 NFT
  由 Whien 懷恩([email protected]) 所創造
  日期為 2022-07-25
  讓我們持續努力，熊市就是我們的值得把握的時機！

  如果您曾經幫助過我，或一起努力建設過，
  這都是得來不易的緣份，
  我將會發送一個 ERC1155 給您，
  這個 NFT 將會永遠記錄我們的過去。

  感謝你的參與一起加油了，努力建造，迎接未來的美好日子！
*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Web3FutureDeveloper is ERC1155, Ownable {
  constructor() ERC1155("https://web3.whien.xyz/metadata/{id}.json") {
    _mint(msg.sender, 1, 1, "");
  }

  function mint(
    address _to,
    uint256 _tokenId,
    uint256 _amount,
    bytes memory _data
  ) external onlyOwner {
    _mint(_to, _tokenId, _amount, _data);
  }

  function setURI(
    string memory _uri
  ) external onlyOwner {
    _setURI(_uri);
  }
}