// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


/*

FUMO Exchange Grand Opening

$FUMO only goes UP

*/
error InsufficientPayment();

contract FumoExchangeRockCommodity is ERC721A, DefaultOperatorFilterer, Ownable {

    bool public GrandOpening;

    ERC721A public milady = ERC721A(0x5Af0D9827E0c53E4799BB226655A1de152A425a5);


    uint256 public MAX_SUPPLY = 690;

    uint256 public  maxPerTx = 5;
    uint256 public  maxPerWallet = 10;


    string public _baseTokenURI;

    uint256 public price = 0.005 ether;

    // Constructor

    constructor() ERC721A("Fumo Exchange Rock Commodity", "FER") {
        _safeMint(msg.sender, 10);

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

    // Mint

    function grandOpen() public onlyOwner {
        GrandOpening = !GrandOpening;
    }

    function FumoIt(uint256 qty) external payable 
    {
        require(tx.origin == msg.sender, 'Bye bye bot');
        require(GrandOpening, 'Mint not live yet');
        require(_totalMinted() + qty <= MAX_SUPPLY, 'ExceedsMaxSupply');
        require(qty <= maxPerTx, 'MintLimitReached');

        require(msg.value >= qty * price, 'InsufficientPayment');
        

        _mint(msg.sender, qty);

    }

    function miladyClaim() external {
        require(milady.balanceOf(msg.sender) > 0, 'Not Milady holder');
        _mint(msg.sender, 1);

    }

    function setMaxPerTxn(uint256 _num) external onlyOwner {
        require(_num >= 0, "Num must be greater than zero");
        maxPerTx = _num;
    } 

    function setMaxPerWallet(uint256 _num) external onlyOwner {
        require(_num >= 0, "Num must be greater than zero");
        maxPerWallet = _num;
    } 

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice >= 0, "Token price must be greater than zero");
        price = newPrice;
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

    function miladyDrop(address[] calldata addys, uint256 _quantity) external onlyOwner {

        for (uint i = 0; i < addys.length; i++) {
            _safeMint(addys[i], _quantity);
        }
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


    function miiilady() public payable {
    }

    receive() external payable  { 
        miiilady();
    }

    fallback() external payable {
        miiilady();
    }



}