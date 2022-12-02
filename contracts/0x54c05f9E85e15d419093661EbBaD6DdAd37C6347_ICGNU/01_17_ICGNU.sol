// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ICGNU is ERC721, DefaultOperatorFilterer, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _countTracker;

    address public multiSigOwner;
    // Base URI
    string private _baseURIextended;
    uint256 public maxTokens = 777; 
    uint256 public maxPerMint = 7; 
    uint256 public mintPrice; //70000000000000000
    constructor(
        address _multiSig,
        string memory baseURI_,
        uint256 _mintPrice
    ) ERC721("ICGNU", "ICGNU") {
        setMultiSig(_multiSig);
        setBaseURI(baseURI_);
        setMintPrice(_mintPrice);
    }


    function totalSupply() public view returns (uint256) {
        return _countTracker.current();
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMultiSig(address _multiSig) public onlyOwner {
        multiSigOwner = _multiSig;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }       

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();
    
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString(), ".json" ));
    }

    function mintOwner(uint256 quantity) external onlyOwner {
        require(quantity > 0, "Mint count should be greater than zero");
        uint256 remainingSupply = maxTokens - _countTracker.current();
        require(remainingSupply >= quantity, "Not Enough Token Supply");
        for (uint256 i = 0; i < quantity; i++) {
            _mintOneItem(msg.sender);
        }
    }


    function mint(uint256 quantity) external payable {
        require(quantity > 0, "Mint count should be greater than zero");
        require(msg.value >= mintPrice * quantity, "Insufficient funds");
        require(maxPerMint >= quantity, "Max Per Mint is 7");
        uint256 remainingSupply = maxTokens - _countTracker.current();
        require(remainingSupply >= quantity, "Not Enough Token Supply");
        
        for (uint256 i = 0; i < quantity; i++) {
            _mintOneItem(msg.sender);
        }
    }

    function _mintOneItem(address _to) private {
        _countTracker.increment();
        uint256 tokenId = _countTracker.current();
        _mint(_to, tokenId);

    }



    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(multiSigOwner, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Transfer failed.");
    }
}