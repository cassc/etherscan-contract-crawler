// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

contract BlockchainBeings is ERC721A, Ownable, OperatorFilterer {

    /// ============ Custom Errors ============
    error SaleIsNotLive();
    error InsufficientPayment();
    error MaxSupplyExceeded();
    error MaxMintPerTransactionExceeded();

    /// ============ Modifiers ============
    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Contracts are not allowed to call this function");
        _;
    }

    /// ============ Variables ============
    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public constant MAX_PER_TRANSACTION = 10;
    uint256 public constant PRICE = 0.005 ether;
    bool public saleIsLive = false;
    bool public operatorFilteringEnabled;
    string public baseURI;

    /// ============ Constructor ============
    constructor() ERC721A("Blockchain Beings", "BB") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    /// ============ Mint Function ============
    function mint(uint256 quantity) external payable onlyEOA {
       if (!saleIsLive) revert SaleIsNotLive();
       if (_totalMinted() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded();
       if (quantity > MAX_PER_TRANSACTION) revert MaxMintPerTransactionExceeded();

       uint256 payAmount = quantity;
       uint256 freeMintCount = _getAux(msg.sender);

       if (freeMintCount < 1) {
            payAmount = quantity - 1;
            _setAux(msg.sender, 1);
       }
       
       if (payAmount > 0) {
            if (msg.value < payAmount * PRICE) revert InsufficientPayment();
        }

        _mint(msg.sender, quantity);
    }

    /// ============ Overrides / Owner Only ============
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

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function toggleSale() public onlyOwner {
        saleIsLive = !saleIsLive;
    }

    function withdraw() external onlyOwner {
        (bool hs, ) = payable(0x8fA3220055C692bE18b751d107CA451B26Bb4df8).call{
            value: (address(this).balance * 30) / 100
        }("");
        require(hs);

        (bool os, ) = payable(0x4786cbf3bD45d9E2D7A025Fb203b40Ca5522FFe6).call{
            value: address(this).balance
        }("");
        require(os);
    }
}