// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SVFQA is ERC1155,
  Ownable
{
    string public baseURI;
    string public notRevealedUri;
    string public name = "Salmon in the river";
    string public symbol = "SVFQA";
    uint256 public constant start = 1;
    uint256 public constant step1 = 2;
    uint256 public constant step2 = 3;
    uint256 public constant end = 4;

    constructor(
    string memory _initNotRevealedUri
    ) ERC1155("SVFQA") {
        setNotRevealedURI(_initNotRevealedUri);
        _mint(msg.sender, start, 1000, "");
        _mint(msg.sender, step1, 500, "");
        _mint(msg.sender, step2, 300, "");
        _mint(msg.sender, end, 100, "");
    }

    function uri(uint256 _tokenid) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                notRevealedUri,
                Strings.toString(_tokenid),".json"
            )
        );
    }
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }
}