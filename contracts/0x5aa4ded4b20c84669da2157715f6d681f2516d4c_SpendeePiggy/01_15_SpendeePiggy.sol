// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SpendeePiggy is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using MerkleProof for bytes32[];

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_MINT_AT_ONCE = 20;

    bool public presaleActive = false;
    bool public saleActive = false;
    uint256 public tokenPrice = 40000000000000000; // 0.04 ETH
    uint256 public reserveRemaining = 100; // reserve for the team
    string public baseURI = "https://storage.googleapis.com/nft.spendee.com/4508115373/";

    uint256 public presaleMaxClaim = 2;
    bytes32 public presaleListMerkleRoot = 0x0;
    mapping(address => uint) public presaleClaimed;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("SpendeePiggy", "SPIGGY") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // END-USER FUNCTIONS

    function getMintedCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function presaleMintPiggy(uint256 _count, bytes32[] calldata _proof) public payable {
        require(presaleActive == true, "Presale is stopped.");
        require(msg.value >= tokenPrice * _count, "Insufficient Ether sent!");
        require(presaleClaimed[msg.sender] + _count <= presaleMaxClaim, "The wallet has already claimed maximum presale tokens!");
        require(_count <= MAX_MINT_AT_ONCE, "You can mint at most 20 tokens at once!");
        require(_tokenIdCounter.current() + _count < MAX_SUPPLY, "No tokens left!");
        require(_proof.verify(presaleListMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "The wallet is not on presale list!");

        presaleClaimed[msg.sender] += _count;
        while (_count > 0) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            _count -= 1;
        }
    }

    function mintPiggy(uint256 _count) public payable {
        require(saleActive == true, "Minting is stopped.");
        require(msg.value >= tokenPrice * _count, "Insufficient Ether sent!");
        require(_count <= MAX_MINT_AT_ONCE, "You can mint at most 20 tokens at once!");
        require(_tokenIdCounter.current() + _count < MAX_SUPPLY, "No tokens left!");

        while (_count > 0) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            _count -= 1;
        }
    }

    // OWNER FUNCTIONS

    function reservePiggy(address _to, uint256 _count) public onlyOwner {
        require(_tokenIdCounter.current() + _count < MAX_SUPPLY, "Insufficient token supply");
        require(_count <= reserveRemaining, "Insufficient token reserve");

        reserveRemaining -= _count;
        while (_count > 0) {
            _safeMint(_to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            _count -= 1;
        }
    }

    function setTokenPrice(uint256 _price) public onlyOwner {
        tokenPrice = _price;
    }

    function setBaseURI(string memory _value) public onlyOwner {
        baseURI = _value;
    }

    function setPresaleMaxClaim(uint256 _max) public onlyOwner {
        presaleMaxClaim = _max;
    }

    function setPresaleListMerkleRoot(bytes32 _root) public onlyOwner {
        presaleListMerkleRoot = _root;
    }

    function flipPresaleState() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function flipSaleState() public onlyOwner {
        saleActive = !saleActive;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}