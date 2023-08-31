// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./library/Base_ZingNFT_1155.sol";

/**
 * @title ZingArt_NFT1155
 * ZingArt_NFT1155 - ERC1155 contract that whitelists an operator address, 
 * has mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ZingArt_NFT1155 is Base_ZingNFT_1155 {
    struct TokenData {
        address receiver;
        string tokenUri;
        string dbId;
        address creator;
        uint256 price;
        uint16 royaltyFee;
        uint256 supply;
        uint256 amountPurchased;
    }
    uint256 private _currentTokenID = 0;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    // mapping for token Id's By DbId
    mapping(string => uint256) public tokenIdByDbId;
    /// frozen Tokens
    mapping(uint256 => bool) public fronzenTokens;

    mapping(uint256 => uint256) public tokenSupply;

    event TreasuryAddressUpdated(address payable treasuryAddress);
    event Burned(uint256 tokenId, uint256 quantity, address burner);
    event ServiceFeeUpdated(uint256 serviceFee);
    event MetadataFrozen(string _value, uint256 indexed _id);
    event LazyMinted(uint256 tokenId, TokenData tokenData);
    event Minted(uint256 tokenId, TokenData tokenData);

    // Mint fee
    uint256 public serviceFee;
    // Platform fee receipient
    address payable public treasuryAddress;
    address public marketplace;
    string public symbol;
    string public name;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _newServiceFee,
        address payable _newTreasuryAddress
    ) ERC1155("%id%") {
        name = _tokenName;
        symbol = _tokenSymbol;
        serviceFee = _newServiceFee;
        treasuryAddress = _newTreasuryAddress;
    }

    function updateServiceFee(uint256 newServiceFee) external onlyOwner {
        require(
            newServiceFee != serviceFee,
            "ZingNFT_1155: mint fee already set to this value"
        );
        serviceFee = newServiceFee;
        emit ServiceFeeUpdated(newServiceFee);
    }

    function updateTreasuryAddress(
        address payable newTreasuryAddress
    ) external onlyOwner {
        require(
            newTreasuryAddress != address(0),
            "ZingNFT_1155: treasury address cannot be zero"
        );
        require(
            newTreasuryAddress != treasuryAddress,
            "ZingNFT_1155: treasury address already set to this value"
        );
        treasuryAddress = newTreasuryAddress;
    }

    function mint(TokenData calldata _data) external payable {
        require(
            _data.receiver != address(0),
            "ZingNFT_1155: The recipient cannot be zero"
        );
        require(
            _data.royaltyFee <= 10000,
            "ZingNFT_1155: Royalty fee cannot be more than 100%"
        );
        require(
            bytes(_data.tokenUri).length > 0,
            "ZingNFT_1155: Token URI cannot be empty"
        );
        uint256 newTokenId = _internalMint(_data);

        emit Minted(newTokenId, _data);
    }

    function lazyMint(TokenData calldata _data) external payable {
        uint256 calculatedServiceFee = ((_data.price * serviceFee) / 100);
        require(
            msg.value >= _data.price,
            "ZingNFT_1155: Insufficient funds to mint."
        );
        require(
            _data.royaltyFee <= 10000,
            "Royalty fee cannot be more than 100%"
        );

        (bool payTreasury, ) = treasuryAddress.call{
            value: calculatedServiceFee
        }("");
        if (!payTreasury) {
            revert("ZingNFT_1155: Failed to pay service fee");
        }

        (bool payCreator, ) = _data.creator.call{
            value: (msg.value - calculatedServiceFee)
        }("");
        if (!payCreator) {
            revert("ZingNFT_1155: Failed to pay royalty");
        }
        uint256 newTokenId = _internalMint(_data);
        emit LazyMinted(newTokenId, _data);
    }

    /**
     * @dev Mints a new token to an address with a tokenURI.
     */
    function _internalMint(
        TokenData calldata _data
    ) internal returns (uint256) {
        require(
            bytes(_data.tokenUri).length > 0,
            "ZingNFT_1155: Token URI cannot be empty"
        );
        uint256 _newTokenId = _getNextTokenId();
        uint256 remainingSupply = _data.supply - _data.amountPurchased;

        _mint(_data.receiver, _newTokenId, _data.amountPurchased, bytes(""));
        if (remainingSupply > 0) {
            _mint(_data.creator, _newTokenId, remainingSupply, bytes(""));
        }
        _tokenURIs[_newTokenId] = _data.tokenUri;
        _setTokenDbId(_newTokenId, _data.dbId);
        tokenCreators[_newTokenId] = _data.creator;
        _updateRoyalty(_newTokenId, _data.royaltyFee);
        return _newTokenId;
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenID
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private returns (uint256) {
        return _currentTokenID += 1;
    }

    /**
     * Override isApprovedForAll to whitelist Zenft contracts to enable gas-less listings.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view override(ERC1155) returns (bool) {
        // Whitelist Zenft auction, marketplace, bundle marketplace contracts for easy trading.
        if (marketplace == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function _isApprovedOrOwner(
        address spender,
        address owner
    ) internal view virtual returns (bool) {
        return (spender == owner || isApprovedForAll(owner, spender));
    }

    function updateMarketplace(address _newMarketplace) external onlyOwner {
        marketplace = _newMarketplace;
    }

    function uri(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC1155: approved query for nonexistent token"
        );
        string memory _tokenURI = _tokenURIs[_tokenId];
        return _tokenURI;
    }

    /**
     * @dev Sets `_dbId` as the dbId of `tokenId`.
     */
    function _setTokenDbId(
        uint256 tokenId,
        string memory _dbId
    ) internal virtual {
        require(
            tokenIdByDbId[_dbId] == 0,
            "ZingNFT_1155: Token already minted"
        );

        tokenIdByDbId[_dbId] = tokenId;
    }

    /**
     * @dev See {ERC1155-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(
        address from,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        super._burn(from, tokenId, quantity);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        emit Burned(tokenId, quantity, from);
    }

    /**
    @notice Burns a NFT, releasing any composed  tokens held by the token itself
    @dev Only the owner or an approved sender can call this method
    @param _tokenId the token ID to burn
    */
    function burn(uint256 _tokenId, uint256 _quantity) public returns (bool) {
        address operator = _msgSender();
        require(
            owner() == operator || isApprovedForAll(owner(), operator),
            "Only NFT owner or approved"
        );

        // Destroy token mappings
        _burn(operator, _tokenId, _quantity);
        return true;
    }

    function freezeMetaData(
        uint256 _tokenId,
        string memory _tokenURI
    ) public onlyOwner {
        require(
            !fronzenTokens[_tokenId],
            "ZingNFT_1155: Metadata is already frozen"
        );
        fronzenTokens[_tokenId] = true;
        setTokenURI(_tokenId, _tokenURI);
        emit MetadataFrozen(uri(_tokenId), _tokenId);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param _id uint256 ID of the token to set its URI
     * @param _uri string URI to assign
     */
    function setTokenURI(
        uint256 _id,
        string memory _uri
    ) public virtual onlyOwner {
        require(_exists(_id), "ERC1155: approved query for nonexistent token");
        require(
            !fronzenTokens[_id],
            "ZingNFT_1155: Contract is already frozen"
        );

        _tokenURIs[_id] = _uri;
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) public view returns (bool) {
        return tokenCreators[_id] != address(0);
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}