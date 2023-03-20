// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";


error MintNotLive();
error ExceedsMaxSupply();
error MintLimitReached();
error InsufficientPayment();


contract EnchantedOfficial is ERC721A, OperatorFilterer, Ownable {


    event ReceivedEth(uint256 amount);

    bool public enchantStart;

    uint256 public MAX_SUPPLY = 1000;

    uint256 public maxPublicSupply = 500;

    uint256 public  maxPerTx = 5;

    string public _baseTokenURI;

    uint256 public price = 0.025 ether;


    bool public operatorFilteringEnabled;


    modifier validateSupply(uint256 _maxSupply, uint256 _quantity) {
        require(
            _totalMinted() + _quantity <= _maxSupply,
            "The current stage has nothing remaining"
        );
        _;
    }

    // Constructor

    constructor() ERC721A("EnchantedOfficial", "EO") {
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

    function enchant() public onlyOwner {
        enchantStart = !enchantStart;
    }

    function mint(uint256 qty) external payable 
        validateSupply(maxPublicSupply, qty)
    {
        if (!enchantStart) revert MintNotLive();
        if (_totalMinted() + qty > MAX_SUPPLY) revert ExceedsMaxSupply();
        if (qty > maxPerTx) revert MintLimitReached();
        if (msg.value < qty * price) revert InsufficientPayment();
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

    function publicMintNextPhase(uint256 _supply) external onlyOwner {
        maxPublicSupply = _supply;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function influx() public payable {
        emit ReceivedEth(msg.value);
    }

    receive() external payable  { 
        influx();
    }

    fallback() external payable {
        influx();
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