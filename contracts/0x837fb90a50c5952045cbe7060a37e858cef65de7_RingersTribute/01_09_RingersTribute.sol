// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


/*

 ███████████    ███                                                    ███████████            ███  █████                 █████            
░░███░░░░░███  ░░░                                                    ░█░░░███░░░█           ░░░  ░░███                 ░░███             
 ░███    ░███  ████  ████████    ███████  ██████  ████████   █████    ░   ░███  ░  ████████  ████  ░███████  █████ ████ ███████    ██████ 
 ░██████████  ░░███ ░░███░░███  ███░░███ ███░░███░░███░░███ ███░░         ░███    ░░███░░███░░███  ░███░░███░░███ ░███ ░░░███░    ███░░███
 ░███░░░░░███  ░███  ░███ ░███ ░███ ░███░███████  ░███ ░░░ ░░█████        ░███     ░███ ░░░  ░███  ░███ ░███ ░███ ░███   ░███    ░███████ 
 ░███    ░███  ░███  ░███ ░███ ░███ ░███░███░░░   ░███      ░░░░███       ░███     ░███      ░███  ░███ ░███ ░███ ░███   ░███ ███░███░░░  
 █████   █████ █████ ████ █████░░███████░░██████  █████     ██████        █████    █████     █████ ████████  ░░████████  ░░█████ ░░██████ 
░░░░░   ░░░░░ ░░░░░ ░░░░ ░░░░░  ░░░░░███ ░░░░░░  ░░░░░     ░░░░░░        ░░░░░    ░░░░░     ░░░░░ ░░░░░░░░    ░░░░░░░░    ░░░░░   ░░░░░░  
                                ███ ░███                                                                                                  
                               ░░██████                                                                                                   
                                ░░░░░░                     

*/
error InsufficientPayment();

contract RingersTribute is ERC721A, DefaultOperatorFilterer, Ownable {

    bool public tributeStart;

    uint256 public MAX_SUPPLY = 1024;

    uint256 public  maxPerTx = 5;
    uint256 public  maxPerWallet = 10;

    string public _baseTokenURI;

    uint256 public price = 0.006529 ether;

    // Constructor

    constructor() ERC721A("RingersTribute", "RT") {
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

    function TributeLive() public onlyOwner {
        tributeStart = !tributeStart;
    }

    function mint(uint256 qty) external payable 
    {
        require(tributeStart, 'Mint not live yet');
        require(_totalMinted() + qty <= MAX_SUPPLY, 'ExceedsMaxSupply');
        require(qty <= maxPerTx, 'MintLimitReached');
        if (msg.value < qty * price) revert InsufficientPayment();
        _mint(msg.sender, qty);
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

    function setdrop(address[] calldata boardAddresses, uint256 _quantity) external onlyOwner {

        for (uint i = 0; i < boardAddresses.length; i++) {
            _safeMint(boardAddresses[i], _quantity);
        }
    }   

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function receiving() public payable {
    }

    receive() external payable  { 
        receiving();
    }

    fallback() external payable {
        receiving();
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

}