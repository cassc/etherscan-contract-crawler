// SPDX-License-Identifier: MIT
// Creator: JCBDEV (Quantum Art)
pragma solidity ^0.8.4;

import "./ERC721QUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import "./ERC2981V3.sol";
import "./TokenId.sol";
import "./ManageableUpgradeable.sol";
import "./QuantumBlackListable.sol";
import "./QuantumSpacesStorage.sol";

error VariantAndMintAmountMismatch();
error InvalidVariantForDrop();
error MintExceedsDropSupply();
error InvalidAuthorizationSignature();
error NotValidYet(uint256 validFrom, uint256 blockTimestamp);
error AuthorizationExpired(uint256 expiredAt, uint256 blockTimestamp);
error IncorrectFees(uint256 expectedFee, uint256 suppliedMsgValue);
error DropPaused(uint128 dropId);

contract QuantumSpaces is
    ERC2981,
    OwnableUpgradeable,
    ManageableUpgradeable,
    ERC721QUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using QuantumSpacesStorage for QuantumSpacesStorage.Layout;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using StringsUpgradeable for uint256;
    using TokenId for uint256;

    /// >>>>>>>>>>>>>>>>>>>>>>>  EVENTS  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    event DropMint(
        address indexed to,
        uint256 indexed dropId,
        uint256 indexed variant,
        uint256 id
    );

    /// >>>>>>>>>>>>>>>>>>>>>>>  STATE  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// >>>>>>>>>>>>>>>>>>>>>  INITIALIZER  <<<<<<<<<<<<<<<<<<<<<< ///

    function initialize(
        address admin,
        address payable quantumTreasury,
        address authorizer,
        address blAddress
    ) public virtual initializer {
        __QuantumSpaces_init(admin, quantumTreasury, authorizer, blAddress);
    }

    function __QuantumSpaces_init(
        address admin,
        address payable quantumTreasury,
        address authorizer,
        address blAddress
    ) internal onlyInitializing {
        __ERC721Q_init("QuantumSpaces", "QSPACE");
        __Ownable_init();
        __Manageable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __QuantumSpaces_init_unchained(
            admin,
            quantumTreasury,
            authorizer,
            blAddress
        );
    }

    function __QuantumSpaces_init_unchained(
        address admin,
        address payable quantumTreasury,
        address authorizer,
        address blAddress
    ) internal onlyInitializing {
        QuantumSpacesStorage.Layout storage qs = QuantumSpacesStorage.layout();
        ERC721QStorage.Layout storage erc = ERC721QStorage.layout();
        erc.baseURI = "https://core-api.quantum.art/v1/drop/metadata/space/";
        qs.ipfsURI = "ipfs://";
        qs.quantumTreasury = quantumTreasury;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MANAGER_ROLE, admin);
        qs.authorizer = authorizer;
        qs.blackListAddress = blAddress;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  BLACKLIST OPS  <<<<<<<<<<<<<<<<<<<<<< ///
    modifier isNotBlackListed(address user) {
        if (
            QuantumBlackListable.isBlackListed(
                user,
                QuantumSpacesStorage.layout().blackListAddress
            )
        ) {
            revert QuantumBlackListable.BlackListedAddress(user);
        }
        _;
    }

    function getBlackListAddress() public view returns (address) {
        return QuantumSpacesStorage.layout().blackListAddress;
    }

    function setBlackListAddress(address blAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (blAddress == address(0)) {
            revert QuantumBlackListable.InvalidBlackListAddress();
        }
        QuantumSpacesStorage.layout().blackListAddress = blAddress;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  RESTRICTED  <<<<<<<<<<<<<<<<<<<<<< ///

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice set address of the minter
    /// @param owner The address of the new owner
    function setOwner(address owner) public onlyOwner {
        transferOwnership(owner);
    }

    /// @notice set address of the minter
    /// @param minter The address of the minter - should be wallet proxy or sales platform
    function setMinter(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, minter);
    }

    /// @notice remove address of the minter
    /// @param minter The address of the minter - should be wallet proxy or sales platform
    function unsetMinter(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, minter);
    }

    /// @notice add a contract manager
    /// @param manager The address of the maanger
    function setManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, manager);
    }

    /// @notice add a contract manager
    /// @param manager The address of the maanger
    function unsetManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MANAGER_ROLE, manager);
    }

    /// @notice set address of the authorizer wallet
    /// @param authorizer The address of the authorizer - should be wallet proxy or sales platform
    function setAuthorizer(address authorizer)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        QuantumSpacesStorage.layout().authorizer = authorizer;
    }

    /// @notice set address of the treasury wallet
    /// @param treasury The address of the treasury
    function setTreasury(address payable treasury)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        QuantumSpacesStorage.layout().quantumTreasury = treasury;
    }

    /// @notice set the baseURI
    /// @param baseURI new base
    function setBaseURI(string calldata baseURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ERC721QStorage.layout().baseURI = baseURI;
    }

    /// @notice set the base ipfs URI
    /// @param ipfsURI new base
    function setIpfsURI(string calldata ipfsURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        QuantumSpacesStorage.layout().ipfsURI = ipfsURI;
    }

    /// @notice Pause contract
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause contract
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice set the IPFS CID
    /// @param dropId The drop id
    /// @param cid cid
    function setCID(uint128 dropId, string calldata cid)
        public
        onlyRole(MANAGER_ROLE)
    {
        QuantumSpacesStorage.layout().dropCID[dropId] = cid;
    }

    /// @notice Pauses a drop
    /// @dev Relay Only
    /// @param dropId drop to pause
    function pauseDrop(uint128 dropId) public onlyRole(MANAGER_ROLE) {
        QuantumSpacesStorage.Layout storage qs = QuantumSpacesStorage.layout();
        qs.isDropPaused.set(dropId);
    }

    /// @notice Unpauses a drop
    /// @dev Relay Only
    /// @param dropId drop to pause
    function unpauseDrop(uint128 dropId) public onlyRole(MANAGER_ROLE) {
        QuantumSpacesStorage.layout().isDropPaused.unset(dropId);
    }

    /// @notice configure a drop
    /// @param dropId The drop id
    /// @param maxSupply maximum items in the drop
    /// @param numOfVariants number of expected variants in drop (zero if normal drop)
    function setDrop(
        uint128 dropId,
        uint128 maxSupply,
        uint256 numOfVariants
    ) public onlyRole(MANAGER_ROLE) {
        QuantumSpacesStorage.layout().dropMaxSupply[dropId] = maxSupply;
        QuantumSpacesStorage.layout().dropNumOfVariants[dropId] = numOfVariants;
    }

    /// @notice sets the recipient of the royalties
    /// @param recipient address of the recipient
    function setRoyaltyRecipient(address recipient)
        public
        onlyRole(MANAGER_ROLE)
    {
        _royaltyRecipient = recipient;
    }

    /// @notice sets the fee of royalties
    /// @dev The fee denominator is 10000 in BPS.
    /// @param fee fee
    /*
        Example

        This would set the fee at 5%
        ```
        KeyUnlocks.setRoyaltyFee(500)
        ```
    */
    function setRoyaltyFee(uint256 fee) public onlyRole(MANAGER_ROLE) {
        _royaltyFee = fee;
    }

    /// @notice Set specific drop royalties and override the contract default
    /// @dev there is no check regarding limiting supply
    /// @param dropId Drop id to set the royalties for
    /// @param recipient recipient of royalties
    /// @param fee fee percentage - 5% = 500
    function setDropRoyalties(
        uint128 dropId,
        address recipient,
        uint256 fee
    ) public onlyRole(MANAGER_ROLE) {
        _dropRoyaltyRecipient[dropId] = recipient;
        _dropRoyaltyFee[dropId] = fee;
    }

    /// @notice Mints new tokens via a presigned authorization voucher
    /// @dev there is no check regarding limiting supply
    /// @param mintAuth preauthorization voucher
    function authorizedMint(MintAuthorization calldata mintAuth)
        public
        payable
        isNotBlackListed(mintAuth.to)
    {
        QuantumSpacesStorage.Layout storage qs = QuantumSpacesStorage.layout();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        mintAuth.id,
                        mintAuth.to,
                        mintAuth.dropId,
                        mintAuth.amount,
                        mintAuth.fee,
                        mintAuth.validFrom,
                        mintAuth.validPeriod,
                        mintAuth.freezePeriod,
                        mintAuth.variants
                    )
                )
            )
        );
        address signer = ecrecover(digest, mintAuth.v, mintAuth.r, mintAuth.s);
        if (signer != qs.authorizer) revert InvalidAuthorizationSignature();
        if (msg.value != mintAuth.fee)
            revert IncorrectFees(mintAuth.fee, msg.value);
        if (block.timestamp <= mintAuth.validFrom)
            revert NotValidYet(mintAuth.validFrom, block.timestamp);
        if (
            mintAuth.validPeriod > 0 &&
            block.timestamp > mintAuth.validFrom + mintAuth.validPeriod
        )
            revert AuthorizationExpired(
                mintAuth.validFrom + mintAuth.validPeriod,
                block.timestamp
            );

        _mint(
            mintAuth.to,
            mintAuth.dropId,
            mintAuth.amount,
            mintAuth.variants,
            mintAuth.freezePeriod
        );
        AddressUpgradeable.sendValue(qs.quantumTreasury, mintAuth.fee);
    }

    /// @notice Mints new tokens
    /// @dev there is no check regarding limiting supply
    /// @param to recipient of newly minted tokens
    /// @param dropId id of the key
    /// @param amount amount of tokens to mint
    /// @param variants use variants/episodes for token - zero for unique drops
    function mint(
        address to,
        uint128 dropId,
        uint128 amount,
        uint256[] calldata variants,
        uint8 freezePeriod
    ) public onlyRole(MINTER_ROLE) isNotBlackListed(to) {
        _mint(to, dropId, amount, variants, freezePeriod);
    }

    function _mint(
        address to,
        uint128 dropId,
        uint128 amount,
        uint256[] calldata variants,
        uint8 freezePeriod
    ) internal {
        ERC721QStorage.Layout storage erc = ERC721QStorage.layout();
        QuantumSpacesStorage.Layout storage qs = QuantumSpacesStorage.layout();
        if (erc.minted[dropId] == 0) erc.minted[dropId] = 1; //If drop is not preallocated
        uint256 numOfVariants = variants.length;
        if (
            qs.dropMaxSupply[dropId] == 0 ||
            (erc.minted[dropId] - 1) + amount > qs.dropMaxSupply[dropId]
        ) revert MintExceedsDropSupply();
        if (numOfVariants != 0 && amount != numOfVariants)
            revert VariantAndMintAmountMismatch();

        if (qs.dropNumOfVariants[dropId] > 0 && numOfVariants == 0)
            revert InvalidVariantForDrop();
        uint256 currentVariant;
        if (numOfVariants > 0) {
            //Check each variant isn't outside range
            do {
                if (
                    variants[currentVariant] < 1 ||
                    variants[currentVariant++] > qs.dropNumOfVariants[dropId]
                ) revert InvalidVariantForDrop();
            } while (currentVariant < numOfVariants);
        }
        currentVariant = 0;

        uint256 startTokenId = TokenId.from(
            dropId,
            uint128(erc.minted[dropId] - 1)
        );
        _safeMint(to, dropId, amount, freezePeriod, "");
        if (numOfVariants > 0) {
            do {
                emit DropMint(
                    to,
                    dropId,
                    variants[currentVariant],
                    startTokenId + currentVariant
                );
                qs.tokenVariant[startTokenId + currentVariant++] = variants[
                    currentVariant
                ];
            } while (currentVariant < numOfVariants);
        } else {
            uint256 endTokenId = startTokenId + amount;
            do {
                emit DropMint(to, dropId, 0, startTokenId++);
            } while (startTokenId < endTokenId);
        }
    }

    /// @notice Pre-allocate storage slots upfront for a drop
    /// @dev Relay Only
    /// @param dropId dropId to preload with gas
    /// @param quantity amount of tokens to preallocate storage space for
    function preAllocateTokens(uint128 dropId, uint128 quantity)
        public
        onlyRole(MINTER_ROLE)
    {
        _preAllocateTokens(dropId, quantity);
    }

    /// @notice Pre-allocate storage slots for known customers
    /// @dev Relay Only
    /// @param addresses list of addresses to register
    function preAllocateAddress(address[] calldata addresses)
        public
        onlyRole(MINTER_ROLE)
    {
        _preAllocateAddresses(addresses);
    }

    /// @notice Burns token that has been redeemed for something else
    /// @dev Relay Only
    /// @param tokenId id of the tokens
    function redeemBurn(uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _burn(tokenId, false);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  VIEW  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Returns the URI of the token
    /// @param tokenId id of the token
    /// @return URI for the token ; expected to be ipfs://<cid>
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        ERC721QStorage.Layout storage erc = ERC721QStorage.layout();
        QuantumSpacesStorage.Layout storage qs = QuantumSpacesStorage.layout();
        (uint128 dropId, uint128 sequenceNumber) = tokenId.split();
        uint256 actualSequence = qs.tokenVariant[tokenId] > 0
            ? qs.tokenVariant[tokenId]
            : sequenceNumber;
        if (bytes(qs.dropCID[dropId]).length > 0)
            return
                string(
                    abi.encodePacked(
                        qs.ipfsURI,
                        qs.dropCID[dropId],
                        "/",
                        actualSequence.toString()
                    )
                );
        else
            return
                string(
                    abi.encodePacked(
                        erc.baseURI,
                        uint256(dropId).toString(),
                        "/",
                        actualSequence.toString()
                    )
                );
    }

    /// @notice Returns the URI of the token
    /// @param dropId id of the drop to check supply on
    /// @return circulating number of minted tokens from drop
    /// @return max The maximum supply of tokens in the drop
    /// @return exists Whether the drop exists
    /// @return paused Whether the drop is paused
    function drops(uint128 dropId)
        public
        view
        returns (
            uint128 circulating,
            uint128 max,
            bool exists,
            bool paused
        )
    {
        QuantumSpacesStorage.Layout storage qs = QuantumSpacesStorage.layout();
        circulating = _mintedInDrop(dropId);
        max = qs.dropMaxSupply[dropId];
        exists = max != 0;
        paused = qs.isDropPaused.get(dropId);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  EXTERNAL  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Burns token
    /// @dev Can be called by the owner or approved operator
    /// @param tokenId id of the tokens
    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721QUpgradeable,
            ERC2981,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return
            ERC721QUpgradeable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  HOOKS  <<<<<<<<<<<<<<<<<<<<<< ///

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        QuantumSpacesStorage.Layout storage qs = QuantumSpacesStorage.layout();
        if (qs.isDropPaused.get(startTokenId.dropId()))
            revert DropPaused(startTokenId.dropId());
        require(!paused(), "Token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}