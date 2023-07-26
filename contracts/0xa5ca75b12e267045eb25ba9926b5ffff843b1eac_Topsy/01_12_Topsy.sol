// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721A/contracts/ERC721A.sol";
import "./operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Topsy is
    ERC721A,
    Ownable,
    ERC2981,
    DefaultOperatorFilterer
{
    string private _baseTokenURI = "ipfs://QmWmC6HuAE6XKQV3hhys2Wrpi4Ai7aWwwX96xQM2ykRqDt/";

    address private constant MAIN_WALLET_ADDRESS = 0xF1dcE0ec855A5837ae1346EB4D91447d4491A388;

    mapping(address => uint256) private _whitelistAddressAndMaxMintQuantityMap;

    uint256 private _publicSaleMaxMintQuantity = 10;

    uint256 private _tokenCirculation = 1200;

    uint256 private _reservedSupply = 0;

    uint256 private _whitelistSaleTokenPrice = 0.28 ether;

    uint256 private _publicSaleTokenPrice = 0.28 ether;

    bool private _isWhitelistSaleActived = false;
    uint256 private _whitelistSaleStartTime = 0;
    uint256 private _whitelistSaleEndTime = 0;

    bool private _isPublicSaleActived = false;
    uint256 private _publicSaleStartTime = 0;
    uint256 private _publicSaleEndTime = 0;

    mapping(address => uint256) private _addressSaleMintedQuantityMap;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() ERC721A("TOPSY", "TOPSY") {
        _setDefaultRoyalty(MAIN_WALLET_ADDRESS, 250);//2.5%
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
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

    function whitelistSaleMint(uint256 quantity) public payable {
        require(quantity > 0, "Invalid quantity");

        uint256 maxMintQuantity = _whitelistAddressAndMaxMintQuantityMap[msg.sender];
        require(maxMintQuantity > 0, "Not in whitelist");
        require(_addressSaleMintedQuantityMap[msg.sender] + quantity <= maxMintQuantity, "Exceed max mint quantity");

        require(msg.value >= _whitelistSaleTokenPrice * quantity, "Not enough ETH mint");
        require(_totalMinted() + quantity <= _tokenCirculation - _reservedSupply, "Exceed token circulation");

        require(_isWhitelistSaleActived && (block.timestamp > _whitelistSaleStartTime), "Whitelist sale is not yet started");
        require(_isWhitelistSaleActived && (block.timestamp < _whitelistSaleEndTime), "Whitelist sale is end");


        _addressSaleMintedQuantityMap[msg.sender] = _addressSaleMintedQuantityMap[msg.sender] + quantity;

        _safeMint(msg.sender, quantity);
    }

    function publicSaleMint(uint256 quantity) public payable {
        require(quantity > 0, "Invalid quantity");
        require(quantity <= _publicSaleMaxMintQuantity, "Invalid quantity");
        require(_addressSaleMintedQuantityMap[msg.sender] + quantity <= _publicSaleMaxMintQuantity, "Exceed max mint quantity");

        require(msg.value >= _publicSaleTokenPrice * quantity, "Not enough ETH mint");
        require(_totalMinted() + quantity <= _tokenCirculation - _reservedSupply, "Exceed token circulation");

        require(_isPublicSaleActived && (block.timestamp > _publicSaleStartTime), "Public sale is not yet started");
        require(_isPublicSaleActived && (block.timestamp < _publicSaleEndTime), "Public sale is end");


        _addressSaleMintedQuantityMap[msg.sender] = _addressSaleMintedQuantityMap[msg.sender] + quantity;

        _safeMint(msg.sender, quantity);
    }

    function airdrop(address to, uint256 quantity) public onlyOwner {
        require(quantity > 0, "Invalid quantity");
        
        require(_totalMinted() + quantity <= _tokenCirculation, "Exceed token circulation");

        _safeMint(to, quantity);
    }

    function batchAirdrop(address[] calldata addresses, uint256[] calldata quantities) public onlyOwner {
        require(addresses.length == quantities.length, "The length of addresses and quantities are not matched");

        uint256 addressesLength = addresses.length;
        for (uint256 i = 0; i < addressesLength; ++i) {
            airdrop(addresses[i], quantities[i]);
        }
    }

    function burn(uint256 tokenId) public callerIsUser {
        require(this.ownerOf(tokenId) == msg.sender, "Ownable: caller is not the token owner");

        _burn(tokenId, false);
    }

    function batchBurn(uint256[] calldata tokenIds) public callerIsUser {
        uint256 tokenIdsLength = tokenIds.length;
        for (uint256 i = 0; i < tokenIdsLength; ++i) {
            burn(tokenIds[i]);
        }
    }

    function withdraw() public onlyOwner {
        //require(address(this).balance > 0 ether, "Not enough ETH withdraw");

        payable(MAIN_WALLET_ADDRESS).transfer(address(this).balance);
    }

    function setBaseTokenURI(string calldata baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setDefaultRoyalty(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(MAIN_WALLET_ADDRESS, feeNumerator);
    }

    function getWhitelistAddressMaxMintQuantity(address inAddress) view public returns(uint256) {
        return _whitelistAddressAndMaxMintQuantityMap[inAddress];
    }

    function setWhitelistAddressesMaxMintQuantity(address[] calldata addresses, uint256 maxMintQuantity) public onlyOwner {
        uint256 addressesLength = addresses.length;
        for (uint256 i = 0; i < addressesLength; ++i) {
            _whitelistAddressAndMaxMintQuantityMap[addresses[i]] = maxMintQuantity;
        }
    }

    function getPublicSaleMaxMintQuantity() view public returns(uint256) {
        return _publicSaleMaxMintQuantity;
    }

    function setPublicSaleMaxMintQuantity(uint256 publicSaleMaxMintQuantity) public onlyOwner {
        _publicSaleMaxMintQuantity = publicSaleMaxMintQuantity;
    }

    function getTokenCirculation() view public returns(uint256) {
        return _tokenCirculation;
    }

    function setTokenCirculation(uint256 tokenCirculation) public onlyOwner {
        _tokenCirculation = tokenCirculation;
    }

    function getReservedSupply() view public returns(uint256) {
        return _reservedSupply;
    }

    function setReservedSupply(uint256 reservedSupply) public onlyOwner {
        _reservedSupply = reservedSupply;
    }

    function getWhitelistSaleTokenPrice() view public returns(uint256) {
        return _whitelistSaleTokenPrice;
    }

    function setWhitelistSaleTokenPrice(uint256 whitelistSaleTokenPrice) public onlyOwner {
        _whitelistSaleTokenPrice = whitelistSaleTokenPrice;
    }

    function getPublicSaleTokenPrice() view public returns(uint256) {
        return _publicSaleTokenPrice;
    }

    function setPublicSaleTokenPrice(uint256 publicSaleTokenPrice) public onlyOwner {
        _publicSaleTokenPrice = publicSaleTokenPrice;
    }

    function controlWhitelistSale(bool isSaleActived, uint256 saleStartTime, uint256 saleEndTime) public onlyOwner {
        _isWhitelistSaleActived = isSaleActived;
        _whitelistSaleStartTime = saleStartTime;
        _whitelistSaleEndTime = saleEndTime;
    }

    function controlPublicSale(bool isSaleActived, uint256 saleStartTime, uint256 saleEndTime) public onlyOwner {
        _isPublicSaleActived = isSaleActived;
        _publicSaleStartTime = saleStartTime;
        _publicSaleEndTime = saleEndTime;
    }

    function getIsWhitelistSaleActived() view public returns(bool) {
        return _isWhitelistSaleActived;
    }

    function getWhitelistSaleStartTime() view public returns(uint256) {
        return _whitelistSaleStartTime;
    }

    function getWhitelistSaleEndTime() view public returns(uint256) {
        return _whitelistSaleEndTime;
    }

    function getIsPublicSaleActived() view public returns(bool) {
        return _isPublicSaleActived;
    }

    function getPublicSaleStartTime() view public returns(uint256) {
        return _publicSaleStartTime;
    }

    function getPublicSaleEndTime() view public returns(uint256) {
        return _publicSaleEndTime;
    }

    function getAddressSaleMintedQuantity(address inAddress) view public returns(uint256) {
        return _addressSaleMintedQuantityMap[inAddress];
    }

    function setAddressesSaleMintedQuantity(address[] calldata addresses, uint256 saleMintedQuantity) public onlyOwner {
        uint256 addressesLength = addresses.length;
        for (uint256 i = 0; i < addressesLength; ++i) {
            _addressSaleMintedQuantityMap[addresses[i]] = saleMintedQuantity;
        }
    }

    //the result is non-grouping
    function tokenOwners() view public returns(address[] memory) {
        address[] memory tokenOwnerAddresses = new address[](totalSupply());

        uint currentTokenOwnerAddressesIndex = 0;

        uint256 endTokenId = _startTokenId() + _totalMinted();
        for(uint256 tokenId = _startTokenId(); tokenId < endTokenId; ++tokenId) {
            if(_exists(tokenId)) {
                tokenOwnerAddresses[currentTokenOwnerAddressesIndex] = ownerOf(tokenId);

                ++currentTokenOwnerAddressesIndex;
            }
        }

        return tokenOwnerAddresses;
    }
}