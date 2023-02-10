// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract SamuricesV2 is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    string public baseURI = "";
    string public baseURIExtension = "";

    uint256 public maxSupply = 7777;
    uint256 public maxSupplyPrivate = 4377;
    uint256 public publicMintPrice = 0.01 ether;
    uint256 public maxPublicMint = 12;

    enum Sale {
        PAUSED,
        PRIVATE,
        LEFTOVERS,
        PUBLIC
    }

    Sale public saleState = Sale.PAUSED;

    mapping(address => uint256) public remainingFreeMints;
    mapping(address => uint256) public remainingLeftOvers;
    mapping(address => uint256) public publicMinted;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier isSaleState(Sale sale) {
        require(saleState == sale, "Sale not active");
        _;
    }

    constructor(string memory _initBaseURI, string memory _initBaseURIExtension) ERC721A("Samurices", "SAMURICES") {
        setBaseURI(_initBaseURI);
        setBaseExtension(_initBaseURIExtension);
    }

    function publicMint(uint256 _quantity) external payable nonReentrant callerIsUser isSaleState(Sale.PUBLIC) {
        uint256 price = publicMintPrice;
        require(_quantity > 0, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Total supply exceeded");
        require(publicMinted[msg.sender] + _quantity <= maxPublicMint, "Max public mint exceeded");
        require(msg.value == price * _quantity, "Wrong ETH amount");
        publicMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function leftoverMint(uint256 _quantity, address _target)
        external
        nonReentrant
        callerIsUser
        isSaleState(Sale.LEFTOVERS)
    {
        require(_quantity > 0, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupplyPrivate, "Total Private Supply exceeded");
        require(remainingLeftOvers[_target] >= _quantity, "Max leftovers mints exceeded");
        remainingLeftOvers[_target] -= _quantity;

        _safeMint(_target, _quantity);
    }

    function reservedMint(uint256 _quantity, address _target)
        external
        nonReentrant
        callerIsUser
        isSaleState(Sale.PRIVATE)
    {
        require(_quantity > 0, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupplyPrivate, "Total Private supply exceeded");
        require(remainingFreeMints[_target] >= _quantity, "Max free mints exceeded");
        remainingFreeMints[_target] -= _quantity;

        _safeMint(_target, _quantity);
    }

    // Metadata

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseURIExtension))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setBaseExtension(string memory _newBaseURIExtension) public onlyOwner {
        baseURIExtension = _newBaseURIExtension;
    }

    // Admin settings

    function setSaleState(Sale sale) external onlyOwner {
        saleState = sale;
    }

    function setMaxPublicMint(uint256 _newMaxMints) external onlyOwner {
        maxPublicMint = _newMaxMints;
    }

    function setPublicMintPrice(uint256 _newPrice) external onlyOwner {
        publicMintPrice = _newPrice;
    }

    function setMaxSupplyPrivateSale(uint256 _supply) external onlyOwner {
        require(_supply < maxSupply, "Private max supply should be lower than collection max supply");
        maxSupplyPrivate = _supply;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        uint256 _currentSupply = totalSupply();
        require(_supply > maxSupplyPrivate, "New max supply should be greater than private max supply");
        require(_supply > _currentSupply, "New max supply should be greater than current supply");
        require(_supply < maxSupply, "New max supply should be lower than previous max supply");
        maxSupply = _supply;
    }

    function batchSetWalletsFreeMints(
        address[] memory _wallets,
        uint256[] memory _freeMints,
        uint256[] memory _leftOvers
    ) external onlyOwner {
        require(
            _wallets.length == _freeMints.length && _wallets.length == _leftOvers.length,
            "Wallets length should be same as freemints and leftovers length"
        );
        for (uint256 i = 0; i < _wallets.length; i++) {
            remainingFreeMints[_wallets[i]] = _freeMints[i];
            remainingLeftOvers[_wallets[i]] = _leftOvers[i];
        }
    }

    function devMint(address[] memory _wallets, uint256[] memory _amounts) external onlyOwner {
        require(_wallets.length == _amounts.length, "Wallets length should be same as amounts length");
        uint256 totalTokens = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalTokens += _amounts[i];
        }
        require(totalTokens + totalSupply() <= maxSupply, "Airdrop supply should not exceed max supply");
        for (uint256 i = 0; i < _wallets.length; i++) {
            _safeMint(_wallets[i], _amounts[i]);
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // OS Operator Registry

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}