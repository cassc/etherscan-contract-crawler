// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RankerBadge is ERC721, ERC721Enumerable, Ownable {
    IERC20 public tokenAddress;
    using Counters for Counters.Counter;
    mapping(uint256 => uint256) private _tokenIdToTokenType;

    Counters.Counter private _tokenIds;

    uint256 public constant BRONZE = 1;
    uint256 public constant SILVER = 2;
    uint256 public constant GOLD = 3;
    uint256 public constant GAMING = 4;

    struct Badge {
        uint256 tokenType;
        uint256 priceRate;
        uint256 maxSupply;
        Counters.Counter totalSupply;
        bool hasMaxSupply;
        uint256 temporarySupplyLimit;
        uint256 temporarySupplyLimitDateTimeDeadline;
        uint256 temporaryPrice;
        bool hasTemporaryCondition;
        bool allowedMint;
    }

    Badge[4] private badges;

    string public baseTokenURI;

    constructor(string memory name_, string memory symbol_, string memory baseURI, address _tokenAddress) ERC721(name_, symbol_) {
        setBaseURI(baseURI);
        tokenAddress = IERC20(_tokenAddress);

        badges[0] = Badge(BRONZE, 20_000, 0, Counters.Counter(0), false, 0, 0, 0, false, false);
        badges[1] = Badge(SILVER, 100_000, 0, Counters.Counter(0), false, 0, 0, 0, false, false);
        badges[2] = Badge(GOLD, 500_000, 25, Counters.Counter(0), false, 0, 0, 0, false, false);
        badges[3] = Badge(GAMING, 2000, 0, Counters.Counter(0), false, 0, 0, 0, false, true);
    }

    modifier tokenTypeMustExist(uint256 tokenType) {
        require(tokenType <= badges.length && tokenType > 0, "Token doesn't exists");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(_tokenIdToTokenType[tokenId]), ".json")) : "";
    }

    function safeMint(uint256 tokenType, uint256 amount) public tokenTypeMustExist(tokenType) {
        uint256 index = tokenType - 1;
        require(isAllowedToMint(tokenType), "NFT badge of the given type is currently not allowed to mint");

        uint256 totalMintedPerBadge = badges[index].totalSupply.current();

        uint256 priceRate = badges[index].priceRate;

        if (badges[index].hasTemporaryCondition && badges[index].temporarySupplyLimitDateTimeDeadline >= block.timestamp) {
            require(totalMintedPerBadge + amount <= badges[index].temporarySupplyLimit, "Not enough NFTs to mint, reached maximum supply");
            priceRate = badges[index].temporaryPrice;
        } else if (badges[index].hasMaxSupply) {
            require(totalMintedPerBadge + amount <= badges[index].maxSupply, "Not enough NFTs to mint, reached maximum supply");
        }

        tokenAddress.transferFrom(msg.sender, address(this), amount * priceRate);
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            _tokenIdToTokenType[tokenId] = tokenType;
            _tokenIds.increment();
            badges[index].totalSupply.increment();
        }
    }

    function withdraw() public onlyOwner {
        require(tokenAddress.balanceOf(address(this)) > 0, "Balance is 0");
        tokenAddress.transfer(msg.sender, tokenAddress.balanceOf(address(this)));
    }

    function totalSupplyPerBadge(uint256 tokenType) public view tokenTypeMustExist(tokenType) returns (uint256) {
        uint256 index = tokenType - 1;
        return badges[index].totalSupply.current();
    }

    function setPrice(uint256 tokenType, uint256 price) external onlyOwner tokenTypeMustExist(tokenType) {
        badges[tokenType - 1].priceRate = price;
    }

    function allowMint(uint256 tokenType, bool allow) external onlyOwner tokenTypeMustExist(tokenType) {
        badges[tokenType - 1].allowedMint = allow;
    }

    function isAllowedToMint(uint256 tokenType) public view tokenTypeMustExist(tokenType) returns (bool) {
        return badges[tokenType - 1].allowedMint;
    }

    function getBadgeInfo(uint256 tokenType) external view onlyOwner tokenTypeMustExist(tokenType) returns (Badge memory) {
        return badges[tokenType - 1];
    }

    function setTokenTemporaryCondition(
        uint256 tokenType,
        uint256 temporarySupplyLimit,
        uint256 unixTemporarySupplyLimitDateTimeDeadline,
        uint256 temporaryPrice
    ) external onlyOwner tokenTypeMustExist(tokenType) {
        uint256 index = tokenType - 1;
        badges[index].hasTemporaryCondition = true;
        badges[index].temporarySupplyLimit = temporarySupplyLimit;
        badges[index].temporarySupplyLimitDateTimeDeadline = unixTemporarySupplyLimitDateTimeDeadline;
        badges[index].temporaryPrice = temporaryPrice;
    }

    function clearTokenTemporaryCondition(uint256 tokenType) external onlyOwner tokenTypeMustExist(tokenType) {
        uint256 index = tokenType - 1;
        badges[index].hasTemporaryCondition = false;
        badges[index].temporarySupplyLimit = 0;
        badges[index].temporarySupplyLimitDateTimeDeadline = 0;
        badges[index].temporaryPrice = 0;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}