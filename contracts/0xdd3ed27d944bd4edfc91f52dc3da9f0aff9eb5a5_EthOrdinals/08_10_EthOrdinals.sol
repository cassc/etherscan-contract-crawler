// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721A} from "@erc721a/ERC721A.sol";
import {OperatorFilterer} from "@closedsea/OperatorFilterer.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin-contracts/utils/Address.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IEthOrdinalsMetadata} from "./interfaces/IEthOrdinalsMetadata.sol";

contract EthOrdinals is ERC721A, OperatorFilterer, Ownable, ReentrancyGuard {
    bool public operatorFilteringEnabled;
    bool public saleOpen;
    uint256 public mintableSupply;
    IEthOrdinalsMetadata public metadataContract;

    constructor(address metadataContract_, uint256 mintableSupply_)
        ERC721A("ETH Ordinals", "EO")
    {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        mintableSupply = mintableSupply_;
        metadataContract = IEthOrdinalsMetadata(metadataContract_);
    }

    function mint() public payable {
        require(saleOpen, "Sale Not Open");
        require(_totalMinted() + 1 <= mintableSupply, "Sold Out");
        require(_getAux(msg.sender) == 0, "Max 1 Per Wallet");
        require(tx.origin == msg.sender, "EOA Only");
        _setAux(msg.sender, 1);
        _mint(msg.sender, 1);
    }

    function freeMinted(address address_) public view returns (bool) {
        return _getAux(address_) == 1;
    }

    function mintAsAdmin(address recipient, uint256 quantity) public onlyOwner {
        require(_totalMinted() + quantity <= mintableSupply, "Max Supply Hit");
        _mint(recipient, quantity);
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

    function toggleSale() public onlyOwner {
        saleOpen = !saleOpen;
    }

    function setMintableSupply(uint256 mintableSupply_) public onlyOwner {
        mintableSupply = mintableSupply_;
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

    function changeMetadataContract(address metadataContract_)
        public
        onlyOwner
    {
        metadataContract = IEthOrdinalsMetadata(metadataContract_);
    }

    function withdrawWeth() public nonReentrant {
        IWETH wrappedEther = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        uint256 balance = wrappedEther.balanceOf(address(this));
        if (balance > 0) {
            wrappedEther.withdraw(balance);
        }
        _withdraw();
    }

    function withdraw() public nonReentrant {
        _withdraw();
    }

    function _withdraw() internal {
        uint256 balance = address(this).balance;
        Address.sendValue(
            payable(address(0xa4e96F19B0dA586A50136036b1B96982a603C65E)),
            (balance * 60) / 100
        );
        Address.sendValue(
            payable(address(0x7652B65dc5a23377EE9b6Eb7c829e0C5102a16e0)),
            (balance * 40) / 100
        );
    }

    receive() external payable {}
}