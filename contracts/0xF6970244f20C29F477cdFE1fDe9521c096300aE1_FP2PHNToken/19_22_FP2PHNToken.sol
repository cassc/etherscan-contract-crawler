// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Access.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
* @notice Contract module with 30 NFTs.
*/
contract FP2PHNToken is Access, ERC721Enumerable, DefaultOperatorFilterer {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    /**
    *    @notice Base URI for tokens. 
    */
    string public baseURI;

    /**
    *    @notice Shows if changing base URI is locked. See {lockCollection}.
    */
    bool public isCollectionLocked;

    /**
    *   @notice Total supply of tokens for this contract.
    *   @dev This is a fixed number.
    */
    uint256 public constant MAX_SUPPLY = 30;

    Counters.Counter private _tokenIDs;

    /**
    *   @notice Emitted when `_tokenID` is minted to `_to` address.
    */
    event TokenMinted(address _to, uint256 _tokenID);

    /**
    *   @notice Emitted when collection is locked by owner. See {lockCollection}.
    */
    event CollectionLocked(bool _isLocked);

    /**
    *   @notice Emitted when base URI is updated to `_newBaseURI`. See {setBaseURI}.
    */
    event BaseURIUpdated(string _newBaseURI);


    /**
    *   @notice Initializes contract setting a `_name`, `_symbol` and `_baseURI` to the collection.
    *   Also sets `isCollectionLocked` to false.
    */
    constructor(string memory _name, string memory _symbol, string memory _baseURI) 
        ERC721 (_name, _symbol)
        Access() 
    {
        isCollectionLocked = false;
        baseURI = _baseURI;
    }

    /**
    *   @notice Returns the available (mintable) amount of tokens.
    */
    function tokensAvailable() public view returns (uint256) {
        return MAX_SUPPLY - _tokenIDs.current();
    }

    /**
    *   @notice Returns true if `_tokenID` exists.
    */
    function tokenExists(uint256 _tokenID) public view returns (bool) {
        return _exists(_tokenID);
    }

    /**
    *   @dev See {IERC165-supportsInterface}.
    */
    function supportsInterface(bytes4 interfaceId)
        public 
        view
        override (Access, ERC721Enumerable) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

     /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view 
        virtual
        override 
        returns (string memory) 
    {
        require(tokenExists(tokenId));
        return string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId)));
    }

    /**
    *   @notice Gives permission to `to` to transfer `tokenId` token to another account.
    *   @dev Override needed for OpenSea royalty enforcement. See {ERC721-approve}.
    */
    function approve(address operator, uint256 tokenId)
        public 
        override (ERC721, IERC721) 
        onlyAllowedOperatorApproval(operator) 
    {
        super.approve(operator, tokenId);
    }
     
    /**
    *   @notice Approve or remove `operator` as an operator for the caller.
    *   @dev Override needed for OpenSea royalty enforcement. See {ERC721-setApprovalForAll}.
    */
    function setApprovalForAll(address operator, bool approved)
        public
        override (ERC721, IERC721) 
        onlyAllowedOperatorApproval(operator) 
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
    *   @notice Transfers `tokenId` token from `from` to `to`.
    *   @dev Override needed for OpenSea royalty encforcement. See {ERC721-transferFrom}.
    */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override (ERC721, IERC721) 
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /**
    *   @notice Safely transfers `tokenId` token from `from` to `to`.
    *   @dev Override needed for OpenSea royalty enforcement. See {ERC721-safeTransferFrom}.
    */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override (ERC721, IERC721) 
        onlyAllowedOperator(from) 
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
    *   @notice Safely transfers `tokenId` token from `from` to `to`.
    *   @dev Override needed for OpenSea royalty enforcement. See {ERC721-safeTransferFrom}.
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override (ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
    *   @notice Mints a token to address `_to`.
    *   @dev Only with minter role. See {Access-onlyMinter}.
    *   Reverts with "Total supply reached"
    *   Autoincrements the tokenID.
    */
    function mint(address _to) public onlyMinter {
        require(tokensAvailable() > 0, "Total supply reached");
        _tokenIDs.increment();
        uint256 newItemID = _tokenIDs.current();
        _safeMint(_to, newItemID);
        emit TokenMinted(_to, newItemID);
    }

    /**
    *   @notice Locks the collection base URI, so it cannot be modified.
    *   @dev Only with owner role. See {Ownable-onlyOwner}. Emits a {CollectionLocked} event.
    */
    function lockCollection () public onlyOwner {
        isCollectionLocked = true;
        emit CollectionLocked(isCollectionLocked);
    }

    /**
    *   @notice Updates the base URI of collection.
    *   @dev Only with admin role. See {Access-onlyAdmin}. Emits a {BaseURIUpdated} event.
    */
    function setBaseURI (string memory _newBaseURI) public onlyAdmin {
        require(!isCollectionLocked, "Collection is locked");
        baseURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }
}