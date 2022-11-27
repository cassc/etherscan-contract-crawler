// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";

contract CelMangas is ERC721A, DefaultOperatorFilterer, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI;
    uint256 public cost = 0.001 ether;
    uint256 public maxSupply = 2222;
    uint256 public maxFree = 2222;
    uint256 public maxperAddressFreeLimit = 5;
    uint256 public maxperAddressPublicMint = 5;

    mapping(address => uint256) public addressFreeMintedBalance;

    constructor() ERC721A("CEL MANGAS", "CM") {
        setBaseURI("ipfs://bafybeib4k6ntg7fvdzzrneag6inof6wyynxkgdlhevtc5teqysvjatljua/");
        _safeMint(msg.sender, 5);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function MintFree(uint256 _mintAmount) public payable nonReentrant{
        uint256 s = totalSupply();
        uint256 addressFreeMintedCount = addressFreeMintedBalance[msg.sender];
        require(addressFreeMintedCount + _mintAmount <= maxperAddressFreeLimit, "max NFT per address exceeded");
        require(_mintAmount > 0, "Cant mint 0" );
        require(s + _mintAmount <= maxFree, "Cant go over supply" );
        for (uint256 i = 0; i < _mintAmount; ++i) {
            addressFreeMintedBalance[msg.sender]++;
        }
        _safeMint(msg.sender, _mintAmount);
        delete s;
        delete addressFreeMintedCount;
    }


    function mint(uint256 _mintAmount) public payable nonReentrant {
        uint256 s = totalSupply();
        require(_mintAmount > 0, "Cant mint 0");
        require(_mintAmount <= maxperAddressPublicMint, "Cant mint more then maxmint" );
        require(s + _mintAmount <= maxSupply, "Cant go over supply");
        require(msg.value >= cost * _mintAmount);
        _safeMint(msg.sender, _mintAmount);
        delete s;
    }

    function gift(uint256[] calldata quantity, address[] calldata recipient)
    external
    onlyOwner
    {
        require(
            quantity.length == recipient.length,
            "Provide quantities and recipients"
        );
        uint256 totalQuantity = 0;
        uint256 s = totalSupply();
        for (uint256 i = 0; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }
        require(s + totalQuantity <= maxSupply, "Too many");
        delete totalQuantity;
        for (uint256 i = 0; i < recipient.length; ++i) {
            _safeMint(recipient[i], quantity[i]);
        }
        delete s;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(_newMaxSupply <= maxSupply, "Cannot increase max supply");
        maxSupply = _newMaxSupply;
    }
    function setmaxFreeSupply(uint256 _newMaxFreeSupply) public onlyOwner {
        maxFree = _newMaxFreeSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMaxperAddressPublicMint(uint256 _amount) public onlyOwner {
        maxperAddressPublicMint = _amount;
    }

    function setMaxperAddressFreeMint(uint256 _amount) public onlyOwner{
        maxperAddressFreeLimit = _amount;
    }
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
        value: address(this).balance
        }("");
        require(success);
    }

    function withdrawAny(uint256 _amount) public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success);
    }

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
    public
    payable
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}