// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TheHighMonks is ERC721A, Ownable, ReentrancyGuard {
    string public PROVENANCE;

    uint256 public maxSupply;
    uint256 public pricePerToken;

    bool public whitelistMintActive = false;
    bool public publicMintActive = false;

    uint256 public constant MAX_PUBLIC_MINT = 7;

    uint256 private _numberOfReserved;
    string private _baseURIextended;
    string private _contractURI;
    mapping(address => uint8) private _whitelist;

    constructor(
        uint256 _maxBatchSize,
        uint256 _maxSupply,
        uint256 _pricePerToken
    ) ERC721A("TheHighMonks", "THM", _maxBatchSize, _maxSupply) {
        pricePerToken = _pricePerToken;
        maxSupply = _maxSupply;
    }

    function setPricePerToken(uint256 _pricePerToken) external onlyOwner {
        require(_pricePerToken > pricePerToken, "Can only set higher price");
        pricePerToken = _pricePerToken;
    }

    function setWhitelistMintActive(bool _whitelistMintActive)
        external
        onlyOwner
    {
        whitelistMintActive = _whitelistMintActive;
    }

    function addToWhitelist(
        address[] calldata addresses,
        uint8 numberAllowedToMint
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = numberAllowedToMint;
        }
    }

    function numberAvailableToMint(address addressToMint)
        external
        view
        returns (uint8)
    {
        return _whitelist[addressToMint];
    }

    function mintWhitelisted(uint8 numberToMint) external payable {
        uint256 totalSupply = totalSupply();
        require(whitelistMintActive, "Whitelist mint is not active");
        require(
            numberToMint <= _whitelist[msg.sender],
            "Exceeded max available to purchase"
        );
        require(
            totalSupply + numberToMint <= maxSupply - _numberOfReserved,
            "Purchase would exceed max tokens"
        );
        require(
            pricePerToken * numberToMint <= msg.value,
            "Ether value sent is not correct"
        );

        _whitelist[msg.sender] -= numberToMint;
        _safeMint(msg.sender, numberToMint);
    }

    function reserve(uint256 numberToReserve) public onlyOwner {
        uint256 totalSupply = totalSupply();
        require(
            totalSupply + numberToReserve <= maxSupply,
            "Reserve too many tokens"
        );

        _numberOfReserved = numberToReserve;
    }

    function mintReserved(address to, uint256 numberToMint) public onlyOwner {
        require(numberToMint <= _numberOfReserved, "Mint more than reserved");
        _safeMint(to, numberToMint);
        _numberOfReserved -= numberToMint;
    }

    function setPublicMintActive(bool _publicMintActive) public onlyOwner {
        publicMintActive = _publicMintActive;
    }

    function mint(uint256 numberToMint) public payable {
        uint256 totalSupply = totalSupply();
        require(publicMintActive, "Public mint must be active to mint tokens");
        require(numberToMint <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(
            totalSupply + numberToMint <= maxSupply - _numberOfReserved,
            "Purchase would exceed max tokens"
        );
        require(
            pricePerToken * numberToMint <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, numberToMint);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }
}