//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ColorClones is ERC721A, ReentrancyGuard, Ownable {
    /* 
    ======================== STATE VARIABLES ========================
    */
    string private baseUrl;
    string private urlSuffix = ".json";
    bool private mintingPaused = true;
    uint256 private constant TOTAL_SUPPLY = 555;
    uint256 private mintPrice = 0.005 ether;
    uint256 private maxPerWallet = 5;
    mapping(address => uint256) private mintedByWallet;

    constructor(string memory _baseUrl) ERC721A("Color Clones", "CC") {
        baseUrl = _baseUrl;
        _safeMint(msg.sender, 1);
    }

    receive() external payable {}

    /* 
    ======================== PUBLIC FUNCTIONS ========================
    */

    function mint(uint256 _quantity)
        external
        payable
        nonReentrant
        mintRequirements(_quantity)
    {
        _safeMint(msg.sender, _quantity);
        mintedByWallet[msg.sender] += _quantity;
    }

    /* 
    ======================== INHERITED FUNCTIONS ========================
    */

    function _baseURI() internal view override returns (string memory) {
        return baseUrl;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, _toString(tokenId), urlSuffix)
                )
                : "";
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /* 
    ======================== GETTER FUNCTIONS ========================
    */

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function getMaxPerWallet() public view returns (uint256) {
        return maxPerWallet;
    }

    function getTotalSupply() public pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function getQuantityMintedByWallet() public view returns (uint256) {
        return mintedByWallet[msg.sender];
    }

    function getBaseUrl() public view returns (string memory) {
        return baseUrl;
    }

    function getMintingStatus() public view returns (bool) {
        return mintingPaused;
    }

    /* 
    ======================== OWNER FUNCTIONS ========================
    */

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        mintPrice = _newMintPrice;
    }

    function toggleMinting() public onlyOwner {
        mintingPaused = !mintingPaused;
    }

    function setBaseUrl(string memory _newBaseUrl) public onlyOwner {
        baseUrl = _newBaseUrl;
    }

    function ownerMint(uint256 _quantity) public onlyOwner {
        require(_quantity > 0, "You can't mint 0 NFTs");
        require((totalSupply() + _quantity) <= TOTAL_SUPPLY, "Sold out!");
        _safeMint(msg.sender, _quantity);
    }

    function ownerMintForAddress(address _toAddress, uint256 _quantity)
        public
        onlyOwner
    {
        require(_quantity > 0, "You can't mint 0 NFTs");
        require((totalSupply() + _quantity) <= TOTAL_SUPPLY, "Sold out!");
        _safeMint(_toAddress, _quantity);
    }

    function withdrawFunds() public payable onlyOwner nonReentrant {
        require(address(this).balance > 0, "The contract has no ETH");
        (bool withdrawOwner, ) = payable(owner()).call{
            value: address(this).balance
        }("");

        require(withdrawOwner, "Withdraw failed");
    }

    /* 
    ======================== MODIFIERS ========================
    */

    modifier mintRequirements(uint256 _quantity) {
        require(mintingPaused == false, "Minting is paused");
        require(totalSupply() < TOTAL_SUPPLY, "Sold out!");
        require((totalSupply() + _quantity) < TOTAL_SUPPLY, "Sold out!");
        require(_quantity > 0, "You can't mint 0 NFTs");
        require(msg.value >= (mintPrice * _quantity), "To little ETH was sent");
        require(
            mintedByWallet[msg.sender] + _quantity <= maxPerWallet,
            "Max per wallet exceeded"
        );
        _;
    }
}