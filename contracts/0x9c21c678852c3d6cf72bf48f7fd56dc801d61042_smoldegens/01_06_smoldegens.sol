// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./OperatorFilterer.sol";

contract smoldegens is ERC721A, OperatorFilterer, Ownable {

    bool public operatorFilteringEnabled;
    string public baseURI;
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public mintLimit;
    uint256 public freeMintLimit;
    bool public mintPaused = true;

    mapping (address => uint256) public addressFreeMintCount;
    mapping (address => uint256) public addressMintCount;

    constructor(
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _mintLimit,
        uint256 _freeMintLimit
    ) ERC721A("smol degens", "smoldegens") {
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        mintLimit = _mintLimit;
        freeMintLimit = _freeMintLimit;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    function mint(uint256 qty) external payable {
        require(!mintPaused, "Public sale paused");
        require(qty > 0 && qty <= mintLimit, "Invalid quantity");
        require(tx.origin == msg.sender, "Caller is a contract");
        require(addressMintCount[msg.sender] + qty <= mintLimit, "Max mint per wallet reached");
        require(totalSupply() + qty <= maxSupply, "Max supply reached");

        uint256 freeMintsRemaining = freeMintLimit - addressFreeMintCount[msg.sender];
        uint256 totalCost;
        if (freeMintsRemaining >= qty) {
            totalCost = 0;
            freeMintsRemaining -= qty;
        } else {
            totalCost = mintPrice * (qty - freeMintsRemaining);
            freeMintsRemaining = 0;
        }

        require(msg.value >= totalCost, "Not enough ETH");

        addressFreeMintCount[msg.sender] = freeMintLimit - freeMintsRemaining;
        addressMintCount[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function toggleMintPaused() external onlyOwner {
        mintPaused = !mintPaused;
    }

    function setFreeMintLimit(uint256 _freeMintLimit) external onlyOwner {
        freeMintLimit = _freeMintLimit;
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // OS
    
    function repeatRegistration() public {
        _registerForOperatorFiltering();
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
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
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

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }
}