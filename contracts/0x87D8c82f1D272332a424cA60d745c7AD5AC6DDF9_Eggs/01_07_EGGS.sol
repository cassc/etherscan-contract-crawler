// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./OperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Eggs is ERC721A, OperatorFilterer, Ownable {
    using Strings for uint256;

    bool public operatorFilteringEnabled;
    string public baseURI;
    string public uriSuffix = ".json";

    uint256 public maxSupply = 8888;
    uint256 public mintPrice = 0.0044 ether;
    uint256 public mintLimit = 12;
    uint256 public freeMintLimit = 1;
    bool public mintPaused = true;

    address founder = 0xDe2932BaE45100Fa60f819BCe80E3aC464b8F5A9;
    address dev = 0x509f4932775Eae152e04bAEa2554F44c7Ae0343e;

    mapping (address => uint256) public addressFreeMintCount;
    mapping (address => uint256) public addressMintCount;

    constructor(
    ) ERC721A("Eggs", "EGGS") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _safeMint(dev, 1);
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

    function withdraw() public payable onlyOwner() {
      uint256 balanceContract = address(this).balance;
      require(balanceContract > 0, "Sales Balance = 0");

      uint256 balance1 = balanceContract / 10;
      uint256 balance2 = balanceContract*9 / 10;

      _withdraw(dev, balance1);
      _withdraw(founder, balance2);

    }

    function _withdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Transfer failed.");
    }

    function toggleMintPaused() external onlyOwner {
        mintPaused = !mintPaused;
    }

    function setFreeMintLimit(uint256 _freeMintLimit) external onlyOwner {
        freeMintLimit = _freeMintLimit;
    }

    function setSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), uriSuffix))
        : "";
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