// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//access control
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./DefaultOperatorFilterer.sol";


contract AuctionHouse is ERC721, AccessControl, Ownable, DefaultOperatorFilterer {
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemIds;
    string private _contractURI;

    struct Art{
        string name;
        string description;
        string artist;
        string date;
        string category;
        string city;
        string gallery;
        string image;
    }

    mapping (uint => Art) _idToMeta;
    mapping(uint=>bool) _itemIdToMinted; 

    mapping(uint=>uint) _tokenIdToItemId;

    constructor()ERC721("Metropolis World - The Auction House", "MWAH") {
        _tokenIds.increment();
        _itemIds.increment();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPDATER_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)public view virtual override(ERC721, AccessControl) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function additem(Art memory art)external onlyRole(UPDATER_ROLE){
        _idToMeta[_itemIds.current()] = art;
        _itemIds.increment(); 
    }


    function mwMint(uint itemId, address to)external onlyRole(UPDATER_ROLE){
        require(_itemIdToMinted[itemId] != true, 'already minted');
        uint tid = _tokenIds.current();
        _safeMint(to, tid);
        _itemIdToMinted[itemId] = true;
        _tokenIdToItemId[tid] = itemId;
    }

    function getArtById(uint id)external view returns(Art memory){
        return _idToMeta[id];
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

    function tokenURI(uint256 _tokenId) public view override returns (string memory){
        bytes memory dataURI = abi.encodePacked(
            '{"name": "',
            _idToMeta[_tokenIdToItemId[_tokenId]].name,
            '", "description": "',
            _idToMeta[_tokenIdToItemId[_tokenId]].description,
            '", "image": "',
            _idToMeta[_tokenIdToItemId[_tokenId]].image,
            '", "attributes": [{ "trait_type": "Artist Name", "value": "',
            _idToMeta[_tokenIdToItemId[_tokenId]].artist,
            '"},{ "trait_type": "Date Drawn", "value": "',
            _idToMeta[_tokenIdToItemId[_tokenId]].date,
            '"},{ "trait_type": "Art Category", "value": "',
            _idToMeta[_tokenIdToItemId[_tokenId]].category,
            '"},{ "trait_type": "Metropolis World City", "value": "',
            _idToMeta[_tokenIdToItemId[_tokenId]].city,
            '"},{ "trait_type": "Gallery Premier", "value": "',
            _idToMeta[_tokenIdToItemId[_tokenId]].gallery,
            '"}]}'
        );
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function setContractURI(
    string memory name,
    string memory desc,
    string memory image,
    string memory link,
    string memory royalty
  ) external onlyRole(UPDATER_ROLE){
    string memory x = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        name,
        '", "description": "',
        desc,
        '", "image": "',
        image,
        '", "external_link": "',
        link,
        '","seller_fee_basis_points":"',
        royalty, // 100 Indicates a 1% seller fee
        '", "fee_recipient": "',
        msg.sender,
        '" }' // Where seller fees will be paid to.}
      )
    );
    _contractURI = string(abi.encodePacked("data:application/json;base64,", x));
    //console.log("contract uri updated");
  }

  function contractURI() external view returns (string memory) {
    return _contractURI;
  }

}