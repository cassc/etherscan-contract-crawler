//SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface iNishikigoi {

    function remainingAmountForPromotion() external view returns (uint256);

    function remainingAmountForSale() external view returns (uint256);

    function isOnSale() external view returns (bool);

    function mintedSalesTokenIdList(
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory);

    function buy(uint256 tokenId) external payable;

    function buyBundle(uint256[] memory tokenIdList) external payable;

    // functions for admin

    function updateSaleStatus(bool _isOnSale) external;

    function updateBaseURI(string calldata newBaseURI) external;

    function freezeMetadata() external;

    function mintForPromotion(
        address to,
        uint256 amount
    ) external;

    function withdrawETH() external;
}

contract Nishikigoi is iNishikigoi, ERC721, ReentrancyGuard, Ownable {

    using Strings for uint256;

    uint256 public constant PRICE = 0.03 ether;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 private _nextReservedTokenId = 9800;
    uint256 private _remainingAmountForPromotion = 200;
    uint256 private _remainingAmountForSale = 9800;
    uint256[] private _mintedTokenIdList;
    address payable private _recipient;
    bool private _isOnSale;
    bool private _isMetadataFroze;
    string private __baseURI;

    constructor(
        string memory baseURI,
        address payable __recipient
    )
    ERC721("Nishikigoi", "KOI")
    {
        require(__recipient != address(0), "Nishikigoi: Invalid address");
        _recipient = __recipient;
        __baseURI = baseURI;
    }

    function remainingAmountForPromotion() external override view returns (uint256) {
        return _remainingAmountForPromotion;
    }

    function remainingAmountForSale() external override view returns (uint256) {
        return _remainingAmountForSale;
    }

    function isOnSale() external view override returns (bool) {
        return _isOnSale;
    }

    function mintedSalesTokenIdList(
        uint256 offset,
        uint256 limit
    ) external override view returns (uint256[] memory) {

        uint256 minted = _mintedTokenIdList.length;

        if (minted == 0) {
            return _mintedTokenIdList;
        }
        if (minted < offset) {
            return new uint256[](0);
        }

        uint256 length = limit;
        if (minted < offset + limit) {
            length = minted - offset;
        }
        uint256[] memory list = new uint256[](length);
        for (uint256 i = offset; i < offset + limit; i++) {
            if (_mintedTokenIdList.length <= i) {
                break;
            }
            list[i - offset] = _mintedTokenIdList[i];
        }

        return list;
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return __baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nishikigoi: URI query for nonexistent token");

        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function buy(uint256 tokenId) external override nonReentrant payable {
        require(_isOnSale, "Nishikigoi: Not on sale");
        require(msg.value == PRICE, "Nishikigoi: Invalid value");
        require(tokenId < _nextReservedTokenId, "Nishikigoi: Invalid id");

        _mintedTokenIdList.push(tokenId);
        _remainingAmountForSale--;
        _safeMint(_msgSender(), tokenId);
    }

    function buyBundle(uint256[] memory tokenIdList) external override nonReentrant payable {
        uint256 count = tokenIdList.length;
        require(_isOnSale, "Nishikigoi: Not on sale");
        require(msg.value == PRICE * count, "Nishikigoi: Invalid value");
        _remainingAmountForSale -= count;

        for (uint256 i; i < count; i++) {
            require(tokenIdList[i] < _nextReservedTokenId, "Nishikigoi: Invalid id");

            _mintedTokenIdList.push(tokenIdList[i]);
            _safeMint(_msgSender(), tokenIdList[i]);
        }
    }

    function updateSaleStatus(bool __isOnSale) external override onlyOwner {
        _isOnSale = __isOnSale;
    }

    function updateBaseURI(string calldata newBaseURI) external override onlyOwner {
        require(!_isMetadataFroze, "Nishikigoi: Metadata is froze");
        __baseURI = newBaseURI;
    }

    function freezeMetadata() external override onlyOwner {
        require(!_isMetadataFroze, "Nishikigoi: Already froze");
        _isMetadataFroze = true;
    }

    function mintForPromotion(
        address to,
        uint256 amount
    ) external override onlyOwner {
        _remainingAmountForPromotion -= amount;

        for (uint256 i = _nextReservedTokenId; i < _nextReservedTokenId + amount; i++) {
            _safeMint(to, i);
        }

        _nextReservedTokenId += amount;
    }

    function withdrawETH() external override onlyOwner {
        Address.sendValue(_recipient, address(this).balance);
    }

}