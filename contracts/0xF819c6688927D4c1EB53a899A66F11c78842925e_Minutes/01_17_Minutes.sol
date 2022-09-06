// SPDX-License-Identifier: MIT
// Creator: https://degen.beauty

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AllowlistSale.sol";

contract Minutes is ERC721, Pausable, Ownable, ERC721Burnable, AllowlistSale, ReentrancyGuard {
    using Counters for Counters.Counter;

    string public baseURI;
    string private _contractURI;
    uint256 public DATE_ZERO; // the minutes are calculated from this time

    Counters.Counter private _tokenIdCounter;

    constructor(
        string memory initBaseURI,
        string memory initContractURI,
        uint256 dateZero,
        address payable _beneficiary
    ) ERC721("Minutes Collective", "60M") {
        baseURI = initBaseURI;
        _contractURI = initContractURI;
        beneficiary = _beneficiary;
        DATE_ZERO = dateZero;

        // setup allowlist mint
        _addSale(1, SaleConfig(1661875200, 0, 0, 2, 1, 0x6DeB3251ba099E8E4cf705a0e156D41A1d7618f6, false, true, true));

        // setup public mint
        _addSale(0, SaleConfig(1661878800, 0, 3200000000000000, 0, 1, address(0), true, false, true));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    @notice the provided key must match with the minting address,
    *       you can get your key from https://minutes.degen.beauty
    *       mint is free, but each key could be used only twice,
    *       the minted timestammp will be the block time of the transaction
    */
    function allowlistMint(bytes calldata key) external nonReentrant {
        verify(1, key, 1);
        uint256 tokenId = _tokenIdCounter.current();
        _mintMinuteToken(tokenId);
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    /**
    @notice this is not a free mint, price is 0.0032 ETH
    *       equivalent of a BigMac, we added this barrier to limit bots
    *       this project is meant to be a fun on-chain experience
    */
    function publicMint() external payable nonReentrant {
        verifyPublicSale(1, 0);
        uint256 tokenId = _tokenIdCounter.current();
        _mintMinuteToken(tokenId);
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    // minute token

    struct MinuteToken {
        uint256 timestamp;
        uint256 minute;
        uint256 number;
    }

    mapping(uint256 => MinuteToken) public minuteTokens;

    mapping(uint256 => uint256[]) public minuteMap;
    uint256 minuteMapSize = 0;

    function _mintMinuteToken(uint256 tokenId) internal {
        require(minuteMapSize < 60, "mint has been ended");
        uint256 time = block.timestamp - DATE_ZERO;
        uint256 minuteValue = (time / 60) % 60;
        uint256 tokenNumber = minuteMap[minuteValue].length;
        minuteTokens[tokenId] = MinuteToken(time, minuteValue, tokenNumber);
        minuteMap[minuteValue].push(tokenId);
        if (tokenNumber == 0) {
            minuteMapSize += 1;
        }
    }

    /**
    @notice returns the stored data for a tokenId
    *       creation timestamp,
    *       minute (wen minted, also referred to as minute category),
    *       tokenNumber (position in minute category, 0 means it was the first in that minute),
    */
    function getTokenData(uint256 tokenId) public view returns(MinuteToken memory){
        require(minuteTokens[tokenId].timestamp != 0, "this tokenId does not exists");
        require(ownerOf(tokenId) != address(0), "this token has been burned");
        return minuteTokens[tokenId];
    }

    /**
    @notice returns a list of tokenIds for a minute category
    */
    function getTokensForMinute(uint256 minute) public view returns(uint256[] memory){
        return minuteMap[minute];
    }

    /**
    @notice returns true if no nft has been minted in the given category
    */
    function isMinuteCategoryEmpty(uint256 minute) public view returns(bool) {
        return minuteMap[minute].length == 0;
    }

    /** 
    @notice returns how many categories are still empty,
    *       it returns 0 when the mint is over (all the possible minutes are present in the collection)
    */
    function remainingMinuteCategories() public view returns(uint256) {
        return 60-minuteMapSize;
    }

    // metadata

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setContractURI(string calldata uri) external onlyOwner {
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setDateZero(uint256 dateZero) external onlyOwner {
        DATE_ZERO = dateZero;
    }

    // transfer revenues

    /**
    @notice Recipient of revenues.
    */
    address payable public beneficiary;

    /**
    @notice Sets the recipient of revenues
    */
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    /**
    @notice Send revenues to beneficiary
    */
    function transferRevenues() external onlyOwner {
        require(beneficiary != address(0), "No beneficiary address defined");
        (bool success, ) = beneficiary.call{value: address(this).balance}("Sending revenues from cowlony");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}