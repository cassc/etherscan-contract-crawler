// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./DefaultOperatorFilterer.sol";

contract JPEGALERTS is
    ERC721,
    DefaultOperatorFilterer,
    ERC721Enumerable,
    Pausable,
    Ownable
{
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    constructor() ERC721("JPEGALERTS", "JPEG ALERTS PASS") {
        tokenIdCounter.increment();
    }

    string private baseURI;
    uint256 public maxSupply = 99;
    bool public pubMintStatus = false;
    uint256 public pubWalletMintLimit = 0;
    uint256 public pubMintPrice = 0 ether;
    uint256 public pubMintStock = 0;
    uint256 private pubMintCounter = 0;
    bool public wlMintStatus = false;
    uint256 public wlWalletMintLimit = 0;
    uint256 public wlMintPrice = 0 ether;
    uint256 public wlMintStock = 0;
    uint256 private wlMintCounter = 0;
    address private withdrawAddress =
        0xF8FA5B533E9b5b25283Fea4bd288acc7735EDcA8;
    mapping(address => bool) private whitelistedWallets;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // set baseURI
    function setBaseURI(string memory value) public onlyOwner {
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
        require(pubMintCounter < pubMintStock, "sold out");
        require(maxSupply >= (totalSupply() + quantity), "reached max supply");
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
            pubMintCounter++;
        }
    }

    // whitelist Mint
    function whitelistMint(uint256 quantity) public payable {
        require(wlMintStatus, "whitelist sale is not live");
        require(wlMintCounter < wlMintStock, "sold out");
        require(maxSupply >= (totalSupply() + quantity), "reached max supply");
        require(
            whitelistedWallets[msg.sender],
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
            wlMintCounter++;
        }
    }

    // airdrop
    function airdrop(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 tokenId = tokenIdCounter.current();
            _safeMint(addresses[i], tokenId);
            tokenIdCounter.increment();
        }
    }

    // configure public mint
    function configurePubMint(
        uint256 limitPerWallet,
        uint256 price,
        uint256 stock
    ) public onlyOwner {
        pubMintStatus = true;
        pubWalletMintLimit = limitPerWallet;
        pubMintPrice = price;
        pubMintStock = stock;
    }

    // configure whitelist mint
    function configureWlMint(
        uint256 limitPerWallet,
        uint256 price,
        uint256 stock
    ) public onlyOwner {
        wlMintStatus = true;
        wlWalletMintLimit = limitPerWallet;
        wlMintPrice = price;
        wlMintStock = stock;
    }

    // turn off public Mint
    function togglePubMint() public onlyOwner {
        pubMintStatus = false;
        pubWalletMintLimit = 0;
        pubMintPrice = 0;
        pubMintStock = 0;
        pubMintCounter = 0;
    }

    // turn off whitelist Mint
    function toggleWlMint() public onlyOwner {
        wlMintStatus = false;
        wlWalletMintLimit = 0;
        wlMintPrice = 0;
        wlMintStock = 0;
        wlMintCounter = 0;
    }

    // add wallets to whitelist
    function addWalletsToWL(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistedWallets[addresses[i]] = true;
        }
    }

    // check whitelist status
    function checkWhitelist(address addr) public view returns (bool) {
        return whitelistedWallets[addr];
    }

    // withdraw balance
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(withdrawAddress).transfer(balance);
    }

    // set max supply
    function setMaxSupply(uint256 supply) public onlyOwner {
        maxSupply = supply;
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