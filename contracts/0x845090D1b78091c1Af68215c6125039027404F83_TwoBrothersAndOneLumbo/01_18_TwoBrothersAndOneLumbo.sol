// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Base64 } from "./libraries/Base64.sol";


contract TwoBrothersAndOneLumbo is ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    IERC20 public USDT;

    uint public artistRoyalty;

    address public treasury;

    event Minted(
        uint256 tokenId,
        address beneficiary,
        string tokenUri,
        address minter
    );

    event RoyaltyUpdated(uint indexed updatedRoyalty);

    event MarketItemCreated (
      uint256 indexed tokenId,
      address seller,
      address owner,
      uint256 price,
      bool sold
    );

    event ItemSold(
        uint256 id, 
        address indexed buyer, 
        uint256 price
    );

    struct MarketItem {
      uint256 tokenId;  
      address  seller;
      address  owner;
      uint256 price;
      bool sold;
    }

    mapping(uint256 => MarketItem) public idToMarketItem;

    /// @notice Contract constructor
    constructor(
        address _treasuryAddress,
        address _usdt,
        uint _royalty
    ) ERC721("Two Brothers and One Lumbo", "TBAOL") {
        treasury = _treasuryAddress;
        USDT = IERC20(_usdt);
        artistRoyalty = _royalty;
        _tokenIds.increment();
    }


    function updateArtistRoyalty(uint _royalty)
        external 
        onlyOwner
    {
        require(_royalty != 0, "CreathMarketplace: 0 is not allowed");
        require(_royalty <= 100, "CreathMarketplace: royalty above 100 is not allowed");
        artistRoyalty = _royalty;
        emit RoyaltyUpdated(_royalty);
    }


    function mintTokens(
        string[] calldata _tokenUris,
        uint256[] memory _pricePerItem,
        address[] memory _owners) external onlyOwner{
        for (uint i = 0; i < _tokenUris.length; i = i + 1) {
            uint256 newTokenId = _tokenIds.current();
            _safeMint(msg.sender, newTokenId);
            _setTokenURI(newTokenId, _tokenUris[i]);
            createMarketItem(newTokenId, _pricePerItem[i], _owners[i]);
            _tokenIds.increment();

            emit Minted(newTokenId, address(this), _tokenUris[i], _msgSender());
        }
    }

    function createMarketItem(
        uint256 tokenId,
        uint256  _pricePerItem,
        address  _owner
    ) internal{
        idToMarketItem[tokenId] =  MarketItem(
        tokenId,
        address(this),
        _owner,
        _pricePerItem,
        false
      );
      _transfer(msg.sender, address(this), tokenId);
      emit MarketItemCreated(
        tokenId,
        msg.sender,
        _owner,
        _pricePerItem,
        false
      );
    }


    function buyItem(uint256 _tokenId )
        external
    {
        require(msg.sender != ownerOf(_tokenId), "Creath Marketplace: cannot buy your own asset.");

        uint _amount = idToMarketItem[_tokenId].price;
        uint artistPercentage = (_amount.mul(artistRoyalty)).div(100);
        uint remainder = _amount.sub(artistPercentage);
        USDT.safeTransferFrom(msg.sender, address(this), _amount);
        USDT.approve(address(treasury), remainder);
        USDT.approve(idToMarketItem[_tokenId].owner, artistPercentage);
        USDT.safeTransfer(idToMarketItem[_tokenId].owner, artistPercentage);
        USDT.safeTransfer(treasury, remainder);

        _transfer(
            address(this),
            msg.sender,
            _tokenId
        );

        idToMarketItem[_tokenId].sold = true;

        emit ItemSold(
            _tokenId,
           msg.sender,
           _amount
        );
    }

    function fetchMarketItems() external view returns (MarketItem[] memory) {
      uint count = _tokenIds.current();
      MarketItem[] memory items = new MarketItem[](count);
      for (uint i = 0; i < count; i = i + 1) {
        if (idToMarketItem[i + 1].seller == address(this)) {
          items[i + 1] = idToMarketItem[i + 1];
        }
      }
      return items;
    }

    function isSold(uint256 id) external view returns (bool){
      MarketItem memory item = idToMarketItem[id];

      return item.sold;
    }

    function updateToken(address _token) external onlyOwner {
      USDT = IERC20(_token);
    } 
}