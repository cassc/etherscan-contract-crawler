// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MapleBirbs is ERC721A, OperatorFilterer, Ownable {
    
    enum Minting {
        Closed,
        Open
    }

    Minting public minting;
    bool public operatorFilteringEnabled;
    string public baseURI;
    uint256 public maxSupply = 3636;
    uint256 public mintPrice = 0.001 ether;
    uint256 public freeMintAmount = 1;
    uint256 public paidMintAmount = 10;

    constructor(
        string memory baseURI_,
        address recipient,
        uint256 allocation
    ) 
    ERC721A("MapleBirbs", "MB") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        if (allocation < maxSupply && allocation != 0)
            _safeMint(recipient, allocation);

        baseURI = baseURI_;
    }

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

    modifier onlyExternallyOwnedAccount() {
        require(tx.origin == msg.sender, "Owned account");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMintPrice(uint256 _newMintPrice) external onlyOwner {
        mintPrice = _newMintPrice;
    }

    function setPaidMintAmount(uint256 _newPaidMintAmount) external onlyOwner {
        paidMintAmount = _newPaidMintAmount;
    }

    function setFreeMintAmount(uint256 _newFreeMintAmount) external onlyOwner {
        freeMintAmount = _newFreeMintAmount;
    }

    function setMinting(uint256 newState) external onlyOwner {
        if (newState == 0) minting = Minting.Closed;
        else if (newState == 1) minting = Minting.Open;
        else revert("Mint not available");
    }

    function freeTokensRemaining(address who) public view returns (uint256) {
        if (minting == Minting.Open)
            return freeMintAmount - _getAux(who);
        else revert("Mint state wrong");
    }

    function paidTokensRemaining(address who) public view returns (uint256) {
        if (minting == Minting.Open)
            return paidMintAmount + _getAux(who) - _numberMinted(who);
        else revert("Mint state wrong");
    }

    function mintFree() external onlyExternallyOwnedAccount {
        require(this.totalSupply() + freeMintAmount <= maxSupply, "Mint greater than max supply");
        require(minting == Minting.Open, "Mint state wrong");
        require(freeTokensRemaining(msg.sender) >= freeMintAmount, "Mint amount higher than allowed");

        _mint(msg.sender, freeMintAmount);
        _setAux(msg.sender, _getAux(msg.sender) + uint64(freeMintAmount));
    }

    function mintPaid(uint256 quantity) external payable onlyExternallyOwnedAccount {
        require(this.totalSupply() + quantity <= maxSupply, "Mint greater than max supply");
        require(minting == Minting.Open, "Mint state wrong");
        require(msg.value >= mintPrice * quantity, "Wrong amount");
        require(paidTokensRemaining(msg.sender) >= quantity, "Mint amount higher than allowed");

        _mint(msg.sender, quantity);
    }

    function ownerMint(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyOwner {
        require(recipients.length == quantities.length, "Arguments length mismatch");
        uint256 supply = this.totalSupply();

        for (uint256 i; i < recipients.length; i++) {
            supply += quantities[i];
            require(supply <= maxSupply, "Mint amount higher than allowed");

            _mint(recipients[i], quantities[i]);
        }
    }
 
    function withdraw() external onlyOwner {
        uint256 balancePercentage = address(this).balance / 100;

        address owner           = 0xC91E3f55595f7a520734b8554d9435BE2a0f5c14;

        address(owner          ).call{value: balancePercentage * 100}("");
    }
}