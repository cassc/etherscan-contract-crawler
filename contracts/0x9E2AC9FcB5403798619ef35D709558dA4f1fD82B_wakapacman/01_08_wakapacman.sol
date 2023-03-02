// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./contract/ERC721A.sol";
import "./contract/DefaultOperatorFilterer.sol";

error SaleNotOpen();
error SoldOut();
error LimitReached();
error InsufficientPayment();
error NoZeroMint();
error NoBots();

contract wakapacman is ERC721A, DefaultOperatorFilterer, Ownable {
    // Variables 
    uint32 public constant MAX_WALLET = 5;
    uint32 public FREE_LIMIT = 1;
    uint64 public PRICE = 0.002 ether;
    uint128 public constant MAX_SUPPLY = 2666;
    bool public saleOpen = false;
    string public baseURI;

    // Constructor
    constructor() ERC721A("WAKA P.M.", "WPC") {
        _mint(msg.sender, 1);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
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

    // Modifiers
    modifier nonContract() {
        if (tx.origin != msg.sender) revert NoBots();
        _;
    }

    // Mint
    function toggleSale() public onlyOwner {
        saleOpen = !saleOpen;
    }

    function mint(uint256 qty) external payable nonContract {
        if (!saleOpen) revert SaleNotOpen();
        if (_totalMinted() + qty > MAX_SUPPLY) revert SoldOut();
        if(_numberMinted(msg.sender) + qty > MAX_WALLET) revert LimitReached();
        if(qty <= 0) revert NoZeroMint();

        if(_numberMinted(msg.sender) >= FREE_LIMIT){
            if(msg.value < qty * PRICE) revert InsufficientPayment();
        }else{
            if(msg.value < (qty - 1) * PRICE) revert InsufficientPayment();  
        }

        _mint(msg.sender, qty);
    }

    // Token URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI,_toString(tokenId),".json"));
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    // Setter
    function setPrice(uint64 amt) external onlyOwner 
    {
        PRICE = amt;
    }

    // Withdraw
    function withdraw() external onlyOwner 
    {
        (bool trx, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(trx, "failed");
    }

    // Others
    function _startTokenId() internal view virtual override returns (uint) {
        return 1;
    }
}