// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Rug is ERC721Enumerable, Ownable {
    uint256 public constant MAX_RUGS = 6969;
    bool public hasSaleStarted = false;

    string private _baseTokenURI;

    constructor(string memory baseTokenURI)
        ERC721("Wen Rug Pull", "WENRUGPULL")
    {
        setBaseURI(baseTokenURI);
    }

    modifier saleIsOpen {
        require(totalSupply() < MAX_RUGS, "Sale end");
        _;
    }

    modifier saleHasStarted {
        require(hasSaleStarted == true, "Sale not started");
        _;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Allows for the early reservation of 100 rugs from the creators for promotional usage
    function saveRugs(uint256 _count) public onlyOwner {
        uint256 totalSupply = totalSupply();
        require(totalSupply + _count < 101, "Beyond max limit"); // make sure we can only mint the first 100
        require(hasSaleStarted == false, "Sale has already started");
        for (uint256 index; index < _count; index++) {
            _safeMint(owner(), totalSupply + index);
        }
    }

    function mint(uint256 _count) public payable saleHasStarted saleIsOpen {
        uint256 totalSupply = totalSupply();
        require(totalSupply + _count <= MAX_RUGS, "Beyond max limit");
        require(totalSupply < MAX_RUGS, "Sale end");
        require(_count < 21, "Exceeds 20");
        require(msg.value >= 20000000000000000 * _count, "Value below price");

        for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function updateSaleStatus(bool val) public onlyOwner {
        hasSaleStarted = val;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}