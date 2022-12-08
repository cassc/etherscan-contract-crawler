// SPDX-License-Identifier: MIT
// This Is Just The Start Of Our Journey

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./OperatorFilterer.sol";

contract ArtOfEmotion is ERC721A, OperatorFilterer, Ownable {

    uint256 public immutable maxSupply;
    uint256 public immutable maxMint;
    string public baseURI;
    bool public operatorFilteringEnabled;

    mapping (address => uint256) public addressMintAmount;

    constructor(
        uint256 _maxSupply,
        uint256 _maxMint
    ) ERC721A("Art of Emotion", "ArtOfEmotion") {
        maxSupply = _maxSupply;
        maxMint = _maxMint;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    function mint() external payable {
        require(addressMintAmount[msg.sender] + 1 <= maxMint, "Max mint reached");
        require(totalSupply() + 1 <= maxSupply, "Max supply reached");

        addressMintAmount[msg.sender]++;
        _safeMint(msg.sender, 1);
    }

    function devMint(uint256 qty) external onlyOwner {
        require(totalSupply() + qty <= maxSupply, "Max supply reached");
        _safeMint(msg.sender, qty);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
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