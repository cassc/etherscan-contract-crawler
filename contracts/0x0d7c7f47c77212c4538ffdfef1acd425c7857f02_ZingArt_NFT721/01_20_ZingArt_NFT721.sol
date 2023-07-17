// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./library/Base_ZingNFT_721.sol";

/**
 * @title ZingArt_NFT721
 * ZingArt_NFT721 - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract ZingArt_NFT721 is Base_ZingNFT_721 {
    struct TokenData {
        address receiver;
        string tokenUri;
        string dbId;
        address creator;
        uint256 price;
        uint16 royaltyFee;
        uint256 supply;
    }
    uint256 private _currentTokenId = 0;
    // mapping for token Id's By DbId
    mapping(string => uint256) private _tokenIdByDbId;
    // mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => address) private _tokenCreators;
    /// frozen Tokens
    mapping(uint256 => bool) private _fronzenTokens;

    /// @dev Events of the contract
    event Minted(uint256 tokenId, TokenData tokenData);
    event LazyMinted(uint256 tokenId, TokenData tokenData);
    event MintFeeUpdated(uint256 newMintFee);
    event TreasuryAddressUpdated(address payable newTreasuryAddress);
    event MetaDataFrozen(string _value, uint256 indexed _id);
    event Burned(uint256 tokenId, address burner);

    /// @notice Platform fee
    uint256 public mintFee;
    /// @notice Platform fee receipient
    address payable public _treasuryAddress;
    bool internal _isFrozen;
    address _marketplace;

    /// @notice Contract constructor
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _newMintFee,
        address payable _newTreasuryAddress
    ) ERC721(_name, _symbol) ERC2771Context(owner()) {
        mintFee = _newMintFee;
        _treasuryAddress = _newTreasuryAddress;
        _marketplace = address(0x0000000000006c3852cbef3e08e8df289169ede581);
    }

    /**
     * @notice Updates the mint fee required for each new token minted
     * @param newMintFee The new mint fee to be set
     */
    function updateMintFee(uint256 newMintFee) external onlyOwner {
        require(
            newMintFee != mintFee,
            "ZingNFT_721: mint fee already set to this value"
        );
        mintFee = newMintFee;
        emit MintFeeUpdated(newMintFee);
    }

    // ["0xaBd39d4596dd947444C11b9EeC492059B5c927ed","ff","ff","0xaBd39d4596dd947444C11b9EeC492059B5c927ed",0,0]
    /**
     * @notice Updates the treasury address for the contract
     * @param newTreasuryAddress The new treasury address to be set
     */
    function updateTreasuryAddress(
        address payable newTreasuryAddress
    ) external onlyOwner {
        require(
            newTreasuryAddress != address(0),
            "ZingNFT_721: treasury address cannot be zero"
        );
        require(
            newTreasuryAddress != _treasuryAddress,
            "ZingNFT_721: treasury address already set to this value"
        );
        _treasuryAddress = newTreasuryAddress;
        emit TreasuryAddressUpdated(newTreasuryAddress);
    }

    /**
     * @dev Mints a new token to an address with a tokenURI.
     */
    function mint(TokenData calldata _data) external payable {
        require(
            _data.receiver != address(0),
            "ZingNFT_721: The recipient cannot be zero"
        );
        require(
            _data.royaltyFee <= 10000,
            "ZingNFT_721: Royalty fee cannot be more than 100%"
        );

        require(
            msg.value >= mintFee,
            "ZingNFT_721: Insufficient funds to mint."
        );

        (bool success, ) = _treasuryAddress.call{value: mintFee}("");
        if (!success) {
            revert("ZingNFT_721: Failed to pay mint fee");
        }

        require(
            bytes(_data.tokenUri).length > 0,
            "ZingNFT_721: Token URI cannot be empty"
        );
        uint256 newTokenId = _internalMint(_data);

        emit Minted(newTokenId, _data);
    }

    /** Lazy Mints
     * @dev Mints a new token to an address with a tokenURI.
     */
    function lazyMint(TokenData calldata _data) external payable {
        require(
            msg.value >= mintFee + _data.price,
            "ZingNFT_721: Insufficient funds to mint."
        );
        require(
            _data.royaltyFee <= 10000,
            "Royalty fee cannot be more than 100%"
        );

        (bool payTreasury, ) = _treasuryAddress.call{value: mintFee}("");
        if (!payTreasury) {
            revert("ZingNFT_721: Failed to pay mint fee");
        }

        (bool payCreator, ) = _data.creator.call{value: (msg.value - mintFee)}(
            ""
        );
        if (!payCreator) {
            revert("ZingNFT_721: Failed to pay royalty");
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
            "ZingNFT_721: Token URI cannot be empty"
        );
        uint256 _newTokenId = _getNextTokenId();
        _safeMint(_data.receiver, _newTokenId);
        _tokenURIs[_newTokenId] = _data.tokenUri;
        _setTokenDbId(_newTokenId, _data.dbId);
        _tokenCreators[_newTokenId] = _data.creator;
        _updateRoyalty(_newTokenId, _data.royaltyFee);
        return _newTokenId;
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private returns (uint256) {
        return _currentTokenId += 1;
    }

    /**
     * @dev checks the given token ID is approved either for all or the single token ID
     */
    function isApproved(
        uint256 _tokenId,
        address _operator
    ) public view returns (bool) {
        return
            isApprovedForAll(ownerOf(_tokenId), _operator) ||
            getApproved(_tokenId) == _operator;
    }

    /**
     * Override isApprovedForAll to whitelist Zenft contracts to enable gas-less listings.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view override(ERC721, IERC721) returns (bool) {
        // Whitelist Zenft auction, marketplace, bundle marketplace contracts for easy trading.
        if (_marketplace == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * Override _isApprovedOrOwner to whitelist ZingIt contracts to enable gas-less listings.
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view override returns (bool) {
        _requireMinted(tokenId);

        address owner = ERC721.ownerOf(tokenId);
        if (isApprovedForAll(owner, spender)) return true;
        return super._isApprovedOrOwner(spender, tokenId);
    }

    function updateMarketplace(address _newMarketplace) external onlyOwner {
        _marketplace = _newMarketplace;
    }

    //Retrieve the token URI for a given token ID
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_dbId` as the dbId of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenDbId(
        uint256 tokenId,
        string memory _dbId
    ) internal virtual {
        require(
            _tokenIdByDbId[_dbId] == 0,
            "ZingNFT_721: Token already minted"
        );

        _tokenIdByDbId[_dbId] = tokenId;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
    @notice Burns a NFT, releasing any composed  tokens held by the token itself
    @dev Only the owner or an approved sender can call this method
    @param _tokenId the token ID to burn
    */
    function burn(uint256 _tokenId) public returns (bool) {
        address operator = _msgSender();
        require(
            ownerOf(_tokenId) == operator || isApproved(_tokenId, operator),
            "Only NFT owner or approved"
        );

        // Destroy token mappings
        _burn(_tokenId);
        return true;
    }

    //Freeze Metadata for a token
    function freezeMetaData(
        uint256 _tokenId,
        string memory _tokenURI
    ) public onlyOwner {
        _requireMinted(_tokenId);
        require(
            !_fronzenTokens[_tokenId],
            "ZingNFT_721: Metadata is already frozen"
        );
        _fronzenTokens[_tokenId] = true;
        _tokenURIs[_tokenId] = _tokenURI;
        emit MetaDataFrozen(tokenURI(_tokenId), _tokenId);
    }

    /* This method gets the tokenId using the dbId */
    function tokenByDbId(string memory _dbId) public view returns (uint256) {
        return _tokenIdByDbId[_dbId];
    }

    /* This Method gets the creator of the token */
    function creator(uint256 _tokenId) public view returns (address) {
        return _tokenCreators[_tokenId];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * This override additionally checks to see if a token-specific URI was set for the token,
     * and if so, it returns that URI. Otherwise, it falls back to the token URI set via {_setTokenURI}.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) public virtual onlyOwner {
        _requireMinted(tokenId);
        require(
            !_fronzenTokens[tokenId],
            "ZingNFT_721: Contract is already frozen"
        );

        address operator = _msgSender();
        require(
            ownerOf(tokenId) == operator || isApproved(tokenId, operator),
            "ZingNFT_721: Only NFT owner or approved"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }
}