// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OmnimorphsArtBook is Ownable, ERC1155 {
    mapping(uint => string) private _tokenURIs;

    mapping(uint => uint) public mintedAmounts;

    mapping(uint => uint) public maxMintedAmounts;

    constructor(string memory initialURI) ERC1155(initialURI) {}

    // OWNER

    function setMaxMintedAmount(uint id, uint newMaxMintedAmount) external onlyOwner {
        require(maxMintedAmounts[id] == 0, "OmnimorphsArtBook: Cannot reset max supply once it was set");

        maxMintedAmounts[id] = newMaxMintedAmount;
    }

    function setURI(uint id, string memory newURI) external onlyOwner {
        _setURI(id, newURI);
    }

    function mint(address to, uint id, uint amount) external onlyOwner {
        require(mintedAmounts[id] + amount <= maxMintedAmounts[id], "OmnimorphsArtBook: Max supply exceeded");

        _mintTokens(to, id, amount);
    }

    function mintForList(address[] calldata addresses, uint id, uint amount) external onlyOwner {
        require(mintedAmounts[id] + (addresses.length * amount) <= maxMintedAmounts[id], "OmnimorphsArtBook: Max supply exceeded");

        for (uint i = 0; i < addresses.length; i++) {
            _mintTokens(addresses[i], id, amount);
        }
    }

    // INTERNAL

    function _setURI(uint id, string memory newURI) private {
        _tokenURIs[id] = newURI;
    }

    function _mintTokens(address to, uint id, uint amount) private {
        mintedAmounts[id] += amount;

        if (maxMintedAmounts[id] > 0) {
            _mint(to, id, amount, "0x");
        }
    }

    // PUBLIC

    function uri(uint id) public view override returns(string memory) {
        return _tokenURIs[id];
    }

    function burnBatch(uint[] calldata ids, uint[] calldata amounts) external {
        _burnBatch(msg.sender, ids, amounts);
    }
}