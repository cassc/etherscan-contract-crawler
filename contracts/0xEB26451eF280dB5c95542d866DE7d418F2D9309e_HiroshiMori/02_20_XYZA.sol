// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "./CollectionManager.sol";
import "./interfaces/IURIResolver.sol";
import "./interfaces/IERC2981.sol";
import "./interfaces/IOperatorFilterRegistry.sol";

/// @title XYZA Generic Multi-Collection ERC721
contract XYZA is
    ERC721,
    ERC721Burnable,
    AccessControl,
    CollectionManager,
    IERC2981,
    Ownable
{
    using Strings for uint256;
    uint256 public totalSupply;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Precondition that the caller is an admin or the artist
    modifier onlyCollectionAdmin(uint256 collectionId) override {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                (collectionId < collections.length &&
                    msg.sender == collections[collectionId].artist),
            "not authorized"
        );
        _;
    }

    /// @dev Precondition that a quantity is not zero
    modifier quantityNonZero(uint256 quantity) {
        require(quantity > 0, "quantity is zero");
        _;
    }

    /// @dev Precondition that the collection is active
    modifier collectionActive(uint256 collectionId) {
        require(collections[collectionId].active, "collection not active");
        _;
    }

    /// @dev Precondition that the collection has started
    modifier collectionStarted(uint256 collectionId) {
        require(
            collections[collectionId].startTime <= block.timestamp,
            "collection not started"
        );
        _;
    }

    /// @dev Precondition that the correct payment is attached
    modifier collectionPaymentAttached(uint256 collectionId, uint256 quantity) {
        require(
            collections[collectionId].price * quantity == msg.value,
            "incorrect payment"
        );
        _;
    }

    /// @dev Precondition that the amount is less than the per mint quantity
    modifier collectionPerMintQuanityRespected(
        uint256 collectionId,
        uint256 quantity
    ) {
        require(
            collections[collectionId].perMintQuantity == 0 ||
                collections[collectionId].perMintQuantity >= quantity,
            "quantity too great"
        );
        _;
    }

    /// @dev Precondition that the payment receiver exists
    modifier collectionPaymentReceiverExists(uint256 collectionId) {
        require(
            collections[collectionId].paymentReceiver != address(0),
            "no payment receiver"
        );
        _;
    }

    /// @notice Mint tokens from a collection to the caller
    /// @param collectionId The id of the collection
    /// @param quantity The number of tokens to mint
    function safeMint(uint256 collectionId, uint256 quantity) public payable {
        safeMintTo(msg.sender, collectionId, quantity);
    }

    /// @notice Mint tokens from a collection to an account
    /// @param to The account to mint to
    /// @param collectionId The id of the collection
    /// @param quantity The number of tokens to mint
    function safeMintTo(
        address to,
        uint256 collectionId,
        uint256 quantity
    )
        public
        payable
        quantityNonZero(quantity)
        collectionExists(collectionId)
        collectionActive(collectionId)
        collectionStarted(collectionId)
        collectionPaymentAttached(collectionId, quantity)
        collectionPerMintQuanityRespected(collectionId, quantity)
        collectionPaymentReceiverExists(collectionId)
    {
        _safeMintTo(to, collectionId, quantity);
        (bool ok, ) = payable(collections[collectionId].paymentReceiver).call{
            value: msg.value
        }("");
        require(ok, "payment failed");
    }

    /// @notice Mint tokens from a collection to the caller, who must be the
    /// collection artist
    /// @param collectionId The id of the collection
    /// @param quantity The number of tokens to mint
    function artistMint(uint256 collectionId, uint256 quantity) public {
        artistMintTo(msg.sender, collectionId, quantity);
    }

    /// @notice Mint tokens from a collection to an account, must be called by
    /// the collection artist
    /// @param to The account to mint to
    /// @param collectionId The id of the collection
    /// @param quantity The number of tokens to mint
    function artistMintTo(
        address to,
        uint256 collectionId,
        uint256 quantity
    )
        public
        onlyCollectionAdmin(collectionId)
        quantityNonZero(quantity)
        collectionExists(collectionId)
    {
        _safeMintTo(to, collectionId, quantity);
    }

    /// @notice Mint tokens from a collection to an address
    /// @param to The address to mint to
    /// @param collectionId The id of the collection
    /// @param quantity The number of tokens to mint
    function _safeMintTo(
        address to,
        uint256 collectionId,
        uint256 quantity
    ) internal {
        uint256 firstTokenId = _consumeTokenIds(collectionId, quantity);
        address artist = collections[collectionId].artist;
        bool directMint = collections[collectionId].directMint || to == artist;
        for (uint256 i = 0; i < quantity; i++) {
            if (directMint) {
                _safeMint(to, firstTokenId + i);
            } else {
                _safeMint(artist, firstTokenId + i);
                _safeTransfer(artist, to, firstTokenId + i, "");
            }
        }
    }

    /// @notice Transfer multiple tokens to multiple accounts
    /// @param to The accounts to transfer to
    /// @param tokenIds The respective ids of the tokens to transfer
    function safeBatchTransfer(
        address[] calldata to,
        uint256[] calldata tokenIds
    ) public {
        require(to.length == tokenIds.length, "array lengths must match");
        for (uint256 i = 0; i < to.length; i++) {
            safeTransferFrom(msg.sender, to[i], tokenIds[i]);
        }
    }

    /// @notice Get the id of a collection for a given token
    /// @param tokenId The id of the token
    /// @return The id of the collection
    function getCollectionIdFromTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(_exists(tokenId), "token does not exist");
        return _getCollectionId(tokenId);
    }

    /// @notice See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl, IERC165)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    /// @notice See {IERC2981-royaltyInfo}
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "token does not exist");
        uint256 collectionId = _getCollectionId(_tokenId);
        return (
            collections[collectionId].paymentReceiver,
            (collections[collectionId].royaltyPercentage * _salePrice) / 10**18
        );
    }

    /// @notice See {ERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "token does not exist");
        uint256 collectionId = _getCollectionId(tokenId);
        if (collections[collectionId].uriResolver != address(0)) {
            return
                IURIResolver(collections[collectionId].uriResolver).tokenURI(
                    tokenId
                );
        }
        string memory baseURI = collections[collectionId].baseURI;
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /// @notice Transfers ownership of the contract to a new account (`newOwner`).
    /// @param newOwner New owner
    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newOwner != address(0), "new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from == address(0)) {
            totalSupply++;
        }
        if (to == address(0)) {
            totalSupply--;
        }
    }

    // See: https://github.com/ProjectOpenSea/operator-filter-registry

    IOperatorFilterRegistry public operatorFilterRegistry;

    error OperatorNotAllowed(address operator);

    function subscribeToFilterRegistry(
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(
                        address(this),
                        subscriptionOrRegistrantToCopy
                    );
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    event OperatorFilterRegistrySet(address indexed newOperatorFilterRegistry);

    function setOperatorFilterRegistry(address _operatorFilterRegistry)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        operatorFilterRegistry = IOperatorFilterRegistry(
            _operatorFilterRegistry
        );
        emit OperatorFilterRegistrySet(_operatorFilterRegistry);
    }

    modifier onlyAllowedOperator(address from) {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !(operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    msg.sender
                ) &&
                    operatorFilterRegistry.isOperatorAllowed(
                        address(this),
                        from
                    ))
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}