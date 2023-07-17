// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./ERC721Base.sol";
import "../metadata/MetadataEncryption.sol";
import "../tokenManager/interfaces/IPostTransfer.sol";
import "../tokenManager/interfaces/IPostBurn.sol";
import "./interfaces/IERC721GeneralMint.sol";
import "../utils/ERC721/ERC721URIStorageUpgradeable.sol";
import "./MarketplaceFilterer/MarketplaceFilterer.sol";

/**
 * @title Generalized Base ERC721
 * @author [email protected], [email protected]
 * @notice Generalized Base NFT smart contract
 */
abstract contract ERC721GeneralBase is
    ERC721Base,
    ERC721URIStorageUpgradeable,
    IERC721GeneralMint,
    MarketplaceFilterer
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Throw when attempting to mint, while mint is frozen
     */
    error MintFrozen();

    /**
     * @notice Throw when requested token is not in range within bounds of limit supply
     */
    error TokenNotInRange();

    /**
     * @notice Throw when new supply is over limit supply
     */
    error OverLimitSupply();

    /**
     * @notice Throw when array lengths are mismatched
     */
    error MismatchedArrayLengths();

    /**
     * @notice Throw when string is empty
     */
    error EmptyString();

    /**
     * @notice Contract metadata
     */
    string public contractURI;

    /**
     * @notice Limit the supply to take advantage of over-promising in summation with multiple mint vectors
     */
    uint256 public limitSupply;

    /**
     * @notice Emitted when uris are set for tokens
     * @param ids IDs of tokens to set uris for
     * @param uris Uris to set on tokens
     */
    event TokenURIsSet(uint256[] ids, string[] uris);

    /**
     * @notice Emitted when limit supply is set
     * @param newLimitSupply Limit supply to set
     */
    event LimitSupplySet(uint256 indexed newLimitSupply);

    /**
     * @notice See {IERC721GeneralMint-mintOneToOneRecipient}
     */
    function mintOneToOneRecipient(address recipient) external onlyMinter nonReentrant returns (uint256) {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }

        uint256 tempSupply = _nextTokenId();
        _requireLimitSupply(tempSupply);

        _mint(recipient, 1, tempSupply, tempSupply);

        return tempSupply;
    }

    /**
     * @notice See {IERC721GeneralMint-mintAmountToOneRecipient}
     */
    function mintAmountToOneRecipient(address recipient, uint256 amount) external onlyMinter nonReentrant {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }
        uint256 tempSupply = _nextTokenId(); // cache
        _requireLimitSupply(tempSupply + amount - 1);

        _mint(recipient, amount, tempSupply, tempSupply);
    }

    /**
     * @notice See {IERC721GeneralMint-mintOneToMultipleRecipients}
     */
    function mintOneToMultipleRecipients(address[] calldata recipients) external onlyMinter nonReentrant {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }
        uint256 recipientsLength = recipients.length;
        uint256 tempSupply = _nextTokenId(); // cache

        for (uint256 i = 0; i < recipientsLength; i++) {
            _mint(recipients[i], 1, tempSupply, tempSupply);
            tempSupply++;
        }

        _requireLimitSupply(tempSupply - 1);
    }

    /**
     * @notice See {IERC721GeneralMint-mintSameAmountToMultipleRecipients}
     */
    function mintSameAmountToMultipleRecipients(address[] calldata recipients, uint256 amount)
        external
        onlyMinter
        nonReentrant
    {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }
        uint256 recipientsLength = recipients.length;
        uint256 tempSupply = _nextTokenId(); // cache

        for (uint256 i = 0; i < recipientsLength; i++) {
            _mint(recipients[i], amount, tempSupply, tempSupply);
            tempSupply += amount;
        }

        _requireLimitSupply(tempSupply - 1);
    }

    /**
     * @notice See {IERC721GeneralMint-mintSpecificTokenToOneRecipient}
     */
    function mintSpecificTokenToOneRecipient(address recipient, uint256 tokenId) external onlyMinter nonReentrant {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }

        uint256 _limitSupply = limitSupply;
        if (_limitSupply != 0) {
            if (tokenId > _limitSupply) {
                _revert(TokenNotInRange.selector);
            }
        }

        _mint(recipient, 1, tokenId, 0);
    }

    /**
     * @notice See {IERC721GeneralMint-mintSpecificTokensToOneRecipient}
     */
    function mintSpecificTokensToOneRecipient(address recipient, uint256[] calldata tokenIds)
        external
        onlyMinter
        nonReentrant
    {
        if (_mintFrozen == 1) {
            _revert(MintFrozen.selector);
        }

        uint256 tempSupply = _nextTokenId();

        uint256 tokenIdsLength = tokenIds.length;
        uint256 _limitSupply = limitSupply;
        if (_limitSupply == 0) {
            // don't check that token id is within range, since _limitSupply being 0 implies unlimited range
            for (uint256 i = 0; i < tokenIdsLength; i++) {
                _mint(recipient, 1, tokenIds[i], tempSupply);
                tempSupply++;
            }
        } else {
            // check that token id is within range
            for (uint256 i = 0; i < tokenIdsLength; i++) {
                if (tokenIds[i] > _limitSupply) {
                    _revert(TokenNotInRange.selector);
                }
                _mint(recipient, 1, tokenIds[i], tempSupply);
                tempSupply++;
            }
        }
    }

    /**
     * @notice Override base URI system for select tokens, with custom per-token metadata
     * @param ids IDs of tokens to override base uri system for with custom uris
     * @param uris Custom uris
     */
    function setTokenURIs(uint256[] calldata ids, string[] calldata uris) external nonReentrant {
        uint256 idsLength = ids.length;
        if (idsLength != uris.length) {
            _revert(MismatchedArrayLengths.selector);
        }

        for (uint256 i = 0; i < idsLength; i++) {
            _setTokenURI(ids[i], uris[i]);
        }

        emit TokenURIsSet(ids, uris);
        observability.emitTokenURIsSet(ids, uris);
    }

    /**
     * @notice Set base uri
     * @param newBaseURI New base uri to set
     */
    function setBaseURI(string calldata newBaseURI) external nonReentrant {
        if (bytes(newBaseURI).length == 0) {
            _revert(EmptyString.selector);
        }

        address _manager = defaultManager;

        if (_manager == address(0)) {
            if (_msgSender() != owner()) {
                _revert(Unauthorized.selector);
            }
        } else {
            if (!ITokenManager(_manager).canUpdateMetadata(_msgSender(), 0, bytes(newBaseURI))) {
                _revert(Unauthorized.selector);
            }
        }

        _setBaseURI(newBaseURI);
        observability.emitBaseUriSet(newBaseURI);
    }

    /**
     * @notice Set limit supply
     * @param _limitSupply Limit supply to set
     */
    function setLimitSupply(uint256 _limitSupply) external onlyOwner nonReentrant {
        // allow it to be 0, for post-mint
        limitSupply = _limitSupply;

        emit LimitSupplySet(_limitSupply);
        observability.emitLimitSupplySet(_limitSupply);
    }

    /**
     * @notice Set contract name
     * @param newName New name
     * @param newSymbol New symbol
     * @param newContractUri New contractURI
     */
    function setContractMetadata(
        string calldata newName,
        string calldata newSymbol,
        string calldata newContractUri
    ) external onlyOwner {
        _setContractMetadata(newName, newSymbol);
        contractURI = newContractUri;

        observability.emitContractMetadataSet(newName, newSymbol, newContractUri);
    }

    /**
     * @notice See {IERC721-transferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override onlyAllowedOperator(from) {
        ERC721AUpgradeable.transferFrom(from, to, tokenId);

        address _manager = tokenManager(tokenId);
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postTransferFrom(_msgSender(), from, to, tokenId);
        }

        observability.emitTransfer(from, to, tokenId);
    }

    /**
     * @notice See {IERC721-safeTransferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable virtual override onlyAllowedOperator(from) {
        ERC721AUpgradeable.safeTransferFrom(from, to, tokenId, data);

        address _manager = tokenManager(tokenId);
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postSafeTransferFrom(_msgSender(), from, to, tokenId, data);
        }

        observability.emitTransfer(from, to, tokenId);
    }

    /**
     * @notice See {IERC721-setApprovalForAll}.
     *         Overrides default behaviour to check MarketplaceFilterer allowed operators.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice See {IERC721-approve}.
     *         Overrides default behaviour to check MarketplaceFilterer allowed operators.
     */
    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @notice See {IERC721-burn}. Overrides default behaviour to check associated tokenManager.
     */
    function burn(uint256 tokenId) public nonReentrant {
        address _manager = tokenManager(tokenId);
        address msgSender = _msgSender();

        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostBurn).interfaceId)) {
            address owner = ownerOf(tokenId);
            IPostBurn(_manager).postBurn(msgSender, owner, tokenId);
        } else {
            // default to restricting burn to owner or operator if a valid TM isn't present
            if (!_isApprovedOrOwner(msgSender, tokenId)) {
                _revert(Unauthorized.selector);
            }
        }

        _burn(tokenId);

        observability.emitTransfer(msgSender, address(0), tokenId);
    }

    /**
     * @notice Overrides tokenURI to first rotate the token id
     * @param tokenId ID of token to get uri for
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Used for meta-transactions
     */
    function _msgSender() internal view override(ERC721Base, ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @notice Used for meta-transactions
     */
    function _msgData() internal view override(ERC721Base, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure override(ERC721AUpgradeable, ERC721Base, MarketplaceFilterer) {
        ERC721AUpgradeable._revert(errorSelector);
    }

    /**
     * @notice Override base URI system for select tokens, with custom per-token metadata
     * @param tokenId Token to set uri for
     * @param _uri Uri to set on token
     */
    function _setTokenURI(uint256 tokenId, string calldata _uri) private {
        address _manager = tokenManager(tokenId);
        address msgSender = _msgSender();

        address tempOwner = owner();
        if (_manager == address(0)) {
            if (msgSender != tempOwner) {
                _revert(Unauthorized.selector);
            }
        } else {
            if (!ITokenManager(_manager).canUpdateMetadata(msgSender, tokenId, bytes(_uri))) {
                _revert(Unauthorized.selector);
            }
        }

        _tokenURIs[tokenId] = _uri;
    }

    /**
     * @notice Require the new supply of tokens after mint to be less than limit supply
     * @param newSupply New supply
     */
    function _requireLimitSupply(uint256 newSupply) private view {
        uint256 _limitSupply = limitSupply;
        if (_limitSupply != 0 && newSupply > _limitSupply) {
            _revert(OverLimitSupply.selector);
        }
    }
}