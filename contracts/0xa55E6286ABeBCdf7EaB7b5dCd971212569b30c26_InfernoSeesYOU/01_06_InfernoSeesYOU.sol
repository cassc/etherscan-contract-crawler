// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";


error MintNotLive();
error ExceedsMaxSupply();
error FreeSummonLimitReached();
error MintLimitReached();
error InsufficientPayment();


contract InfernoSeesYOU is ERC721A, OperatorFilterer, Ownable {


    event ReceivedEth(uint256 amount);

    bool public InFERnoReSSEREct;
    uint256 public MAX_SUPPLY = 666;

    uint256 public  maxPerTx = 3;

    string public _baseTokenURI;

    uint256 public summon_sacrifice = 0.01 ether;


    bool public operatorFilteringEnabled;


    // Constructor

    constructor() ERC721A("InfernoSeesYOU", "InfernoSY") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _safeMint(msg.sender, 4);

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

    function chargeCamera() public onlyOwner {
        InFERnoReSSEREct = !InFERnoReSSEREct;
    }

    function mint(uint256 qty) external payable  {
        if (!InFERnoReSSEREct) revert MintNotLive();
        if (_totalMinted() + qty > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (qty > maxPerTx) revert MintLimitReached();
        if (msg.value < qty * summon_sacrifice) revert InsufficientPayment();
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

    function send2Inferno() public payable {
        emit ReceivedEth(msg.value);
    }

    receive() external payable  { 
        send2Inferno();
    }

    fallback() external payable {
        send2Inferno();
    }
}