//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MyNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("CITIZEN", "CTZN") {}

	function baseTokenURI() public pure returns (string memory) {
        return "https://elliotrades.herokuapp.com/api/citizen/";
    }

	function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }


    function mintNFT(address recipient)
        public virtual payable
        returns (uint256)
    {
		require(msg.value >= 100000000000000000, "Not enough ETH sent; check price!"); 

        uint256 newItemId;
        for (uint256 value = msg.value; value >= 100000000000000000; value -= 100000000000000000)
        {
            _tokenIds.increment();

            string memory newTokenURI = tokenURI(_tokenIds.current());

            newItemId = _tokenIds.current();
            _mint(recipient, newItemId);
            _setTokenURI(newItemId, newTokenURI);
        }
        return newItemId;
    }

	function withdrawAll() external onlyOwner {
        require(msg.sender.send(address(this).balance));
	}
}