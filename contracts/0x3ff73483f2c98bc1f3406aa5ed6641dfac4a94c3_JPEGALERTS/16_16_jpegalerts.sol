// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract JPEGALERTS is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;

    // private variables
    string private baseURI;
    Counters.Counter private tokenIdCounter;

    constructor() ERC721("JPEGALERTS", "JPEG ALERTS PASS") {
        tokenIdCounter.increment();
    }

    // public variables
    uint256 public maxSupply = 0;

    // publicMint variables
    bool public pubMintStatus = false;
    uint256 public pubWalletMintLimit = 0;
    uint256 public pubMintPrice = 0 ether;

    // whiteListMint variables
    mapping(address => bool) private whitelistedAddresses;
    bool public wlMintStatus = false;
    uint256 public wlWalletMintLimit = 0;
    uint256 public wlMintPrice = 0 ether;
    

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // set baseURI
    function setBaseURI(string memory value) public {
        baseURI = value;
    }

    // Get metadata URI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721: invalid token ID");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        "/",
                        Strings.toString(tokenId)
                    )
                )
                : "";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // publicMint
    function publicMint(uint256 quantity) public payable {
        require(pubMintStatus, "public sale is not live");
        require(maxSupply > totalSupply(), "sold out");
        require(
            quantity > 0 &&
                (balanceOf(msg.sender) + quantity) <= pubWalletMintLimit,
            "invalid quantity"
        );
        require(msg.value >= (quantity * pubMintPrice), "insufficient eth");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
            tokenIdCounter.increment();
        }
    }

    // whitelist Mint
    function whitelistMint(uint256 quantity) public payable {
        require(wlMintStatus, "whitelist sale is not live");
        require(maxSupply > totalSupply(), "sold out");
        require(
            whitelistedAddresses[msg.sender],
            "sorry you are not in the whitelist"
        );
        require(
            quantity > 0 &&
                (balanceOf(msg.sender) + quantity) <= wlWalletMintLimit,
            "invalid quantity"
        );
        require(msg.value >= (quantity * wlMintPrice), "insufficient eth");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);

            tokenIdCounter.increment();
        }
    }

    // configure public mint
    function configurePubMint(
        bool status,
        uint256 limitPerWallet,
        uint256 price
    ) public onlyOwner {
        pubMintStatus = status;
        pubWalletMintLimit = limitPerWallet;
        pubMintPrice = price;
    }

    // configure whitelist mint
    function configureWlMint(
        bool status,
        uint256 limitPerWallet,
        uint256 price
    ) public onlyOwner {
        wlMintStatus = status;
        wlWalletMintLimit = limitPerWallet;
        wlMintPrice = price;
    }

    // set whitelist addresses
    function addWhitelistAddresses(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistedAddresses[addresses[i]] = true;
        }
    }

    // set public mint status
    function setMaxSupply(uint256 supply) public onlyOwner {
        maxSupply = supply;
    }

    // check whitelist status
    function isWhitelisted(address addr) public view returns (bool) {
        return whitelistedAddresses[addr];
    }

    // withdraw balance
    function withdrawBalance(address addr) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(addr).transfer(balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}