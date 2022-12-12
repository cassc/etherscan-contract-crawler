// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// ███████╗██╗   ██╗ ██████╗██╗  ██╗    ████████╗██╗  ██╗███████╗
// ██╔════╝██║   ██║██╔════╝██║ ██╔╝    ╚══██╔══╝██║  ██║██╔════╝
// █████╗  ██║   ██║██║     █████╔╝        ██║   ███████║█████╗
// ██╔══╝  ██║   ██║██║     ██╔═██╗        ██║   ██╔══██║██╔══╝
// ██║     ╚██████╔╝╚██████╗██║  ██╗       ██║   ██║  ██║███████╗
// ╚═╝      ╚═════╝  ╚═════╝╚═╝  ╚═╝       ╚═╝   ╚═╝  ╚═╝╚══════╝

// ███████╗██╗      ██████╗  ██████╗ ██████╗     ██████╗ ██████╗ ██╗ ██████╗███████╗
// ██╔════╝██║     ██╔═══██╗██╔═══██╗██╔══██╗    ██╔══██╗██╔══██╗██║██╔════╝██╔════╝
// █████╗  ██║     ██║   ██║██║   ██║██████╔╝    ██████╔╝██████╔╝██║██║     █████╗
// ██╔══╝  ██║     ██║   ██║██║   ██║██╔══██╗    ██╔═══╝ ██╔══██╗██║██║     ██╔══╝
// ██║     ███████╗╚██████╔╝╚██████╔╝██║  ██║    ██║     ██║  ██║██║╚██████╗███████╗
// ╚═╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝╚═╝ ╚═════╝╚══════╝
// by mindrash

import {ERC721A} from "./ERC721A.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract nft is ERC721A, OperatorFilterer, Ownable {
    bool public operatorFilteringEnabled;
    bool public paused;
    uint256 public cost;
    uint256 public maxSupply;
    string private uriPrefix;
    string private uriSuffix;

    constructor() ERC721A("Fuck The Floor Price", "FTFPMINDRASH") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        cost = 100000000000000000;
        paused = true;
        maxSupply = 450;
        uriSuffix = ".json";
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "Minting is paused.");
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        currentBaseURI = string.concat(
            currentBaseURI,
            Strings.toString(_tokenId)
        );

        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, uriSuffix))
                : "";
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
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

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "Invalid mint amount.");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded."
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds.");
        _;
    }
}