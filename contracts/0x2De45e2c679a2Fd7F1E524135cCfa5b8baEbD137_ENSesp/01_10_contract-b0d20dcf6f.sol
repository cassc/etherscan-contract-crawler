// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC1155/ERC1155.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract ENSesp is ERC1155, Ownable {
    uint256 public constant OGPASS = 0;
    uint256 public constant ESP = 1;

    constructor() ERC1155("ipfs://QmTzW1UJjNC9taYJyDcnxkoXy9svE5XSoL1MUw12WDkDFZ/{id}.json")
    {
        _mint(msg.sender, OGPASS, 250, "");
        _mint(msg.sender, ESP, 10**7, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
}