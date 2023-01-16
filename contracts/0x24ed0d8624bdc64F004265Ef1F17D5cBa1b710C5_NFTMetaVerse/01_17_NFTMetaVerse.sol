// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMetaVerse is
    Initializable,
    ReentrancyGuardUpgradeable,
    ERC721Upgradeable,
    ERC721HolderUpgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public mintFee;
    uint256 public royality;

    mapping(uint256 => MarketItem) private idToMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address contractAddress;
        address payable owner;
        uint256 price;
        bool isSale;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price
    );

    function initialize() 
      public 
      initializer 
    {
        mintFee = 0.001 ether;
        royality = 5; // 5 percentage
        __ReentrancyGuard_init();
        __ERC721_init("NFT Metaverse", "NFT");
        __ERC721URIStorage_init();
        __Ownable_init();
    }

    modifier isOwner(uint256 tokenId) {
        address _owner = ownerOf(tokenId);
        require(
            (_owner == address(this) &&
                idToMarketItem[tokenId].owner == _msgSender()) ||
                _owner == _msgSender(),
             "tokenId: caller is not the owner"
        );
        _;
    }

    function _burn(
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        isOwner(tokenId)
    {
       super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setMintPrice(uint _fee) 
      public 
      onlyOwner 
    {
        mintFee = _fee;
    }

    function createItem(
        string memory _tokenURI
    ) 
      public 
      payable 
      nonReentrant 
      returns (uint) 
    {
        require(msg.value == mintFee, "insufficient fund");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(_msgSender(), newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        createMarketItem(newTokenId);
        return newTokenId;
    }

    function createMarketItem(uint256 tokenId) 
      private 
    {
     
        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            address(this),
            payable(_msgSender()),
            0,
            false
        );
    }

    function putOnSale(uint256 tokenId, uint256 price) 
      public 
      virtual 
    {

        require(
            ownerOf(tokenId) == _msgSender(),
            "tokenId: caller is not the owner"
        );
      
        require(idToMarketItem[tokenId].isSale == false, "tokenId exist on sale");
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].isSale = true;
    }

    function cancelOnSale(uint256 tokenId) public virtual isOwner(tokenId) {

        require(idToMarketItem[tokenId].isSale == true, "tokenId nonexist on sale");
        idToMarketItem[tokenId].isSale = false;

    }

    function buyNft(uint256 tokenId) 
      public 
      virtual 
      payable 
      nonReentrant 
    {

      require(idToMarketItem[tokenId].price == msg.value, "insufficient fund");
      require(ownerOf(tokenId) != _msgSender(), "tokenId: owner not buyable");

      idToMarketItem[tokenId].owner   = payable(_msgSender());
      idToMarketItem[tokenId].isSale  = false;
      _safeTransfer(ownerOf(tokenId), _msgSender(), tokenId, "0x00");
      
      uint256 _price = idToMarketItem[tokenId].price;
      uint256 _royality = (_price * royality) / 100;
      uint256 priceAfterRoyality =  _price - _royality;
      (bool success, ) = idToMarketItem[tokenId].owner.call{value: priceAfterRoyality }("");
      require(success, "Txn failed");
    }

    function listItems(uint offset, uint limit)
      public 
      view 
      returns (MarketItem[] memory) 
    {
        uint256 endIndex = getTotalItems();
        uint256 countItems = limit;
        if(countItems > endIndex){
          countItems = endIndex;
        }
        endIndex =  endIndex - (offset * limit);
        uint256 startIndex = endIndex > countItems ? endIndex - countItems : 0;

        uint256 i = 0;
        MarketItem[] memory items = new MarketItem[](countItems);
        for (uint256 currentId = endIndex; currentId > startIndex; currentId--) {
            if(idToMarketItem[currentId].isSale == true){
               MarketItem memory item = idToMarketItem[currentId];
              address _owner = ownerOf(item.tokenId);
              item.owner  = payable(_owner);
              items[i] = item;
              i++;
            }
        }
        return items;
    }

    function listItemById(
      uint256 _tokenId
    ) 
      public 
      view 
      returns (MarketItem memory) 
    {
        MarketItem memory item = idToMarketItem[_tokenId];
        address _owner = ownerOf(item.tokenId);
        item.owner     = payable(_owner);
        return item;
    }

    function listMyItems(uint offset, uint limit)
      public 
      view 
      returns (MarketItem[] memory) 
    {
        uint256 endIndex = getTotalItems();
        uint256 countItems = limit;
        if(countItems > endIndex){
          countItems = endIndex;
        }
        endIndex =  endIndex - (offset * limit);
        uint256 startIndex = endIndex > countItems ? endIndex - countItems : 0;
      
        uint256 i = 0;
        MarketItem[] memory items = new MarketItem[](countItems);
        for (uint256 currentId = endIndex; currentId > startIndex; currentId--) {
            if(ownerOf(currentId) == _msgSender()){
               MarketItem memory item = idToMarketItem[currentId];
              address _owner = ownerOf(item.tokenId);
              item.owner  = payable(_owner);
              items[i] = item;
              i++;
            }
        }
        return items;
    }

    function getTotalItems() 
      public 
      virtual 
      view 
      returns(uint256) 
    {

      return _tokenIds.current();
    }

    function withdraw() 
      public 
      virtual 
      onlyOwner 
    {
        require(address(this).balance > 0);
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "windraw: failed");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) 
      public 
      virtual 
      override 
    {

       idToMarketItem[tokenId].isSale  = false;
       super.safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) 
      public 
      virtual
      override
    {
        idToMarketItem[tokenId].isSale  = false;
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) 
      public 
      virtual 
      override 
    {
        idToMarketItem[tokenId].isSale  = false;
        super.transferFrom(from, to, tokenId);
    }
}