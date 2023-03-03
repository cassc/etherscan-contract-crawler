// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AllYourBase is ERC721A, OperatorFilterer, Ownable {
    
    enum MintState {
        Closed,
        Open
    }

    MintState public mintState;

    bool public operatorFilteringEnabled;

    string public baseURI;

    uint256 public SUPPLY = 4444;
    
    uint256 public PRICE = 0.001 ether;
    
    uint256 public FREE_AMOUNT = 1;
    uint256 public PAID_AMOUNT = 10;

    constructor(
        string memory baseURI_,
        address recipient,
        uint256 allocation
    ) 
    ERC721A("AllYourBase", "AYB") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        if (allocation < SUPPLY && allocation != 0)
            _safeMint(recipient, allocation);

        baseURI = baseURI_;
    }

    // ----- Overrides -----

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // ----- Allowed Operators -----

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

    // ----- Modifiers -----

    modifier onlyExternallyOwnedAccount() {
        require(tx.origin == msg.sender, "Not externally owned account");
        _;
    }

    // ----- Token URI -----

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    // ----- Edit -----

    function setSupply(uint256 _newSupply) external onlyOwner {
        SUPPLY = _newSupply;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        PRICE = _newPrice;
    }

    function setPaidAmount(uint256 _newAmount) external onlyOwner {
        PAID_AMOUNT = _newAmount;
    }

    function setFreeAmount(uint256 _newAmount) external onlyOwner {
        FREE_AMOUNT = _newAmount;
    }

    // ----- Mint -----

    function setMintState(uint256 newState) external onlyOwner {
        if (newState == 0) mintState = MintState.Closed;
        else if (newState == 1) mintState = MintState.Open;
        else revert("Mint state does not exist");
    }

    function freeTokensRemaining(address who) public view returns (uint256) {
        if (mintState == MintState.Open)
            return FREE_AMOUNT - _getAux(who);
        else revert("Mint state mismatch");
    }

    function paidTokensRemaining(address who) public view returns (uint256) {
        if (mintState == MintState.Open)
            return PAID_AMOUNT + _getAux(who) - _numberMinted(who);
        else revert("Mint state mismatch");
    }

    function mintFree() external onlyExternallyOwnedAccount {
        require(this.totalSupply() + FREE_AMOUNT <= SUPPLY, "Mint exceeds max supply");
        require(mintState == MintState.Open, "Mint state mismatch");
        require(freeTokensRemaining(msg.sender) >= FREE_AMOUNT, "Mint limit for user reached");

        _mint(msg.sender, FREE_AMOUNT);
        _setAux(msg.sender, _getAux(msg.sender) + uint64(FREE_AMOUNT));
    }

    function mintPaid(uint256 quantity) external payable onlyExternallyOwnedAccount {
        require(this.totalSupply() + quantity <= SUPPLY, "Mint exceeds max supply");
        require(mintState == MintState.Open, "Mint state mismatch");
        require(msg.value >= PRICE * quantity, "Insufficient value");
        require(paidTokensRemaining(msg.sender) >= quantity, "Mint limit for user reached");

        _mint(msg.sender, quantity);
    }

    function batchMint(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyOwner {
        require(recipients.length == quantities.length, "Arguments length mismatch");
        uint256 supply = this.totalSupply();

        for (uint256 i; i < recipients.length; i++) {
            supply += quantities[i];
            require(supply <= SUPPLY, "Batch mint exceeds max supply");

            _mint(recipients[i], quantities[i]);
        }
    }
 
    function withdraw() external onlyOwner {
        uint256 balancePercentage = address(this).balance / 100;

        address owner           = 0x5dE0385cEb0403e66b1E45741b2397a0656F4B65;

        address(owner          ).call{value: balancePercentage * 100}("");
    }
}