// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../UnloxToken.sol";
import "../CurrencyConverter/CurrencyConverterInterface.sol";
import "../CurrencyConverter/RealTimeCurrencyConverter.sol";
import "../CurrencyConverter/DummyCurrencyConverter.sol";

abstract contract NFTM is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    uint256 internal _marketFeeCENT;
    address private _feeCollector;

    UnloxToken internal _marketCoin;
    CurrencyConverterInterface internal _currencyConverter;

    address[] internal _nftCollections;
    mapping(address => uint256[]) internal _nftIDs;
    mapping(address => mapping(uint256 => SaleItem)) internal _nftSaleItems;
    mapping(address => SaleItem[]) internal _sellerSaleItems;

    mapping(address => uint256) internal _credits;

    struct SaleItem {
        address tokenAddr;
        address payable seller;
        address payable creator;
        uint256 tokenId;
        uint256 creatorFee; // In percentage (e.g., 250 = 2.5%)
        uint256 price; // WEI
    }

    event SaleStatusChange(address tokenAddr, uint256 tokenId, uint256 price);

    constructor(address feeCollector, uint256 marketFeeCENT) {
        _feeCollector = feeCollector;
        _marketFeeCENT = marketFeeCENT;
        _currencyConverter = new RealTimeCurrencyConverter();
        //_currencyConverter = new DummyCurrencyConverter();
    }

    // ************************************************
    // Core trading functions
    // ************************************************

    function buyNFT(address tokenAddr, uint256 tokenId)
        public
        payable
        nonReentrant
        onlySellingToken(tokenAddr,tokenId) onlyValidToken(tokenAddr, tokenId)
    {
        SaleItem memory item = _nftSaleItems[tokenAddr][tokenId];
        uint256 marketFee = _centToWEI(_marketFeeCENT);
        _executeSaleItem(
            tokenAddr,
            tokenId,
            item.price,
            item.seller,
            item.creator,
            item.creatorFee,
            marketFee
        );
    }

    function createSaleItem(
        address tokenAddr,
        uint256 tokenId,
        uint256 price,
        address payable creator,
        uint256 creatorFee
    ) public nonReentrant {
        _createSaleItemWithCreatorFee(
            tokenAddr,
            tokenId,
            msg.sender,
            price,
            creator,
            creatorFee
        );
    }

    function cancelSaleItem(address tokenAddr, uint256 tokenId)
        public
        nonReentrant
    {
        _removeItemFromMarket(tokenAddr, tokenId);
        emit SaleStatusChange(tokenAddr, tokenId, 0);
    }

    // ************************************************
    // Admin functions
    // ************************************************

    function setFeeCollector(address feeCollector) external onlyOwner notNullAddress(feeCollector) {
        _feeCollector = feeCollector;
    }

    function setMarketFeeCENT(uint256 marketFeeCENT) external onlyOwner {
        _marketFeeCENT = marketFeeCENT;
    }

    function setMarketToken(UnloxToken marketToken) external onlyOwner {
        require(address(marketToken) != address(0), 'NFTM: Market token can not be NULL');
        _marketCoin = marketToken;
    }

    function transferMarketTokenOwnership(address newOwner) external onlyOwner notNullAddress(newOwner) {
        _marketCoin.transferOwnership(newOwner);
    }

    function setCurrencyConverter(CurrencyConverterInterface currencyConverter)
        external
        onlyOwner
    {
        _currencyConverter = currencyConverter;
    }

    // ************************************************
    // Getter functions
    // ************************************************

    function getFeeCollector() external view returns (address) {
        return _feeCollector;
    }

    function getMarketFeeCENT() public view returns (uint256) {
        return _marketFeeCENT;
    }

    function getMarketToken() public view returns (UnloxToken) {
        return _marketCoin;
    }

    // ************************************************
    // Fee Collection functions
    // ************************************************

    function withdrawCredits() external nonReentrant {
        uint256 amount = _credits[msg.sender];

        require(amount != 0, "The caller does not have any credit");
        require(address(this).balance >= amount, "No money in the contract");

        _credits[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // ************************************************
    // Private functions
    // ************************************************

    function _createSaleItemWithCreatorFee(
        address tokenAddr,
        uint256 tokenId,
        address seller,
        uint256 price,
        address payable creator,
        uint256 creatorFee
    ) internal notNullAddress(tokenAddr) onlyValidToken(tokenAddr, tokenId){

        require(price != 0, "NFTM: Provided invalid price value");   
        require(creatorFee >= 0 && creatorFee <= 5000, "NFTM: Provided exceeded creator fee value");  

        if (_isTokenAddrExistInMarket(tokenAddr) == false) {
            _nftCollections.push(tokenAddr);
        }

        if (_isTokenIDExistInMarket(tokenAddr, tokenId) == false) {
            _nftIDs[tokenAddr].push(tokenId);
        }

        _nftSaleItems[tokenAddr][tokenId] = SaleItem({
            tokenAddr: tokenAddr,
            seller: payable(seller),
            tokenId: tokenId,
            price: price,
            creator: creator,
            creatorFee: creatorFee
        });

        _sellerSaleItems[msg.sender].push(_nftSaleItems[tokenAddr][tokenId]);

        emit SaleStatusChange(tokenAddr, tokenId, price);
    }

    function _removeItemFromMarket(address tokenAddr, uint256 tokenId)
        internal
    {
        SaleItem memory item = _nftSaleItems[tokenAddr][tokenId];

        delete _nftSaleItems[tokenAddr][tokenId];

        SaleItem[] storage sellerItems = _sellerSaleItems[item.seller];
        for (uint256 i = 0; i < sellerItems.length; i++) {
            if (sellerItems[i].tokenId == tokenId) {
                for (uint256 j = i; j < sellerItems.length - 1; j++) {
                    sellerItems[j] = sellerItems[j + 1];
                }
                sellerItems.pop();

                break;
            }
        }

        uint256[] storage ids = _nftIDs[tokenAddr];
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == tokenId) {
                for (uint256 j = i; j < ids.length - 1; j++) {
                    ids[j] = ids[j + 1];
                }
                ids.pop();

                break;
            }
        }

        if (ids.length == 0) {
            for (uint256 i = 0; i < _nftCollections.length; i++) {
                if (_nftCollections[i] == tokenAddr) {
                    for (uint256 j = i; j < _nftCollections.length - 1; j++) {
                        _nftCollections[j] = _nftCollections[j + 1];
                    }
                    _nftCollections.pop();

                    break;
                }
            }
        }
    }

    function _executeSaleItem(
        address tokenAddr,
        uint256 tokenId,
        uint256 tokenPrice,
        address payable seller,
        address payable creator,
        uint256 creatorFee,
        uint256 marketFee
    ) internal {
        _transferRevenue(tokenPrice, seller, creator, creatorFee, marketFee);

        IERC721 nftContract = IERC721(tokenAddr);
        nftContract.safeTransferFrom(seller, msg.sender, tokenId);

        _removeItemFromMarket(tokenAddr, tokenId);
    }

    function _transferRevenue(
        uint256 tokenPrice,
        address payable seller,
        address payable creator,
        uint256 creatorFee,
        uint256 marketFee
    ) private {

        address payable feeCollector = payable(_feeCollector);

        require(tokenPrice > 0, "Market: tokenPrice > 0");
        require(msg.value >= tokenPrice, "Market: msg.value is lower");
        require(seller != address(0), "Market: Seller address is 0x00");
        require(feeCollector != address(0), "Market: market address is 0x00");

        if (creator == address(0)) {
            creator = feeCollector;
        }

        uint256 creatorAmount = msg.value.mul(creatorFee).div(10000);
        uint256 marketAmount = marketFee;
        uint256 sellerAmount = msg.value.sub(creatorAmount).sub(marketAmount);

        assert(creatorAmount.add(marketAmount).add(sellerAmount) == msg.value);

        if (creator == seller) {
            sellerAmount = sellerAmount.add(creatorAmount);
            creatorAmount = 0;
        }

        if (creatorFee != 0) {
            if (!creator.send(creatorAmount)) {
                _credits[creator] += creatorAmount;
            }
        }

        if (marketFee != 0) {
            if (!feeCollector.send(marketAmount)) {
                _credits[feeCollector] += marketAmount;
            }
        }

        if (!seller.send(sellerAmount)) {
            _credits[seller] += sellerAmount;
        }
    }

    function _saleItemArrayToJSON(SaleItem[] memory saleItems)
        internal
        pure
        returns (string memory)
    {
        string memory returnText = "";

        returnText = string.concat(returnText, "[");

        for (uint256 i = 0; i < saleItems.length; i++) {
            SaleItem memory item = saleItems[i];
            returnText = string.concat(returnText, _saleItemToJSON(item));

            if (i != saleItems.length - 1) {
                returnText = string.concat(returnText, ",");
            }
        }

        returnText = string.concat(returnText, "]");

        return returnText;
    }

    function _saleItemToJSON(SaleItem memory saleItem)
        internal
        pure
        returns (string memory)
    {
        string memory returnText = "";

        returnText = string.concat(returnText, '{"tokenAddr":"0x');
        returnText = string.concat(
            returnText,
            _toAsciiString(saleItem.tokenAddr)
        );
        returnText = string.concat(returnText, '","sellerAddr":"0x');
        returnText = string.concat(returnText, _toAsciiString(saleItem.seller));
        returnText = string.concat(returnText, '","tokenId":"');
        returnText = string.concat(
            returnText,
            Strings.toString(saleItem.tokenId)
        );
        returnText = string.concat(returnText, '","price":"');
        returnText = string.concat(
            returnText,
            Strings.toString(saleItem.price)
        );
        returnText = string.concat(returnText, '"}');

        return returnText;
    }

    function _toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return string(s);
    }

    function _char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function _centToWEI(uint256 centValue) internal view returns (uint256) {
        return _currencyConverter.centToWEI(centValue);
    }

    function _isTokenAddrExistInMarket(address tokenAddr) internal view returns (bool){
        bool isCollectionExist = false;

        for (uint256 i = 0; i < _nftCollections.length; i++) {
            if (_nftCollections[i] == tokenAddr) {
                isCollectionExist = true;
                break;
            }
        }

        return isCollectionExist;
    }

    function _isTokenIDExistInMarket(address tokenAddr, uint256 tokenId) internal view returns (bool){
        bool isIDExist = false;

        uint256[] memory tmpIDs = _nftIDs[tokenAddr];

        for (uint256 i = 0; i < tmpIDs.length; i++) {
            if (tmpIDs[i] == tokenId) {
                isIDExist = true;
                break;
            }
        }

        return isIDExist;
    }

    //TODO erc1155
    function _isValidToken(address tokenAddr, uint256 tokenId) internal view returns (bool){
        IERC721 nftContract = IERC721(tokenAddr);
        address tokenOwner = nftContract.ownerOf(tokenId);
        return nftContract.isApprovedForAll(tokenOwner, address(this));
    }

    modifier onlyValidToken(address tokenAddr, uint256 tokenId) {
        require (_isValidToken(tokenAddr, tokenId),"NFTM: Market is not token owner nor approved");
        _;
    }

    modifier onlySellingToken(address tokenAddr, uint256 tokenId) {

        require(_isTokenAddrExistInMarket(tokenAddr),"NFTM: Provided token address & ID is not listed on the market");
        require(_isTokenIDExistInMarket(tokenAddr, tokenId),"NFTM: Provided token address & ID is not listed on the market");
        _;
    }

    modifier notNullAddress(address addr) {
        require(addr != address(0), "NFTM: Provided invalid token address");
        _;
    }
}