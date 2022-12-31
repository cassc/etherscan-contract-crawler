// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EtherTrials is ERC721A, OperatorFilterer, Ownable {

    enum MintState {
        Closed,
        Public
    }

    uint256 public MAX_SUPPLY = 2222;
    
    uint256 public TOKEN_PRICE = 0.01 ether;    
    uint256 public MINT_LIMIT = 2;
    
    MintState public mintState;

    string public baseURI;

    bool public operatorFilteringEnabled;

    constructor(
        string memory baseURI_,
        address recipient,
        uint256 allocation
    ) 
    ERC721A("EtherTrials", "ET") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        if (allocation < MAX_SUPPLY && allocation != 0)
            _safeMint(recipient, allocation);
        
        baseURI = baseURI_;
    }

    // Overrides

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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

    // Modifiers

    modifier onlyExternallyOwnedAccount() {
        require(tx.origin == msg.sender, "Not externally owned account");
        _;
    }

    // Token URI

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    // Mint
    function setMintState(uint256 newState) external onlyOwner {
        if (newState == 0) mintState = MintState.Closed;
        else if (newState == 1) mintState = MintState.Public;
        else revert("Mint state does not exist");
    }

    function tokensRemainingForAddress(address who) public view returns (uint256) {
        if (mintState == MintState.Public)
            return MINT_LIMIT + _getAux(who) - _numberMinted(who);
        else revert("Mint state mismatch");
    }

    function mintPublic(uint256 quantity) external payable onlyExternallyOwnedAccount {
        require(this.totalSupply() + quantity <= MAX_SUPPLY, "Mint exceeds max supply");
        require(mintState == MintState.Public, "Mint state mismatch");
        require(msg.value >= TOKEN_PRICE * quantity, "Insufficient value");
        require(tokensRemainingForAddress(msg.sender) >= quantity, "Mint limit for user reached");

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
            require(supply <= MAX_SUPPLY, "Batch mint exceeds max supply");

            _mint(recipients[i], quantities[i]);
        }
    }

    // Edit Mint

    function setSupply(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function setPublicPrice(uint256 _newPrice) external onlyOwner {
        TOKEN_PRICE = _newPrice;
    }

    function setPublicLimit(uint256 _newLimit) external onlyOwner {
        MINT_LIMIT = _newLimit;
    }

    // Withdraw
 
    function withdrawToRecipients() external onlyOwner {
        uint256 balancePercentage = address(this).balance / 100;

        address owner           = 0x95F1424FdA4d99BdFb4b3174F57e02E75e1C8269;

        address(owner          ).call{value: balancePercentage * 100}("");
    }
}