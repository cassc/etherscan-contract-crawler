// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "Ownable.sol";
import "ERC721.sol";
import "Pausable.sol";

contract BRONICORNS is ERC721, Ownable, Pausable {

    uint public maxItemsPerTx = 5;
    uint public maxItems = 8888;
    uint public totalSupply = 0;
    string public _baseTokenURI;

    event Mint(address indexed owner, uint indexed tokenId);

    constructor() ERC721("BRONICORNS", "BRO") {
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(uint amount) external whenNotPaused {
        _mintWithoutValidation(msg.sender, amount);
    }

    function _mintWithoutValidation(address to, uint amount) internal {
        require(totalSupply + amount <= maxItems, "mintWithoutValidation: Sold out");
        require(amount <= maxItemsPerTx, "mintWithoutValidation: Surpasses maxItemsPerTx");
        for (uint i = 0; i < amount; i++) {
            _mint(to, totalSupply);
            emit Mint(to, totalSupply);
            totalSupply += 1;
        }
    }

    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }


}