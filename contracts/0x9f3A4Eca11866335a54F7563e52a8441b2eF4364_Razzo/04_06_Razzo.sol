// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

error SaleNotActive();
error MaxSupplyReached();
error AlreadyMintedFree();
error WalletLimitReached();
error InsufficientPayment();

contract Razzo is ERC721A, Ownable, OperatorFilterer {

   /* Variables */
   uint256 public MAX_SUPPLY = 5555;
   uint256 public MAX_PER_WALLET = 10;
   uint256 public PRICE = 0.005 ether;

   bool public saleActive = false;
   bool public operatorFilteringEnabled;
   string public baseURI;

   /* Constructor */
   constructor(string memory baseURI_) ERC721A("Razzo", "RZZO") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        baseURI = baseURI_;
    }

    /* Overrides */
     function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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
    
    /* Mint */

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function freeMint() external {
        if (!saleActive) revert SaleNotActive();
        if (_totalMinted() + 1 > MAX_SUPPLY) revert MaxSupplyReached();
        if (_getAux(msg.sender) != 0) revert AlreadyMintedFree();
        _setAux(msg.sender, 1);
        _mint(msg.sender, 1);
    }

    function mint(uint256 amount) external payable {
        if (!saleActive) revert SaleNotActive();
        if (_totalMinted() + amount >= MAX_SUPPLY) revert MaxSupplyReached();
        if (amount > MAX_PER_WALLET) revert WalletLimitReached();
        if (msg.value < PRICE * amount) revert InsufficientPayment();
        _mint(msg.sender, amount);
    }

    /* Withdraw */
    function withdraw() external onlyOwner {
       (bool hs, ) = payable(0x7f17E6239D16cB71CCa1c3E7b13de517382794ca).call{
            value: (address(this).balance * 50) / 100
        }("");
        require(hs);

        (bool os, ) = payable(0xe41291560154B4BbBB80678d753e36F87F48fabC).call{
            value: address(this).balance
        }("");
        require(os);
    }
}