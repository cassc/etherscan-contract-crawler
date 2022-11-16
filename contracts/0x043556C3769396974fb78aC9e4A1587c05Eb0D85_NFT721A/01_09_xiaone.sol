// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT721A is ERC721A, DefaultOperatorFilterer, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) internal mintCountMap;
    bool mintAvailable = false;
    string public baseUri;
    uint256 public maxCount = 6464;
    uint256 public individualMintLimit = 20;

    constructor() ERC721A("XIA ONE(GEN2)", "XIA ONE(GEN2)") {}

    //******SET UP******
    function setMaxCount(uint256 _maxCount) public onlyOwner {
        maxCount = _maxCount;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseUri = _newURI;
    }

    function setIndividualMintLimit(uint256 _individualMintLimit) public onlyOwner {
        individualMintLimit = _individualMintLimit;
    }

    function setMintAvailable(bool _mintAvailable) public onlyOwner {
        mintAvailable = _mintAvailable;
    }

    //******END SET UP******

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mint(uint256 quantity) external {
        require(mintAvailable, "Mint not available!");
        require(
            _nextTokenId() + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            mintCountMap[msg.sender] + quantity <= individualMintLimit,
            "You have reached individual mint limit!"
        );

        _safeMint(msg.sender, quantity);
        mintCountMap[msg.sender] = mintCountMap[msg.sender] + quantity;
    }

    function airdrop(address to, uint256 quantity) public onlyOwner {
        require(quantity > 0, "The quantity is less than 0!");
        require(
            _nextTokenId() + quantity <= maxCount,
            "The quantity exceeds the stock!"
        );
        _safeMint(to, quantity);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }
}