//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ReferalyGenesisPass is ERC721URIStorageUpgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable {
    uint256 public totalSupply;
    uint256 public maxBatchSize;
    uint256 public reservedTokens;

    bool public mintingOpen;
    uint256 public nftPrice;
    string public metadataURI;

    uint256 private _currentIndex;
    uint256 private _currentPrivateIndex;

    uint256 public version;
    uint256 buildNo;

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 reservedTokens_,
        uint256 maxBatchSize_,
        uint256 nftPrice_,
        string memory metadataURI_,
        bool mintingOpen_
    ) initializer public {
        require(totalSupply_ > 0, "ERC721A: collection must have a nonzero supply");
        require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");

        totalSupply = totalSupply_;
        reservedTokens = reservedTokens_;
        maxBatchSize = maxBatchSize_;
        nftPrice = nftPrice_;
        metadataURI = metadataURI_;
        mintingOpen = mintingOpen_;

        _currentIndex = reservedTokens;
        _currentPrivateIndex = 0;

        __ERC721_init(name_, symbol_);
        __Ownable_init();
        __DefaultOperatorFilterer_init();

        version = 4;
        buildNo = 202212130045;
    }

    // setters

    function setNftPrice(uint256 nftPrice_) public onlyOwner {
        nftPrice = nftPrice_;
    }

    function setMetadataURI(string memory metadataURI_) public onlyOwner {
        metadataURI = metadataURI_;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        super._setTokenURI(tokenId, _tokenURI);
    }

    function setMintingOpen(bool mintingOpen_) public onlyOwner {
        mintingOpen = mintingOpen_;
    }

    // Minting

    function mintReserved(address _to, uint256 _amount) public onlyOwner {
        require(totalReservedMinted() + _amount <= reservedTokens, "Cannot mint over reserved tokens");

        uint256 updatedIndex = _getNextPrivateTokenId();

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_to, updatedIndex);
            _setTokenURI(updatedIndex, string.concat(metadataURI, "/", Strings.toString(updatedIndex), ".json"));
            updatedIndex++;
        }

        _updatePrivateCurrentIndex(_amount);
    }

    function mint(uint256 _amount) public payable {
        require(_amount >= 1, "Must mint at least 1 token");
        require(_amount <= maxBatchSize, "Cannot mint more than max mint per transaction");
        require(mintingOpen == true, "Minting is not open right now!");

        require(_currentIndex + _amount <= totalSupply, "Cannot mint over supply cap");
        require(msg.value >= _calcPrice(_amount), "Value below required mint fee for amount");
        require(balanceOf(msg.sender) < maxBatchSize, "Can't mint more than limited number of tokens");

        uint256 updatedIndex = _getNextTokenId();

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, updatedIndex);
            _setTokenURI(updatedIndex, string.concat(metadataURI, "/", Strings.toString(updatedIndex), ".json"));
            updatedIndex++;
        }

        _updateCurrentIndex(_amount);
    }

    // View config

    function totalMinted() public view returns (uint256) {
    unchecked {return _currentIndex - reservedTokens;}}

    function totalReservedMinted() public view onlyOwner returns (uint256) {
    unchecked {return _currentPrivateIndex;}}

    // opensea operator filtering

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function getVersion() public pure returns (string memory) {
        return "V4";
    }

    // Private
    function _calcPrice(uint256 _count) internal view returns (uint256) {
        return nftPrice * _count;
    }

    function _getNextTokenId() internal view returns (uint256) {
        return SafeMath.add(_currentIndex, 1);
    }

    function _getNextPrivateTokenId() internal view onlyOwner returns (uint256) {
        return SafeMath.add(_currentPrivateIndex, 1);
    }

    function _updatePrivateCurrentIndex(uint256 step) internal onlyOwner {
        _currentPrivateIndex = _currentPrivateIndex + step;
    }

    function _updateCurrentIndex(uint256 step) internal {
        _currentIndex = _currentIndex + step;
    }

    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
    }
}