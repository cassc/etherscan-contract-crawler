// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Izumi is ERC721, Ownable, DefaultOperatorFilterer {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    string private baseURI =
        "https://gateway.pinata.cloud/ipfs/bafybeibkffhvbjho76i52t7ds7bwphg4u5gsfl4mkb6piad2l3bo4cy72y/";

    uint256 public constant maxSupply = 2160;
    uint256 public totalSupply = 0;
    uint256 public price = 0;

    address public developer = 0xC21d08431f5848352fA6F4B4374dc49d256D048D;

    uint256 public developerCut = 50; // percentage

    constructor() ERC721("Izumi", "IZM") {
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwnerOrDeveloper {
        baseURI = baseURI_;
    }

    function setDeveloper(address _developer) public onlyDeveloper {
        require(_developer != address(0), "Inalid address");

        developer = _developer;
    }

    function setPrice(uint256 _price) public onlyOwnerOrDeveloper {
        price = _price;
    }

    function mint() public payable {
        require(totalSupply < maxSupply, "All NFTs are minted.");

        require(!_exists(totalSupply), "Token already minted");
        require(price <= msg.value, "Invalid value");

        _safeMint(msg.sender, totalSupply);
        totalSupply++;
    }

    function mintAmount(uint256 amount) public onlyDeveloper {
        require(totalSupply < maxSupply, "All NFTs are minted.");

        while (totalSupply < maxSupply && amount > 0) {
            _safeMint(msg.sender, totalSupply);
            totalSupply++;

            amount--;
        }
    }

    function withdraw() public onlyOwnerOrDeveloper {
        uint256 balance = address(this).balance;
        payable(developer).transfer((balance / 100) * developerCut);
        payable(owner()).transfer(address(this).balance);
    }

    function mintTo(address recipient) public returns (uint256) {
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    modifier onlyOwnerOrDeveloper() {
        require(
            msg.sender == developer || msg.sender == owner(),
            "Inalid sender"
        );
        _;
    }

    modifier onlyDeveloper() {
        require(msg.sender == developer, "Inalid sender");
        _;
    }
}