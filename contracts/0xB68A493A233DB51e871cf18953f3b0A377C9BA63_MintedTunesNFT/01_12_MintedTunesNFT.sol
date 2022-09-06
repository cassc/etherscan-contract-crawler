// MintedTunes NFT token
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface INFTFactory {
    function owner() external view returns (address);
    function getMintFee() external view returns (uint256);
}

contract MintedTunesNFT is ERC721Upgradeable {
    using SafeMath for uint256;

    address public feeAddress;

    string public collection_name;
    string public collection_uri;
    bool public isPublic;
    address public factory;
    address public owner;

    struct Item {
        uint256 id;
        address creator;
        string uri;
        uint256 royalty;       
    }
    uint256 public currentID;    
    mapping (uint256 => Item) public Items;


    event CollectionUriUpdated(string collection_uri);    
    event CollectionNameUpdated(string collection_name);
    event TokenUriUpdated(uint256 id, string uri);

    event ItemCreated(uint256 id, address creator, string uri, uint256 royalty);
    event Burned(address owner, uint nftID);
    /**
		Initialize from Swap contract
	 */
    function initialize(
        string memory _name,
        string memory _uri,
        address creator,
        address _feeAddress,
        bool bPublic
    ) public initializer {
        factory = _msgSender();

        collection_uri = _uri;
        collection_name = _name;
        owner = creator;
        feeAddress = _feeAddress;
        isPublic = bPublic;        
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "Admin can only change feeAddress");
        feeAddress = _feeAddress;
    }
    
    /**
		Change & Get Collection Information
	 */
    function setCollectionURI(string memory newURI) public onlyOwner {
        collection_uri = newURI;
        emit CollectionUriUpdated(newURI);
    }

    function setName(string memory newname) public onlyOwner {
        collection_name = newname;
        emit CollectionNameUpdated(newname);
    }

    function transferOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;        
    }

    function getCollectionURI() external view returns (string memory) {
        return collection_uri;
    }
    function getCollectionName() external view returns (string memory) {
        return collection_name;
    }


    /**
		Change & Get Item Information
	 */
    function addItem(string memory _tokenURI, uint256 royalty) external payable returns (uint256){
        uint256 mintFee = INFTFactory(factory).getMintFee();
        require(owner == msg.sender || isPublic, "Only minter can add item");

        require(msg.value >= mintFee, "insufficient mint fee");
        payable(feeAddress).transfer(mintFee);
        currentID = currentID.add(1);        
        _safeMint(msg.sender, currentID);
        Items[currentID] = Item(currentID, msg.sender, _tokenURI, royalty);
        emit ItemCreated(currentID, msg.sender, _tokenURI, royalty);
        return currentID;
    }

    function burn(uint _tokenId) external returns (bool)  {
        require(_exists(_tokenId), "Token ID is invalid");
        require(ERC721Upgradeable.ownerOf(_tokenId) == _msgSender(), "only owner can burn");
        _burn(_tokenId);
        emit Burned(_msgSender(),_tokenId);
        return true;
    }

    function setTokenURI(uint256 _tokenId, string memory _newURI)
        public
        creatorOnly(_tokenId)
    {
        Items[_tokenId].uri = _newURI;
        emit TokenUriUpdated( _tokenId, _newURI);
    }



    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return Items[tokenId].uri;
    }    

    function creatorOf(uint256 _tokenId) public view returns (address) {
        return Items[_tokenId].creator;
    }

    function royalties(uint256 _tokenId) public view returns (uint256) {
        return Items[_tokenId].royalty;
	}

    function withdrawBNB() external {
        address factoryOwner = INFTFactory(factory).owner();
        require(
            factoryOwner == _msgSender(),
            "caller is not the factory owner"
        );

		uint balance = address(this).balance;
		require(balance > 0, "insufficient balance");
		payable(msg.sender).transfer(balance);
	}


    modifier onlyOwner() {
        require(owner == _msgSender(), "caller is not the owner");
        _;
    }
    /**
     * @dev Require _msgSender() to be the creator of the token id
     */
    modifier creatorOnly(uint256 _id) {
        require(
            Items[_id].creator == _msgSender(),
            "ERC721Tradable#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    receive() external payable {}
}