// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// Interfaces.
import "./interfaces/IToken.sol";

/**
 * @title Furio Downline NFT
 * @author Steve Harmeyer
 * @notice This is the ERC721 contract for $FURDOWNLINE.
 */

/// @custom:security-contact [email protected]
contract DownlineV2 is BaseContract, ERC721Upgradeable
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __ERC721_init("Furio Downline NFT", "$FURDL");
        __BaseContract_init();
        _properties.buyPrice = 5e18; // 5 $FUR.
        _properties.sellPrice = 4e18; // 4 $FUR.
        _properties.maxPerUser = 15; // 15 NFTs max per user.
        createGeneration(10000, 'ipfs://QmPmvwSarTWNBYAcXhbGUCUUkGsiD7hXx8qpk49YwCAGcU/');
    }

    using Counters for Counters.Counter;

    /**
     * Properties.
     */
    struct Properties {
        uint256 buyPrice;
        uint256 sellPrice;
        uint256 maxPerUser;
    }
    Properties private _properties;

    /**
     * Generation struct.
     * @dev Data structure for generation info.
     * this allows us to increase the supply with new art and description.
     */
    struct Generation {
        uint256 maxSupply;
        string baseUri;
    }

    /**
     * Generation tracker.
     * @dev Keeps track of how many generations exist.
     */
    Counters.Counter private _generationTracker;

    /**
     * Mapping to store generation info.
     */
    mapping(uint256 => Generation) private _generations;

    /**
     * Mapping to store token generations.
     */
    mapping(uint256 => uint256) private _tokenGenerations;

    /**
     * Token id tracker.
     * @dev Keeps track of the current token id.
     */
    Counters.Counter private _tokenIdTracker;

    /**
     * Freeze URI event.
     * @dev Tells opensea that the metadata is frozen.
     */
    event PermanentURI(string value_, uint256 indexed id_);

    /**
     * Total supply.
     * @return uint256
     * @notice returns the total amount of NFTs created.
     */
    function totalSupply() public view returns (uint256)
    {
        return _tokenIdTracker.current();
    }

    /**
     * Max supply.
     * @return uint256
     * @notice Returns the sum of the max supply for all generations.
     */
    function maxSupply() public view returns (uint256)
    {
        uint256 _maxSupply;
        for(uint256 i = 1; i <= _generationTracker.current(); i++) {
            _maxSupply += _generations[i].maxSupply;
        }
        return _maxSupply;
    }

    /**
     * Buy an NFT.
     * @notice Allows a user to buy an NFT.
     */
    function buy(uint256 quantity_) external whenNotPaused returns (bool)
    {
        IToken _token_ = IToken(addressBook.get("token"));
        require(address(_token_) != address(0), "Token not set");
        require(balanceOf(msg.sender) + quantity_ <= _properties.maxPerUser, "Address already owns max");
        require(totalSupply() + quantity_ < maxSupply(), "Sold out");
        require(_token_.transferFrom(msg.sender, address(this), _properties.buyPrice * quantity_), "Payment failed");
        require(_token_.transfer(addressBook.get("vault"), _properties.buyPrice - _properties.sellPrice), "Transfer to vault failed");
        for(uint256 i = 0; i < quantity_; i ++) {
            _tokenIdTracker.increment();
            uint256 _id_ = _tokenIdTracker.current();
            _mint(msg.sender, _id_);
            emit PermanentURI(tokenURI(_id_), _id_);
        }
        return true;
    }

    /**
     * Sell an NFT.
     * @param quantity_ Quantity to sell.
     * @return bool True if successful.
     */
    function sell(uint256 quantity_) external whenNotPaused returns (bool)
    {
        IToken _token_ = IToken(addressBook.get("token"));
        require(address(_token_) != address(0), "Token not set");
        require(balanceOf(msg.sender) >= quantity_, "Quantity is too high");
        uint256 _refund_ = 0;
        uint256[] memory _tokens_ = new uint256[](quantity_);
        for(uint256 i = 0; i < quantity_; i ++) {
            _refund_ += _properties.sellPrice;
            _tokens_[i] = tokenOfOwnerByIndex(msg.sender, i);
        }
        for(uint256 i = 0; i < _tokens_.length; i ++) {
            super._burn(_tokens_[i]);
        }
        uint256 _balance_ = _token_.balanceOf(address(this));
        if(_balance_ < _refund_) {
            _token_.mint(address(this), _refund_ - _balance_);
        }
        require(_token_.transfer(msg.sender, _refund_), "Payment failed");
        return true;
    }

    /**
     * Mint an NFT.
     * @param to_ The address receiving the NFT.
     * @param quantity_ The number of NFTs to mint.
     * @notice This function is used to mint presale NFTs for team addresses.
     */
    function mint(address to_, uint256 quantity_) external onlyOwner
    {
        require(balanceOf(to_) + quantity_ <= _properties.maxPerUser, "Address already owns max");
        require(totalSupply() + quantity_ < maxSupply(), "Sold out");
        for(uint256 i = 0; i < quantity_; i ++) {
            _tokenIdTracker.increment();
            uint256 _id_ = _tokenIdTracker.current();
            _mint(to_, _id_);
            emit PermanentURI(tokenURI(_id_), _id_);
        }
    }

    function _mint(address to_, uint256 tokenId_) internal override
    {
        require(!_exists(tokenId_), "Token already exists");
        super._mint(to_, tokenId_);
        _tokenGenerations[tokenId_] = _generationTracker.current();
    }


    /**
     * Find which tokens a user owns.
     * @param owner_ Address of NFT owner.
     * @param index_ The index of the token looking for. Hint: all are 0.
     * @notice This function returns the token id owned by address_.
     * @dev This function is simplified since each address can only own
     * one NFT. No need to do complex enumeration.
     */
    function tokenOfOwnerByIndex(address owner_, uint256 index_) public view returns(uint256) {
        uint256 count = 0;
        for(uint256 i = 1; i <= _tokenIdTracker.current(); i++) {
            if(!_exists(i)) {
                continue;
            }
            if(ownerOf(i) == owner_) {
                if(count == index_) {
                    return i;
                }
                count++;
            }
        }
        return 0;
    }

    /**
     * Token URI.
     * @param tokenId_ The id of the token.
     * @notice This returns base64 encoded json for the token metadata. Allows us
     * to avoid putting metadata on IPFS.
     */
    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "Token does not exist");
        return string(abi.encodePacked(_generations[_tokenGenerations[tokenId_]].baseUri, Strings.toString(tokenId_)));
    }

    /**
     * -------------------------------------------------------------------------
     * OWNER FUNCTIONS
     * -------------------------------------------------------------------------
     */

    /**
     * Create a generation.
     * @param maxSupply_ The maximum NFT supply for this generation.
     * @param baseUri_ The metadata base URI for this generation.
     * @notice This method creates a new NFT generation.
     */
    function createGeneration(
        uint256 maxSupply_,
        string memory baseUri_
    ) public onlyOwner
    {
        _generationTracker.increment();
        _generations[_generationTracker.current()].maxSupply = maxSupply_;
        _generations[_generationTracker.current()].baseUri = baseUri_;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}