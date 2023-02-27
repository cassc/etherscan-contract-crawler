// SPDX-License-Identifier: MIT

// Pepe Samurai NFT

pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./DefaultOperatorFilterer.sol";


contract PepeSamurai is ERC721A, DefaultOperatorFilterer, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_TOKENS = 4444;
    uint256 public price = 0.025 ether;
    uint256 public whitelistSalePrice = 0.015 ether;
    uint256 public ogSalePrice = 0.01 ether;
    uint256 public maxPerOGWallet = 1;
    uint256 public maxPerWLWallet = 3;
    uint256 public maxPerWallet = 5;
    
    address public constant w1 = 0xb1d33bF74216432238468E855656CdD54098C1CD;

    bool public publicSaleStarted = false;
    bool public whitelistSaleStarted = false;
    bool public ogSaleStarted = false;

    mapping(address => uint256) public walletMints;
    mapping(address => uint256) public whitelistMints;
    mapping(address => uint256) public ogMints;
    bool public revealed = false; // by default collection is unrevealed
    string public unRevealedURL = "https://pepesamurai.mypinata.cloud/ipfs/QmYcEuQs77hRMR4JTpsf9pRgSEn54BTubgy8CSy3WEtAXB/hidden.json";
    string public baseURI = "";
    string public extensionURL = ".json";
    bytes32 public wlMerkleRoot = 0x921d4faf0b93e10059167890b89c019ddca1488a89d68051994d19f258bad7a9;
    bytes32 public ogMerkleRoot = 0x9be41b6ca212a71ea38991dc9b16dc1e116e9f0bb0a1ce885c683b995b4f1558;

    constructor() ERC721A("The Pepe Samurai", "PSM") {}

    function setMaxTokens(uint maxTokens) external onlyOwner {
        MAX_TOKENS = maxTokens;
    }

    function toggleWhitelistSaleStarted() external onlyOwner {
        whitelistSaleStarted = !whitelistSaleStarted;
    }

    function toggleOGSaleStarted() external onlyOwner {
        ogSaleStarted = !ogSaleStarted;
    }

    function toggleWlOgSale() external onlyOwner {
        whitelistSaleStarted = !whitelistSaleStarted;
        ogSaleStarted = !ogSaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

     function toggleRevealed() external onlyOwner {
        revealed = !revealed;
    }

    function setPublicPrice(uint256 _newpublicPrice) external onlyOwner {
        price = _newpublicPrice;
    }

    function setWhitelistPrice(uint256 _newWhitelistprice) external onlyOwner {
        whitelistSalePrice = _newWhitelistprice;
    }

    function setOGPrice(uint256 _newOGprice) external onlyOwner {
        ogSalePrice = _newOGprice;
    }

    function setMaxPerWallet(uint256 _newMaxPerWallet) external onlyOwner {
        maxPerWallet = _newMaxPerWallet;
    }

    function setMaxPerWLWallet(uint256 _newMaxPerWLWallet) external onlyOwner {
        maxPerWLWallet = _newMaxPerWLWallet;
    }

    function setMaxPerOGWallet(uint256 _newMaxPerOGWallet) external onlyOwner {
        maxPerOGWallet = _newMaxPerOGWallet;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWLMerkleRoot(bytes32 _wlMerkleRoot) external onlyOwner {
        wlMerkleRoot = _wlMerkleRoot;
    }

    function setOGMerkleRoot(bytes32 _ogMerkleRoot) external onlyOwner {
        ogMerkleRoot = _ogMerkleRoot;
    }

    function setUnrevealURL(string memory _notRevealuri) public onlyOwner {
        unRevealedURL = _notRevealuri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        if (revealed == false) {
            return unRevealedURL;
        } else {
            string memory currentBaseURI = _baseURI();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            tokenId.toString(),
                            extensionURL
                        )
                    )
                    : "";
        }
    }

    function mintWhitelist(uint256 tokens, bytes32[] calldata wlMerkleProof)
        external
        payable
    {
        require(whitelistSaleStarted, "WL Sale has not started");
        require(
            MerkleProof.verify(
                wlMerkleProof,
                wlMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on the whitelist"
        );
        require(
            totalSupply() + tokens <= MAX_TOKENS,
            "Minting would exceed max supply"
        );
        require(tokens > 0, "Must mint at least one Pepe Samurai");
        require(
            whitelistMints[_msgSender()] + tokens <= maxPerWLWallet,
            "WL limit for this wallet reached"
        );
        require(whitelistSalePrice * tokens <= msg.value, "Not enough ETH");

        whitelistMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    function mintOG(uint256 tokens, bytes32[] calldata ogMerkleProof)
        external
        payable
    {
        require(ogSaleStarted, "OG Sale has not started");
        require(
            MerkleProof.verify(
                ogMerkleProof,
                ogMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on the oglist"
        );
        require(
            totalSupply() + tokens <= MAX_TOKENS,
            "Minting would exceed max supply"
        );
        require(tokens > 0, "Must mint at least one Pepe Samurai");
        require(
            ogMints[_msgSender()] + tokens <= maxPerOGWallet,
            "OG limit for this wallet reached"
        );
        require(ogSalePrice * tokens <= msg.value, "Not enough ETH");

        ogMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "Public Sale has not started");
        require(
            totalSupply() + tokens <= MAX_TOKENS,
            "Minting would exceed max supply"
        );
        require(tokens > 0, "Must mint at least one Pepe Samurai");
        require(
            walletMints[_msgSender()] + tokens <= maxPerWallet,
            "Limit exceeded"
        );
        require(price * tokens <= msg.value, "Not enough ETH");

        walletMints[_msgSender()] += tokens;
        _safeMint(_msgSender(), tokens);
    }

     function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(w1, ((balance * 100) / 100));
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}