// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// Interfaces.
import "./interfaces/IToken.sol";

error DOWNLINE__invalidBalance();
error DOWNLINE__paymentFailed();

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
     * Setup.
     */
    function setup() external
    {
        _token = IToken(0x48378891d6E459ca9a56B88b406E8F4eAB2e39bF);
    }

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
            super._mint(msg.sender, _id_);
            _tokenGenerations[_id_] = _generationTracker.current();
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
        if(balanceOf(msg.sender) < quantity_) revert DOWNLINE__invalidBalance();
        uint256 _refund_ = quantity_ * _properties.sellPrice;
        for(uint256 i = 0; i < quantity_; i ++) {
            super._burn(tokenOfOwnerByIndex(msg.sender, i));
        }
        uint256 _balance_ = _token.balanceOf(address(this));
        if(_balance_ < _refund_) _token.mint(address(this), _refund_ - _balance_);
        if(!_token.transfer(msg.sender, _refund_)) revert DOWNLINE__paymentFailed();
        return true;
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;

    IToken private _token;
}