// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721A} from "@erc721a/ERC721A.sol";
import {OperatorFilterer} from "@closedsea/OperatorFilterer.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {Address} from "@openzeppelin-contracts/utils/Address.sol";

/**
 * @title Orion NFT
 */
contract OrionERC721A is ERC721A, OperatorFilterer, Ownable {
    uint256 public constant MAX_SUPPLY = 4555;
    uint256 public constant MAX_PER_WALLET = 10;

    string private baseURI;
    bool private revealed;
    bool public open;

    bool public operatorFilteringEnabled;

    uint256 public price = 0.0089 ether;

    constructor(string memory baseURI_) ERC721A("ORION", "ORION") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        baseURI = baseURI_;
    }

    function mint(uint64 quantity)
        public
        payable
        insideTotalSupply(quantity)
        onlyEoa
    {
        require(open, "Sale Not Open");
        uint64 numMints = _getAux(msg.sender) + quantity;
        require(numMints <= MAX_PER_WALLET, "Wallet Limit");
        if (numMints > 1) {
            require(msg.value >= price * quantity, "Insufficent Funds");
        }
        _setAux(msg.sender, numMints);
        _mint(msg.sender, quantity);
    }

    modifier onlyEoa() {
        require(tx.origin == msg.sender, "Not EOA");
        _;
    }

    modifier insideTotalSupply(uint256 _quantity) {
        require(_totalMinted() + _quantity <= MAX_SUPPLY, "Above total supply");
        _;
    }

    function mintAsAdmin(address recipient, uint256 quantity)
        public
        onlyOwner
        insideTotalSupply(quantity)
    {
        _mint(recipient, quantity);
    }

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory result;
        if (revealed) {
            result = string(abi.encodePacked(baseURI, _toString(tokenId)));
        } else {
            result = baseURI;
        }
        return bytes(baseURI).length != 0 ? result : "";
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function toggleSale() public onlyOwner {
        open = !open;
    }

    function setBaseUri(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
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

    function _operatorFilteringEnabled()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return operatorFilteringEnabled;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(
            payable(0x0BB705C88Bfd26E858Ce7704C0D1716e31ff6e06),
            (balance * 60) / 100
        );
        Address.sendValue(
            payable(0x41eB2B94dFe7163F5405402C826948405a5733A4),
            (balance * 40) / 100
        );
    }

    receive() external payable {}
}