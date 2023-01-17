// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/utils/Counters.sol";
import "openzeppelin-contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "operator-filter-registry/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./Deployer.sol";

/**
 * @title ERC721Minter
 * @dev An upgradeable ERC721 contract.
 */
contract ERC721Minter is
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PaymentSplitterUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    using Counters for Counters.Counter;

    /**
     * @dev Event for airdrop
     */
    event Airdrop(uint256 length);

    /**
     * @dev Event for setting a new max supply
     */
    event SetMaxSupply(uint256 newMaxSupply);

    /**
     * @dev Event for setting a new max quantity
     */
    event SetMaxQuantity(uint256 newMaxQuantity);

    /**
     * @dev Event for setting a new price
     */
    event SetPrice(uint256 newPrice);

    /**
     * @dev Event for setting a new start time
     */
    event SetStartTime(uint256 newStartTime);

    /**
     * @dev Event for setting a new merkle root
     */
    event SetMerkleRoot(bytes32 newMerkleRoot);

    /**
     * @dev Event for setting a new base URI
     */
    event SetBaseUri(string newBaseUri);

    /**
     * @dev Event for setting a new contract URI
     */
    event SetContractURI(string newContractURI);

    /**
     * @notice The max number of tokens that can be minted.
     */
    uint256 public maxSupply;

    /**
     * @notice The max number of tokens that can be minted in a single transaction.
     */
    uint256 public maxQuantity;

    /**
     * @notice The price of each token.
     */
    uint256 public price;

    /**
     * @notice The earliest time that tokens can be minted.
     */
    uint256 public startTime;

    /**
     * @notice The merkle root of the allow-list.
     */
    bytes32 public merkleRoot;

    /**
     * @notice Whether or not tokens are transferable (immutable).
     */
    bool public transferable;

    /**
     * @notice The payees of the payment splitter.
     */
    address[] public minterPayees;

    /**
     *   @notice Reference to the contract that deployed this minter.
     */
    Deployer public deployer;

    /**
     * @dev Token ids counter.
     */
    Counters.Counter internal _tokenIds;

    /**
     * @dev Base URI for token metadata
     */
    string internal _baseURIExtended;

    /**
     * @dev Contract level metadata
     */
    string internal _contractURI;

    modifier onlyPrivilegedMintAddress() {
        require(
            deployer.privilegedMintAddresses(msg.sender),
            "Caller is not a privileged mint address."
        );
        _;
    }

    constructor() {
        // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract. Required for ugpradeable contracts.
     * @param deployerAddress_ The address of the contract that deployed this minter
     * @param name_ The ERC721 name
     * @param symbol_ The ERC721 symbol
     * @param baseUri_ The ERC721 metadata base URI
     * @param contractURI_ The contract level metadata URI
     * @param maxSupply_ The initial maxSupply
     * @param maxQuantity_ The initial maxQuantity
     * @param price_ The initial mint price
     * @param startTime_ The initial start time
     * @param merkleRoot_ The initial allow-list merkle root
     * @param transferable_ Whether or not tokens are transferable
     * @param payees_ The payee addresses
     * @param shares_ The shares per payee address
     */
    function initialize(
        address deployerAddress_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseUri_,
        string calldata contractURI_,
        uint256 maxSupply_,
        uint256 maxQuantity_,
        uint256 price_,
        uint256 startTime_,
        bytes32 merkleRoot_,
        bool transferable_,
        address[] calldata payees_,
        uint256[] calldata shares_
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init(name_, symbol_);
        __PaymentSplitter_init(payees_, shares_);
        __DefaultOperatorFilterer_init();

        deployer = Deployer(deployerAddress_);
        _baseURIExtended = baseUri_;
        _contractURI = contractURI_;
        maxSupply = maxSupply_;
        price = price_;
        startTime = startTime_;
        merkleRoot = merkleRoot_;
        transferable = transferable_;
        minterPayees = payees_;

        _validateMaxQuantity(maxQuantity_);
        maxQuantity = maxQuantity_;
    }

    /**
     * @notice Mints tokens to the caller.
     * @param merkleProof_ The merkle proof for the caller's address
     */
    function mintAllowList(bytes32[] calldata merkleProof_, uint256 quantity_)
        external
        payable
        virtual
        nonReentrant
    {
        _mintAllowList(msg.sender, merkleProof_, quantity_);
    }

    /**
     * @notice Mints tokens to the specified recipient.
     * @param to_ The recipient of the token.
     * @param merkleProof_ The merkle proof for the caller's address
     */
    function mintAllowListOnBehalfOf(
        address to_,
        bytes32[] calldata merkleProof_,
        uint256 quantity_
    ) external payable virtual nonReentrant onlyPrivilegedMintAddress {
        _mintAllowList(to_, merkleProof_, quantity_);
    }

    /**
     * @notice Mints tokens to the caller.
     */
    function mintPublic(uint256 quantity)
        external
        payable
        virtual
        nonReentrant
    {
        _mintPublic(msg.sender, quantity);
    }

    /**
     * @notice Mints tokens to the specified recipient.
     * @param to The recipient of the token.
     */
    function mintPublicOnBehalfOf(address to, uint256 quantity)
        external
        payable
        virtual
        nonReentrant
        onlyPrivilegedMintAddress
    {
        return _mintPublic(to, quantity);
    }

    /**
     * @notice Mints tokens to a set of addresses.
     * @param addresses The addresses to receive tokens
     */
    function airdrop(address[] calldata addresses)
        external
        virtual
        onlyOwner
        nonReentrant
    {
        require(
            _tokenIds.current() + addresses.length <= maxSupply,
            "Max supply reached."
        );

        for (uint256 i = 0; i < addresses.length; ) {
            _mintOne(addresses[i]);

            unchecked {
                i++;
            }
        }

        emit Airdrop(addresses.length);
    }

    /**
     * @notice Sets the max supply.
     * @param maxSupply_ The new max supply
     */
    function setMaxSupply(uint256 maxSupply_) external virtual onlyOwner {
        maxSupply = maxSupply_;
        emit SetMaxSupply(maxSupply_);
    }

    /**
     * @notice Sets the max quantity.
     * @param maxQuantity_ The new max quantity
     */
    function setMaxQuantity(uint256 maxQuantity_) external virtual onlyOwner {
        _validateMaxQuantity(maxQuantity_);

        maxQuantity = maxQuantity_;
        emit SetMaxQuantity(maxQuantity_);
    }

    /**
     * @notice Sets the mint price.
     * @param price_ The new price
     */
    function setPrice(uint256 price_) external virtual onlyOwner {
        price = price_;
        emit SetPrice(price_);
    }

    /**
     * @notice Sets the start time.
     * @param startTime_ The new start time
     */
    function setStartTime(uint256 startTime_) external virtual onlyOwner {
        startTime = startTime_;
        emit SetStartTime(startTime_);
    }

    /**
     * @notice Sets the merkle root.
     * @param merkleRoot_ The new merkle root
     */
    function setMerkleRoot(bytes32 merkleRoot_) external virtual onlyOwner {
        merkleRoot = merkleRoot_;
        emit SetMerkleRoot(merkleRoot_);
    }

    /**
     * @notice Sets the token base URI.
     * @param baseURI_ The new token base URI
     */
    function setBaseURI(string calldata baseURI_)
        external
        onlyOwner
        returns (string memory)
    {
        _baseURIExtended = baseURI_;
        emit SetBaseUri(baseURI_);
        return _baseURIExtended;
    }

    /**
     * @notice Sets the contract URI.
     * @param contractURI_ The new contract URI
     */
    function setContractURI(string calldata contractURI_)
        public
        virtual
        onlyOwner
    {
        _contractURI = contractURI_;
        emit SetContractURI(contractURI_);
    }

    /**
     * @notice Returns the contract metadata URI.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Returns a static URI for all tokens.
     * @param tokenId The token ID
     * @return The static URI
     * See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return _baseURI();
    }

    /**
     * @notice Returns the total supply of minted tokens.
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    /*
        OpenSea Operator Filter Registry overrides
    */

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
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

    /**
     * @dev Overrides the default _beforeTokenTransfer to check transferability.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Upgradeable) {
        require(
            transferable || from == address(0) || to == address(0),
            "Transfer not allowed"
        );

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev Overrides the default _setApprovalForAll to check transferability.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual override {
        require(transferable, "Approval not allowed");

        super._setApprovalForAll(owner, operator, approved);
    }

    function _mintPublic(address to, uint256 quantity) internal virtual {
        require(
            msg.value == price * quantity,
            "The price does not match the amount paid."
        );

        require(
            merkleRoot == 0x00,
            "Public mint not allowed. Merkle root is set."
        );

        require(
            block.timestamp >= startTime,
            "Public mint not allowed. Too early."
        );

        require(_tokenIds.current() < maxSupply, "Max supply reached.");

        _mintMany(to, quantity);
    }

    function _mintAllowList(
        address to_,
        bytes32[] calldata merkleProof_,
        uint256 quantity_
    ) internal virtual {
        require(
            msg.value == price * quantity_,
            "The price does not match the amount paid."
        );

        require(
            MerkleProof.verify(
                merkleProof_,
                merkleRoot,
                keccak256(abi.encodePacked(to_))
            ),
            "Allow list mint not allowed. Sender is not on allow list."
        );

        return _mintMany(to_, quantity_);
    }

    /**
     * @dev Mints a single token to the given address.
     * @param to The address that will own the minted token
     */
    function _mintOne(address to) internal virtual returns (uint256 tokenId) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(to, newItemId);
        return newItemId;
    }

    /**
     * @dev Mints multiple tokens to the given address.
     * @param to The address that will own the minted tokens
     * @param quantity The number of tokens to mint
     */
    function _mintMany(address to, uint256 quantity) internal virtual {
        require(quantity > 0, "Quantity must be greater than 0.");

        require(
            balanceOf(to) + quantity <= maxQuantity,
            "Balance exceeds max quantity."
        );

        require(
            _tokenIds.current() + quantity <= maxSupply,
            "Max supply reached."
        );

        for (uint256 i = 0; i < quantity; ) {
            _mintOne(to);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Overrides the default _baseURI to return the custom base URI.
     * @return The custom base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseURIExtended;
    }

    /**
     * @dev Ensures max quantity is a valid value.
     * @param maxQuantity_ The max quantity to validate
     */
    function _validateMaxQuantity(uint256 maxQuantity_) internal view {
        require(maxQuantity_ > 0, "Max quantity must be greater than 0.");

        require(
            maxQuantity_ <= maxSupply,
            "Max quantity must be less than or equal to max supply."
        );
    }
}