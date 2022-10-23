/*       ___      _     ___                    _     _          ___ _       _         
        / _ \___ | |_  / __\ __ ___ _ __   ___| |__ (_) ___    / __\ |_   _| |__        
       / /_\/ _ \| __|/ _\| '__/ _ \ '_ \ / __| '_ \| |/ _ \  / /  | | | | | '_ \       
      / /_\\ (_) | |_/ /  | | |  __/ | | | (__| | | | |  __/ / /___| | |_| | |_) |      
      \____/\___/ \__\/   |_|  \___|_| |_|\___|_| |_|_|\___| \____/|_|\__,_|_.__/       
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GotFrenchieClub is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint;
    using Counters for Counters.Counter;

    //URLS
    string private _baseURL;
    string public PRE_REVEAL_URL;

    //ADDRESSES
    address constant WITHDRAW_ADDRESS = 0x2e07B7c6E37b0bCf6BAd69ff807fAce6F265A9D6;
    address private _adminSigner = 0xD320B0c113511A3BbF190D69949CaDed4887f952;

    //COLLECTION SIZES
    uint public COLLECTION_SIZE = 10000;
    uint public COLLECTION_SIZE_WL = 2500;
    uint public COLLECTION_SIZE_CREATOR = 200;

    //LIMITS
    uint public TOKENS_PER_PERSON_WL_LIMIT = 2;
    uint public TOKENS_PER_PERSON_PUB_LIMIT = 10;

    //PRICES
    uint public PRESALE_MINT_PRICE = 0.05 ether;
    uint public MINT_PRICE = 0.08 ether;

    //MINT COUNTERS
    mapping(address => uint) private _mintedCount;
    mapping(address => uint) private _whitelistMintedCount;
    mapping(address => uint) private _creatorMintedCount;

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    enum CouponType {
        Genesis,
        Author,
        Presale
    }

    enum SaleStatus {
        PAUSED,
        PRESALE,
        PUBLIC
    }

    Counters.Counter private _tokenIds;
    SaleStatus public saleStatus = SaleStatus.PRESALE;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory url
    ) ERC721(_name, _symbol) {
        PRE_REVEAL_URL = url;
    }

    /* REQUIRED METHODS */
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    function tokenURI(uint tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, "/", tokenId.toString(), ".json")
                )
                : PRE_REVEAL_URL;
    }

    /* REVEAL METHODS */
    function unreveal() external onlyOwner {
        _baseURL = "";
    }

    function reveal(string memory uri) external onlyOwner {
        _baseURL = uri;
    }

    function setPreRevealUrl(string memory url) external onlyOwner {
        PRE_REVEAL_URL = url;
    }
    
    /* OWNER METHODS */
    function withdraw() external onlyOwner nonReentrant {
        uint balance = address(this).balance;

        require(balance > 0, "NO_BALANCE");

        (bool os, ) = payable(WITHDRAW_ADDRESS).call{
            value: address(this).balance
        }("");
        
        require(os, "WITHDRAW_FAILED");
    }

    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }

    /* PRICE METHODS*/
    function setPublicMintPrice(uint price) external onlyOwner {
        MINT_PRICE = price;
    }

    function setPresaleMintPrice(uint price) external onlyOwner {
        PRESALE_MINT_PRICE = price;
    }

    /* COLLECTION SIZES METHODS*/
    function setCollectionSizeWL(uint size) external onlyOwner {
        COLLECTION_SIZE_WL = size;
    }

    function setCollectionSizeCreator(uint size) external onlyOwner {
        COLLECTION_SIZE_CREATOR = size;
    }

    function getCreatorMintCount() external view onlyOwner returns (uint) {
        return _creatorMintedCount[owner()];
    }

    /* MINTING LIMITS */
    function setPerPersonLimitWL(uint size) external onlyOwner {
        TOKENS_PER_PERSON_WL_LIMIT = size;
    }

    function setPerPersonLimitPublic(uint size) external onlyOwner {
        TOKENS_PER_PERSON_PUB_LIMIT = size;
    }

    /* MINTING METHODS */
    function _mintTokens(address to, uint count) internal {
        for (uint index = 0; index < count; index++) {
            _tokenIds.increment();
            uint newItemId = _tokenIds.current();

            _safeMint(to, newItemId);
        }
    }

    function calcTotal(uint count) public view returns (uint) {
        require(saleStatus != SaleStatus.PAUSED, "SALES_OFF");

        uint price = saleStatus == SaleStatus.PRESALE
            ? PRESALE_MINT_PRICE
            : MINT_PRICE;

        return count * price;
    }

    function airdrop(address to, uint count) external onlyOwner {
        require(
            _tokenIds.current() + count <= COLLECTION_SIZE,
            "COLLECTION_LIMIT"
        );

        require(
            _creatorMintedCount[owner()] + count <= COLLECTION_SIZE_CREATOR,
            "COLLECTION_LIMIT_CREATOR"
        );

        _creatorMintedCount[owner()] += count;
        _mintTokens(to, count);
    }

    function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon)
        internal
        view
        returns (bool)
    {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer == _adminSigner;
    }

    function whitelistMint(address to, uint count, Coupon memory coupon) external payable {    
        require(saleStatus != SaleStatus.PAUSED, "SALES_OFF");
        require(saleStatus == SaleStatus.PRESALE, "PRESALE_SALES_OFF");

        require(count > 0, "MIN_QTY_1");
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "COLLECTION_LIMIT");
        require(msg.value >= calcTotal(count), "ETH_NOT_ENUF");

        if (saleStatus == SaleStatus.PRESALE) {
            //check coupon
            bytes32 digest = keccak256(abi.encode(CouponType.Presale, to));
            require(_isVerifiedCoupon(digest, coupon), "INVALID_COUPON");

            //check limits - per wallet
            require(_whitelistMintedCount[to] + count <= TOKENS_PER_PERSON_WL_LIMIT, "PRESALE_ALLOWANCE_LIMIT");

            //check limits - WL sale allowance
            require(_tokenIds.current() + count <= COLLECTION_SIZE_WL, "COLLECTION_LIMIT_WL");

            _whitelistMintedCount[to] += count;
        }

        _mintTokens(to, count);
    }

    function mint(address to, uint count) external payable {    
        require(saleStatus != SaleStatus.PAUSED, "SALES_OFF");
        require(saleStatus == SaleStatus.PUBLIC, "PUBLIC_SALES_OFF");

        require(count > 0, "MIN_QTY_1");
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "COLLECTION_LIMIT");

        //check limits - public sale allowance
        uint creatorMintedCount = _creatorMintedCount[owner()];
        require((_tokenIds.current() + count - creatorMintedCount) <= (COLLECTION_SIZE - COLLECTION_SIZE_CREATOR), "COLLECTION_LIMIT_PUBLIC");
        
        require(msg.value >= calcTotal(count), "ETH_NOT_ENUF");

        if (saleStatus == SaleStatus.PUBLIC) {
             //check limits - per wallet
            require(_mintedCount[to] + count <= TOKENS_PER_PERSON_PUB_LIMIT, "PUBLIC_ALLOWANCE_LIMIT");

            _mintedCount[to] += count;
        }

        _mintTokens(to, count);
    }
}