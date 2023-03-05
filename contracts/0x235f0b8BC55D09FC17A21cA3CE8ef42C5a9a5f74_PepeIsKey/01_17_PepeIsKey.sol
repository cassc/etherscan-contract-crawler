// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import "./lib/ERC721Enumerable.sol";


error MintNotLive();
error ExceedsMaxSupply();
error MintLimitReached();
error InsufficientPayment();

abstract contract NeonPepeNFT is ERC721Enumerable, Ownable, OperatorFilterer {
    function burn(uint256 tokenId) public {}
}

contract PepeIsKey is ERC721A, OperatorFilterer, Ownable {
    // Variables
    event ReceivedEth(uint256 amount);

    bool public showReady;

    uint256 public MAX_SUPPLY = 4269;

    uint256 public maxPerTx = 5;

    string public _baseTokenURI;

    uint256 public token_price = 0.005 ether;

    NeonPepeNFT neonPepe;

    bool evolveStart;

    bool public operatorFilteringEnabled;


    // Constructor

    constructor() ERC721A("PepeIsKey", "PIK") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _safeMint(msg.sender, 3);

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



    // Mint

    function startTheShow() public onlyOwner {
        showReady = !showReady;
    }

    function mint(uint256 qty) external payable  {
        if (!showReady) revert MintNotLive();
        if (_totalMinted() + qty > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (qty > maxPerTx) revert MintLimitReached();
        if (msg.value < qty * token_price) revert InsufficientPayment();
        _mint(msg.sender, qty);
    }

    /**
     * @dev override ERC721A _startTokenId()
     */
    function _startTokenId() 
        internal 
        view 
        virtual
        override 
        returns (uint256) {
        return 1;
    }
    // Token URI

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    function PepeEvolve(uint256[] calldata nft1Ids)
        external
        payable
    {
        require(evolveStart, 'Pepe Evolution has not started');
        for (uint256 i = 0; i < nft1Ids.length; i++) {
            neonPepe.burn(nft1Ids[i]);
        }
        _mint(msg.sender, nft1Ids.length);
    }

    function startEvolve() public onlyOwner {
        evolveStart = !evolveStart;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }
    // Withdraw

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice >= 0, "Token price must be greater than zero");
        token_price = newPrice;
    }

    function setKeySupply(uint256 _supply) external onlyOwner {
        require(_supply >= MAX_SUPPLY, "Token price must be greater than zero");
        MAX_SUPPLY = _supply;
    }


    function fund() public payable {
        emit ReceivedEth(msg.value);
    }

    receive() external payable  { 
        fund();
    }

    fallback() external payable {
        fund();
    }
}