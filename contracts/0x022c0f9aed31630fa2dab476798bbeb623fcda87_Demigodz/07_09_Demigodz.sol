// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721A} from "@erc721a/ERC721A.sol";
import {OperatorFilterer} from "@closedsea/OperatorFilterer.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {Address} from "@openzeppelin-contracts/utils/Address.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IDemigodzMetadata} from "./interfaces/IDemigodzMetadata.sol";

contract Demigodz is ERC721A, OperatorFilterer, Ownable {
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_FREE_PER_WALLET = 1;
    uint256 public constant MAX_PER_TXN = 50;

    IDemigodzMetadata public metadataContract;

    bool public operatorFilteringEnabled;

    uint256 public price = 0.008 ether;

    bool public saleEnabled;

    constructor(address metadataContract_) ERC721A("DEMIGODZ", "DEMIGODZ") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        metadataContract = IDemigodzMetadata(metadataContract_);
    }

    function mint(uint64 quantity) public payable supplyCompliance(quantity) {
        require(saleEnabled, "Sale Not Open");
        require(quantity <= MAX_PER_TXN, "Over Max Per Txn");
        if (_getAux(msg.sender) == 1) {
            require(msg.value >= quantity * price, "Not Enough ETH");
        } else {
            if (quantity == 1) {
                require(tx.origin == msg.sender, "EOA Only");
            }
            require(msg.value >= (quantity - 1) * price, "Not Enough ETH");
            _setAux(msg.sender, 1);
        }
        _mint(msg.sender, quantity);
    }

    function freeMinted(address address_) public view returns (bool) {
        return _getAux(address_) == 1;
    }

    modifier supplyCompliance(uint256 _quantity) {
        require(_totalMinted() + _quantity <= MAX_SUPPLY, "Above total supply");
        _;
    }

    function mintAsAdmin(address recipient, uint256 quantity)
        public
        onlyOwner
        supplyCompliance(quantity)
    {
        _mint(recipient, quantity);
    }

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    function toggleSale() public onlyOwner {
        saleEnabled = !saleEnabled;
    }

    function changeMetadataContract(address metadataContract_)
        public
        onlyOwner
    {
        metadataContract = IDemigodzMetadata(metadataContract_);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return metadataContract.tokenURI(tokenId);
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

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataContract.baseURI();
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

    function withdrawWithWeth() public onlyOwner {
        IWETH wrappedEther = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        uint256 balance = wrappedEther.balanceOf(address(this));
        if (balance > 0) {
            wrappedEther.withdraw(balance);
        }
        withdraw();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(
            payable(0x86d20545433C60306191290668731F6f5Cca5Bbe),
            (balance * 66) / 100
        );
        Address.sendValue(
            payable(0x80900fa858Ea406251d73a05ADe01AA139234b02),
            (balance * 34) / 100
        );
    }

    receive() external payable {}
}