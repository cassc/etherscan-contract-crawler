// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

error SaleNotActive();
error MaxSupplyReached();
error InsufficientPayment();
error MaxMintPerTransactionExceeded();

contract EtherFellas is ERC721A, OperatorFilterer, Ownable {
    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public constant MAX_PER_TRANSACTION = 10;
    uint256 public constant PRICE = 0.005 ether;

    bool public saleIsActive = false;
    bool public operatorFilteringEnabled;
    string public baseURI;

    modifier noContract() {
        require(tx.origin == msg.sender, "Contracts are not allowed to call this function");
        _;
    }

    constructor() ERC721A("Ether Fellas", "FELLAS") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
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
        saleIsActive = !saleIsActive;
    }

    function mint(uint256 quantity) external payable noContract {
       if (!saleIsActive) revert SaleNotActive();
       if (_totalMinted() + quantity >= MAX_SUPPLY) revert MaxSupplyReached();
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

    function withdraw() external onlyOwner {
        (bool hs, ) = payable(0xb74D713420724CC379312376f48177E29455F00D).call{
            value: (address(this).balance * 30) / 100
        }("");
        require(hs);

        (bool os, ) = payable(0xb4AE62b059Ad163BDF4Ac67c8Fa3D77EB465007c).call{
            value: address(this).balance
        }("");
        require(os);
    }
}