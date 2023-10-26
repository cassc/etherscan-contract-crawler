// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "erc721a/contracts/ERC721A.sol";

contract Bunnygirl is ERC721A, Ownable {
    uint256 public bunnySupply = 9999;
    uint256 public bunnyPrice = 0.08888 ether;

    bool public mintable = false;
    bool public BunnylistClaim = false;
    bool public WhitelistActive = false;

    mapping(address => uint256) public Bunnylist;
    mapping(address => uint256) public Whitelist;

    mapping(address => bool) private _BunnylistClaimed;
    string private baseURI;

    constructor() ERC721A("Bunnygirl", "BGC") Ownable(0x6c4965aeFB460DC0Da40b43F363cd919EA0Ba4ad) {}

    modifier validMintQuantity(uint256 numTokens) {
        require(
            totalSupply() + numTokens <= bunnySupply,
            "Exceeds total supply"
        );
        _;
    }

    modifier paidEnough(uint256 numTokens) {
        require(
            msg.value == bunnyPrice * numTokens,
            "Incorrect Ether value sent"
        );
        _;
    }

    function publicMintActive() external view returns (bool) {
        return mintable;
    }

    function togglePublicMintActive() external onlyOwner {
        mintable = !mintable;
        WhitelistActive = false;
    }

    function addToWhitelist(address[] calldata _addrs) external onlyOwner {
        for (uint i = 0; i < _addrs.length; i++) {
            Whitelist[_addrs[i]] = 20;
        }
    }

    function removeFromWhitelist(address[] calldata _addrs) external onlyOwner {
        for (uint i = 0; i < _addrs.length; i++) {
            delete Whitelist[_addrs[i]];
        }
    }

    function checkWhitelist(address _addr) external view returns (uint256) {
        return Whitelist[_addr];
    }

    function isWhitelistActive() external view returns (bool) {
        return WhitelistActive;
    }

    function toggleWhitelistActive() external onlyOwner {
        WhitelistActive = !WhitelistActive;
    }

    function addToBunnylist(
        address[] calldata _addrs,
        uint256[] calldata _freeMints
    ) external onlyOwner {
        require(_addrs.length == _freeMints.length, "Mismatched array lengths");

        for (uint i = 0; i < _addrs.length; i++) {
            Bunnylist[_addrs[i]] = _freeMints[i];
        }
    }

    function removeFromBunnylist(address[] calldata _addrs) external onlyOwner {
        for (uint i = 0; i < _addrs.length; i++) {
            delete Bunnylist[_addrs[i]];
        }
    }

    function checkBunnylist(address _addr) external view returns (uint256) {
        return Bunnylist[_addr];
    }

    function isBunnylistActive() external view returns (bool) {
        return BunnylistClaim;
    }

    function toggleBunnylistClaim() external onlyOwner {
        BunnylistClaim = !BunnylistClaim;
    }

    function changePrice(uint256 _price) external onlyOwner {
        bunnyPrice = _price;
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        require(totalSupply() < _newSupply);
        bunnySupply = _newSupply;
    }

    function publicMint(
        uint256 numTokens
    ) external payable validMintQuantity(numTokens) paidEnough(numTokens) {
        require(mintable, "Public minting not allowed");

        _mint(msg.sender, numTokens);
    }

    function whitelistMint(
        uint256 numTokens
    ) external payable validMintQuantity(numTokens) paidEnough(numTokens) {
        require(WhitelistActive, "Whitelist minting not allowed");
        require(
            Whitelist[msg.sender] > 0,
            "You are either not on the Whitelist or have no WL mints left"
        );

        require(
            Whitelist[msg.sender] >= numTokens,
            "Not enough WL mints left for this address"
        );
        Whitelist[msg.sender] = Whitelist[msg.sender] - numTokens;

        _mint(msg.sender, numTokens);
    }

    function claimBunnylist() external payable {
        require(BunnylistClaim, "Bunnylist is not active");
        require(
            Bunnylist[msg.sender] > 0,
            "You are either not on the Bunnylist or have no free mints left"
        );
        require(
            totalSupply() + Bunnylist[msg.sender] <= bunnySupply,
            "Minting these would exceed the total supply"
        );

        uint256 numFreeMints = Bunnylist[msg.sender];

        Bunnylist[msg.sender] = 0; // Reset the free mints for this address to 0 upfront

        _mint(msg.sender, numFreeMints);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return baseURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = address(owner()).call{value: balance}("");
        require(success, "Withdrawal Failed");
    }
}