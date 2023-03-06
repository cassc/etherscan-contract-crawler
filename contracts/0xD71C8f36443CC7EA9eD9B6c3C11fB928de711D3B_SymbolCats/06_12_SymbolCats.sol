// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SymbolCats is ERC721A, DefaultOperatorFilterer, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bool public isMintActive = false;

    uint256 public price = 0.0025 ether;

    string private unrevealedUri;
    string private baseURI;
    bool public isRevealed = false;

    mapping(address => uint256) public claimedList;

    uint256 public constant LIMIT_PER_WALLET = 10;
    uint256 public constant MAX_SUPPLY = 3333;

    constructor(
        string memory _unrevealedUri
    ) ERC721A("SymbolCats", "SBC") {
        unrevealedUri = _unrevealedUri;
    }

    function mint(uint256 _quantity) external payable {
        require(isMintActive, "Mint isn't enabled!");
        require(_quantity > 0, "Quantity must be more zero!");
        require(_quantity <= LIMIT_PER_WALLET, "Quantity must be less max!");
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Exceed max supply!"
        );
        require(
            claimedList[msg.sender] + _quantity <=
            LIMIT_PER_WALLET,
            "You already minted max!"
        );
        // first free
        if(claimedList[msg.sender] == 0) {
            require(msg.value == price * (_quantity - 1), "Invalid funds provided! You already minted free!");
        } else {
            require(msg.value == price * _quantity, "Invalid funds provided!");
        }

        _safeMint(msg.sender, _quantity);
        claimedList[msg.sender] += _quantity;
    }

    function setIsMintActive(bool _value) external onlyOwner {
        isMintActive = _value;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setUnrevealedUri(string memory _uri) external onlyOwner {
        unrevealedUri = _uri;
    }

    function reservedForTeamMint(uint256 _quantity)
    external
    onlyOwner
    {
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Can't mint more max supply"
        );
        _safeMint(msg.sender, _quantity);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success,) = payable(owner()).call{value : address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function reveal() external onlyOwner {
        isRevealed = true;
    }


    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (isRevealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
        }
        return unrevealedUri;
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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}