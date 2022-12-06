// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract KAJ is ERC721Enumerable, ReentrancyGuard, Ownable, DefaultOperatorFilterer {

    string public KAJ_PROVENANCE = "";
    string public baseTokenURI;
    bool public mintIsActive = false;
    uint256 public constant MAX_KAJ = 6969;
    uint256 adminMinted;
    uint256 adminReserved = 99;
    uint256 public mintPrice;
    uint256 public maxPerMint;
    uint256 public maxWalletMint;
    mapping(address => uint256) public walletMinted;

    uint256 public claimMinted;
    uint256 public claimReserved = 1000;
    uint256 public maxPerClaim;
    uint256 public maxWalletClaim;
    mapping(address => uint256) public walletClaimed;

    constructor(string memory baseURI, uint256 _mintPrice, uint256 _maxPerMint, uint256 _maxWalletMint, uint256 _maxPerClaim, uint256 _maxWalletClaim) ERC721("KarasAJoke", "KAJ") {
        setBaseURI(baseURI);
        mintPrice = _mintPrice;
        maxPerMint = _maxPerMint;
        maxWalletMint = _maxWalletMint;
        maxPerClaim = _maxPerClaim;
        maxWalletClaim = _maxWalletClaim;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        maxPerMint = _maxPerMint;
    }

    function setmaxWalletMint(uint256 _maxWalletMint) external onlyOwner {
        maxWalletMint = _maxWalletMint;
    }

    function setMaxPerClaim(uint256 _maxPerClaim) external onlyOwner {
        maxPerClaim = _maxPerClaim;
    }

    function setmaxWalletClaim(uint256 _maxWalletClaim) external onlyOwner {
        maxWalletClaim = _maxWalletClaim;
    }

    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        KAJ_PROVENANCE = provenanceHash;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        payable(msg.sender).transfer(balance);
    }

    function reserveKAJ(uint256 numberOfTokens) public onlyOwner {
        require((adminMinted + numberOfTokens) <= adminReserved, "Purchase would exceed reserved supply");

        uint256 supply = totalSupply();
        uint256 i;
        for (i = 1; i <= numberOfTokens; i++) {
            if (totalSupply() < MAX_KAJ) {
                uint256 mintIndex = supply + i;
                adminMinted++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function claim(uint256 numberOfTokens) public payable nonReentrant{
        require(mintIsActive, "Sales is inactive");
        require(numberOfTokens <= maxPerClaim, "Cannot purchase this many tokens per transaction");
        uint256 total = totalSupply();
        require((total + numberOfTokens - adminMinted) <= (MAX_KAJ - adminReserved), "Purchase would exceed supply");
        require((claimMinted + numberOfTokens) <= claimReserved, "Fully claimed");
        require((walletClaimed[msg.sender] + numberOfTokens) <= maxWalletClaim, "Number of tokens requested exceeded the value allowed per wallet");
        require(msg.sender == tx.origin);

        for(uint256 i = 0; i < numberOfTokens; i++) {
            if (walletClaimed[msg.sender] < maxWalletClaim) {
                walletClaimed[msg.sender]++;
                claimMinted++;
                _safeMint(msg.sender, totalSupply() + 1);
            }
        }
    }

    function mint(uint256 numberOfTokens) public payable nonReentrant{
        require(mintIsActive, "Sales is inactive");
        require(numberOfTokens <= maxPerMint, "Cannot purchase this many tokens per transaction");
        uint256 total = totalSupply();
        require((total + numberOfTokens - adminMinted) <= (MAX_KAJ - adminReserved), "Purchase would exceed supply");
        require(mintPrice * numberOfTokens <= msg.value, "Incorrect ether value");
        require((walletMinted[msg.sender] + numberOfTokens) <= maxWalletMint, "Number of tokens requested exceeded the value allowed per wallet");
        require(msg.sender == tx.origin);

        for(uint256 i = 0; i < numberOfTokens; i++) {
            if (walletMinted[msg.sender] < maxWalletMint) {
                walletMinted[msg.sender]++;
                _safeMint(msg.sender, totalSupply() + 1);
            }
        }
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}