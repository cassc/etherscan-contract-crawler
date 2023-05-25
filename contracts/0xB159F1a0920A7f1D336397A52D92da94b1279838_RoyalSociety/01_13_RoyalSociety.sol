// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

contract RoyalSociety is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant RESERVES = 151; // Saved for the team for promotional purposes

    uint256 private _saleTime = 1626987600; // Date and time (GMT): Thursday, July 22, 2021 9:00:00 PM (https://www.epochconverter.com/)
    uint256 private _price = 8 * 10**16; // This is currently .08 eth

    string private _baseTokenURI;

    constructor(string memory baseURI) ERC721("Royal Society", "ROYALSOCIETY") {
        setBaseURI(baseURI);
    }

    function setSaleTime(uint256 time) public onlyOwner {
        _saleTime = time;
    }

    function getSaleTime() public view returns (uint256) {
        return _saleTime;
    }

    function isSaleOpen() public view returns (bool) {
        return block.timestamp >= _saleTime;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Allows for the early reservation of 100 rugs from the creators for promotional usage
    function getReserves(uint256 _count) public onlyOwner {
        uint256 totalSupply = totalSupply();
        require(totalSupply + _count < RESERVES, "Beyond max limit"); // make sure we can only mint the first 100
        require(
            block.timestamp < _saleTime,
            "The Royal Society sale has already started."
        );
        for (uint256 index; index < _count; index++) {
            _safeMint(owner(), totalSupply + index);
        }
    }

    function mint(uint256 _count) public payable {
        uint256 totalSupply = totalSupply();
        require(
            totalSupply + _count <= MAX_SUPPLY,
            "A transaction of this size would surpass the token limit."
        );
        require(
            totalSupply < MAX_SUPPLY,
            "All tokens have already been minted."
        );
        require(_count < 21, "Exceeds the max token per transaction limit.");
        require(
            msg.value >= _price * _count,
            "The value submitted with this transaction is too low."
        );
        require(
            block.timestamp >= _saleTime,
            "The Royal Society sale is not currently open."
        );

        for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}