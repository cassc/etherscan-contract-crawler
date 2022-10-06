// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VFQA is ERC1155,
  Ownable
{
    string public baseURI;
    string public notRevealedUri;
    uint256 public constant tenx = 1;
    uint256 public constant clikclik = 2;
    uint256 public constant moon = 3;
    uint256 public constant habumus = 4;
    uint256 public constant superv = 5;
    uint256 public constant vsd = 6;
    uint256 public constant vault = 7;

    constructor(
    string memory _initNotRevealedUri
    ) ERC1155("VFQA") {
        setNotRevealedURI(_initNotRevealedUri);
        _mint(msg.sender, tenx, 1, "");
        _mint(msg.sender, clikclik, 1000, "");
        _mint(msg.sender, moon, 10, "");
        _mint(msg.sender, habumus, 10, "");
        _mint(msg.sender, superv, 42, "");
        _mint(msg.sender, vsd, 12, "");
        _mint(msg.sender, vault, 20, "");
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