// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract YakuzaCatsSociety is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public constant KAMI = 0x001094B68DBAD2dce5E72d3F13A4ACE2184AE4B7;
    uint256 public constant PUBLIC_SALE_ENDING_PRICE = 0.0893 ether;
    uint256 public constant MAX_YAKUZA = 8930;

    EnumerableSet.AddressSet private _allowList;
    mapping(address => uint256) private _preSaleCounts;
    string private _metadata;
    bool private _startPreSale = false;
    bool private _startSale = false;

    uint256 private _maxSizeAtOneTime = 5;
    uint256 private _publicSaleStartPrice = 0.893 ether;
    uint256 private _downPriceDuration = 14400;
    uint256 private _publicSaleStartTime;

    constructor() ERC721("Yakuza Cats Society", "YCS") {
    }

    function forAirdrop() public onlyOwner{
        for (uint256 i; i < 30; i++) {
            _safeMint(KAMI, i);
        }
    }

    function migrateForOwners(uint256 startIndex, uint256 endIndex)
        public
        onlyOwner
        nonReentrant
    {
        for (uint256 i = startIndex; i < endIndex; i++) {
            address owner = ERC721Enumerable(0xA17a51C35Ac33D991C1132764E3bAD80Dffb640b).ownerOf(i);
            _safeMint(owner, i);
        }
    }

    function allowList() public view returns (address[] memory) {
        return _allowList.values();
    }

    function addAllowList(address[] memory lists, uint256 limit)
        public
        onlyOwner
    {
        for (uint256 i; i < lists.length; i++) {
            if (!_allowList.contains(lists[i])) {
                _allowList.add(lists[i]);
                _preSaleCounts[lists[i]] = limit;
            }
        }
    }

    function getPreSaleCount(address owner) public view returns (uint256) {
        return _preSaleCounts[owner];
    }

    function setStartPreSale(bool startPreSale_) public onlyOwner {
        _startPreSale = startPreSale_;
    }

    function isStartPreSale() public view returns (bool) {
        return _startPreSale;
    }

    function preSale(uint256 count) public payable nonReentrant {
        uint256 minted = totalSupply();
        require(isStartPreSale(), "pre sale is currently closed");
        require(count <= 2, "can mint up to 2");
        require(_allowList.contains(msg.sender), "you are not on the whitelist");
        require(_preSaleCounts[msg.sender] - count >= 0, "exceeded allowed amount");
        require(msg.value >= preSalePrice() * count, "insufficient ether");
        require(minted + count < MAX_YAKUZA, "total supply is 8930");

        _preSaleCounts[msg.sender] -= count;
        for (uint256 i; i < count; i++) {
            _safeMint(msg.sender, minted + i);
        }

        _distribute();
    }

    function preSalePrice() public pure returns (uint256) {
        return 0.0893 ether;
    }

    function sale(uint256 count) public payable nonReentrant {
        uint256 minted = totalSupply();
        require(isStartSale(), "sale is currently closed");
        require(count <= maxSizeAtOneTime(), "can mint up to maxSizeAtOneTime");
        require(msg.value >= getSalePrice() * count, "insufficient ether");
        require(minted + count < MAX_YAKUZA, "total supply is 8930");

        for (uint256 i; i < count; i++) {
            _safeMint(msg.sender, minted + i);
        }

        require(payable(msg.sender).send(msg.value - getSalePrice() * count));
        _distribute();
    }

    function setStartSale(bool startSale_) public onlyOwner {
        _startSale = startSale_;
        if( startSale_ && _publicSaleStartTime == 0 ){
            _publicSaleStartTime = block.timestamp;
        }
    }

    function isStartSale() public view returns (bool) {
        return _startSale;
    }

    function getSalePrice() public view returns (uint256) {
        if (_startSale && _publicSaleStartTime > 0) {
            if (block.timestamp - _publicSaleStartTime >= _downPriceDuration) {
                return PUBLIC_SALE_ENDING_PRICE;
            } else {
                uint256 price = _publicSaleStartPrice -
                    ((_publicSaleStartPrice - PUBLIC_SALE_ENDING_PRICE) *
                        (block.timestamp - _publicSaleStartTime)) /
                    _downPriceDuration;
                return
                    price <= PUBLIC_SALE_ENDING_PRICE
                        ? PUBLIC_SALE_ENDING_PRICE
                        : price;
            }
        }
        return PUBLIC_SALE_ENDING_PRICE;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(_metadata).length > 0
                ? string(abi.encodePacked(_metadata, tokenId.toString()))
                : "ipfs://QmdfVPU3VuPDywcAmUuhwghSS3BrvuL8tqKtc1rTS1c3kg";
    }

    function updateMetadata(string memory metadata) public onlyOwner {
        _metadata = metadata;
    }

    function setMaxSizeAtOneTime(uint256 newMaxSize) public onlyOwner {
        require(0 < newMaxSize && newMaxSize < 6, "");
        _maxSizeAtOneTime = newMaxSize;
    }

    function maxSizeAtOneTime() public view returns (uint256) {
        return _maxSizeAtOneTime;
    }

    function _distribute() internal {
        payable(address(KAMI)).transfer(address(this).balance);
    }

}