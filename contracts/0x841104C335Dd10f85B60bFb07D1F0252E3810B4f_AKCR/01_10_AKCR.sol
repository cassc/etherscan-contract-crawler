// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DefaultOperatorFilterer.sol";

contract AKCR is Ownable, ERC721A, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint;

    uint256 public cost = 0 ether;
    uint256 public maxSupply = 5000;
    uint256 public maxPerWalletPublic = 1;
    uint256 public maxPerTx = 1;
    

    string public uriPrefix = "";
    string public hiddenMetadataUri = "ipfs://QmYATkFcVTwFUHKm1WCKTmjuZc6XunsHrpEjm1HXPv5PVE";

    mapping(address => uint256) public publicMinted;

    constructor() ERC721A("AKCR", "AKCR") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxPerTx,
            "Invalid mint amount"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded"
        );
        _;
    }
    function publicMint(uint256 amount) public payable mintCompliance(amount) {
        require(publicMinted[msg.sender] + amount <= maxPerWalletPublic, "Can't mint that many");
        require(msg.value == cost * amount, "Insufficient funds");
        _safeMint(msg.sender, amount);
    }

    function mintForAddress(uint256 amount, address _receiver)
        public
        onlyOwner
    {
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        _safeMint(_receiver, amount);
    }

    // GETTERS
    function numberMinted(address _minter) public view returns (uint256) {
        return _numberMinted(_minter);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory) { require(_exists(_tokenId),"RUG: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0 ? string( abi.encodePacked(currentBaseURI,_tokenId.toString(),".json")) : string(abi.encodePacked(hiddenMetadataUri));
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply < maxSupply, "Max supply cannot be increased");
        maxSupply = _maxSupply;
    }

    function setMaxMintAmountPerTx(uint256 _maxPerTx)
        public
        onlyOwner
    {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerWalletPublic(uint256 _maxPerWalletPublic)
        public
        onlyOwner
    {
        maxPerWalletPublic = _maxPerWalletPublic;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    // WITHDRAW
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

        // Operator Filter

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}