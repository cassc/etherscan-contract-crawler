// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./UniqueCollectionRoyaltiesV1.sol";

/**
 * @title Fuel Initializable implementation of ERC721
 * @author https://www.onfuel.io
 * @dev this contract will not be deployed directly.
 * New clones shall be created through `UniqueCollectionCloneFactoryV1`.
 * @dev this contract is designed to be controllable through
 * 2 accounts and 2 roles. Accounts are granted roles in the initializer.
 * `roleAdmin` has authority to grant and revoke roles
 * later on.
 *
 * Accounts:
 *
 * `roleAdmin`
 *  - has `DEFAULT_ADMIN_ROLE`.
 *  - Should be with a TimelockController controlled by a Gnosis Safe.
 *
 * `manager`
 * - has `MANAGER_ROLE`.
 * - is the fuel-core plattform by default.
 *
 * Roles:
 *
 * `DEFAULT_ADMIN_ROLE`
 * - attached to `roleAdmin`
 * - can {grantRole} and {revoveRole} for all roles and accounts
 * - can call {unpause}
 * - can call {withdrawNativeTokens}
 * - can call {recoverERC20}
 *
 * `MANAGER_ROLE`
 * - attached to `manager`
 * - can call {toggleSaleState}
 * - can call {setAllowListMintEndBlockHeight}
 * - can call {setPublicMintStartBlockHeight}
 * - can call {setSaleStateAndBlockHeights}
 * - can call {setRoyaltyRecipient}
 * - can call {decreaseRoyaltyPercentage}
 * - can call {setBaseURI}
 * - can call {managerMint}
 * - can call {pause}
 */
contract UniqueCollectionInitializableV1 is
    Initializable,
    ERC721Upgradeable,
    UniqueCollectionRoyaltiesV1,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20 for IERC20;
    /**
     * @dev counter for tokenIds, should start with 1 and increment
     * after every mint
     */
    CountersUpgradeable.Counter private _tokenIdCounter;

    /**
    * @dev the block.number until {allowListMint} can be called
    * to mint tokens with a mekle proof and ETH/MATIC.
    *
    * N >  block.number  -> allowListMint is enabled
    * N <= block.number  -> allowListMint is disabled
    */
    uint128 public allowListMintEndBlockHeight;

    /**
    * @dev the block.number at which the {publicMint} can be called
    * to buy tokens with ETH/MATIC.
    *
    * N == 0            -> {publicMint} is disabled
    * N >  block.number -> {publicMint} will enable the future
    * N <= block.number -> {publicMint} is enabled
    */
    uint128 public publicMintStartBlockHeight;

    /**
     * @dev following 5 storage vars should be packed in to one slot
     */

    /**
     * @dev true if sale is active. See modifier {isSaleActive}
     * {managerMint}, {allowListMint} and {publicMint} can only be called if
     * this is set to true.
     */
    bool public saleActive;

    /**
     * @dev how many tokens can be minted in total.
     * {managerMint}, {allowListMint} and {publicMint} can only be called if
     * the total balance of all the token owners is less than maxSupply
     * see {tokensLeft} modifier.
     * Can not be changed after initialized
     */
    uint64 public maxSupply;

    /**
     * @dev how many tokens can be minted per address.
     * Can not be changed later.
     * Can not be changed after initialized
     */
    uint56 public maxMintPerAddress;

    /**
     * @dev the native token (ETH/MATIC) price for
     * minting with {allowListMint} and {publicMint} in WEI.
     * {allowListMint} and {publicMint} can only be called
     * msg.value is higher than mintPrice.
     * max is 5,192,296,858,534,827 ETH
     */
    uint112 public mintPrice;

    /**
     * @dev how many tokens can be minted per address during allowListMint.
     * 0 means no limit, limit of maxMintPerAddress is enforeced though.
     * period.
     * Can not be changed after initialized.
     */
    uint16 public maxAllowListMintPerAddress;

    /**
     * @dev baseURI for token metadata
     * Can not be changed after initialized through {setBaseURI}
     */
    string public _extendedBaseURI;

    /**
     * @dev how many tokens have been minted for one address.
     * Is used to check if maxMintPerAddress has been exceeded.
     */
    mapping(address => uint256) public minted;

    /**
     * @dev merkle tree root hash for {allowListMint}
     * Can not be changed after initialized.
     */
    bytes32 public allowListMerkleRoot;


    /**
     * @dev `MANAGER_ROLE` this role can call all sensitive operations.
     * This role is given to the manager account in the initializer.
     * *WARNING* this role gives full control over all sensitive operations.
     * *WARNING* this role can NOT grant or revoke roles.
     */
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");


    /**
     * @dev Emitted when a `manager` activates or deactivates the sale
     * of the NFTs through a call to {toggleSaleState} or {setSaleStateAndBlockHeights}
     * `active` is a bool indicating if the sale is active (true).
     */
    event SaleStatusChanged(
        bool active
    );

    /**
     * @dev Emitted when a `manager` changes the allowListMintEndBlockHeight
     * through a call to {toggleSaleState} or {setAllowListMintEndBlockHeight}.
     */
    event AllowListMintEndBlockHeightChanged(
        uint128 allowListMintEndBlockHeight
    );

    /**
     * @dev Emitted when a `manager` changes the publicMintStartBlockHeight
     * through a call to {toggleSaleState} or {setPublicMintStartBlockHeight}.
     */
    event PublicMintStartBlockHeightChanged(
        uint128 publicMintStartBlockHeight
    );

    /**
     * @dev Emitted when a `manager` updated the baseURI through
     * a call to {setBaseURI}.
     * `baseURI` is a uri to the metadata of the NFT.
     */
    event BaseURIChanged(
        string baseURI
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    /**
     * @notice Struct for initializing the `UniqueCollectionInitializableV1`.
     * @param _roleAdmin address of the account that will have `DEFAULT_ADMIN_ROLE`.
     * Can grant and revoke roles to other accounts on the new `UniqueCollectionInitializableV1`.
     * Can NOT mint, pause, ect. on the new `UniqueCollectionInitializableV1`.
     * @param _manager account that will have `MANAGER_ROLE` on the new UniqueCollectionV`.
     * Can call all sensitive operations ({managerMint}, {toggleSaleState}...).
     * Must be given to a account that the fuel-core controls in order to
     * mint on behelve of the arist.
     * @param _maxSupply the maximum amount of tokens that can be minted.
     * Can not be changed later on.
     * @param _name name of the Token (e. g. 'Jane's Awsome Collection').
     * Can not be changed later on.
     * @param _symbol symbol of the Token (e.g. 'JAC').
     * Can not be changed later on.
     * @param baseURI the metadata base uri of the tokens
     * Can be changed later on.
     * @param royaltyPercentage royalties to be payed in percent (10000 = 100%)
     * @param royaltyRecipient the account to receive the royalties
     * @param mintPrice eth price of one token to be payed by {allowListMint} and {publicMint}
     * @param maxAllowListMintPerAddress how many tokens can be minted per address trough
     * @param allowListMerkleRoot merke root hash of allowlist for {allowListMint}
     * {allowListMint}.
     */
    struct InitializeData {
        address roleAdmin;
        address manager;
        uint64 maxSupply;
        uint56 maxMintPerAddress;
        string name;
        string symbol;
        string baseURI;
        uint256 royaltyPercentage;
        address royaltyRecipient;
        uint112 mintPrice;
        uint16 maxAllowListMintPerAddress;
        bytes32 allowListMerkleRoot;
    }

    /**
     * @notice initialize the `UniqueCollectionInitializableV1`.
     * @dev clones of this contract are created by the `manager`
     * account of fuel-core through it's `UniqueCollectionCloneFactoryV1` contract
     * and are not meant to be created directly through an individual deployment.
     */
    function initialize(
       InitializeData calldata _init
    ) public initializer {
        require(_init.roleAdmin != address(0), "RoleAdmin is address(0)");
        require(_init.manager != address(0), "Manager is address(0)");
        require(_init.maxSupply > 0, "maxSupply must be greater than 0");

        __ERC721_init(_init.name, _init.symbol);
        __Pausable_init();
        __AccessControl_init();
        // we are not calling __Ownable_init()
        // because we don't want msg.sender to be the owner.
        // we will call _transferOwnership later.

        maxSupply = _init.maxSupply;
        maxMintPerAddress = _init.maxMintPerAddress;
        allowListMerkleRoot = _init.allowListMerkleRoot;
        maxAllowListMintPerAddress = _init.maxAllowListMintPerAddress;
        mintPrice = _init.mintPrice;
        _tokenIdCounter.increment(); // Ensure we start from ID 1
        _extendedBaseURI = _init.baseURI;
        _grantRole(DEFAULT_ADMIN_ROLE, _init.roleAdmin);
        _grantRole(MANAGER_ROLE, _init.manager);
        _setTokenRoyalty(_init.royaltyPercentage, _init.royaltyRecipient);
        _transferOwnership(_init.manager);
    }


    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not manager");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        _;
    }

    modifier onlyProof(
        bytes32[] calldata _merkleProof
    ) {
        require(isProofValid(_merkleProof, _msgSender()), "invalid proof");
        _;
    }


    modifier isSaleActive() {
        require (saleActive, "Sale is not active");
        _;
    }

    modifier tokensLeft() {
        require(_tokenIdCounter.current() <= maxSupply, "Purchase would exceed max tokens");
        _;
    }


    modifier canStillMint(address to, uint256 amount) {
        if (maxMintPerAddress > 0) {
            require(
                minted[to] + amount <= maxMintPerAddress,
                "maxMintPerAddress exceeded"
            );
        }
        _;
    }

    // External functions

    /**
     * @notice publish the `UniqueCollectionInitializableV1` as active for sale.
     * only after this function has been called with parameter `true` a
     * mint can be successful.
     * @param _saleActive bool of the new state. `true` means on sale.
     */
    function toggleSaleState(
        bool _saleActive
    ) external onlyManager {
        saleActive = _saleActive;
        emit SaleStatusChanged(_saleActive);
    }

    /**
     * @notice see {_setAllowListMintEndBlockHeight}
     */
    function setAllowListMintEndBlockHeight(
        uint128 _allowListMintEndBlockHeight
    ) external onlyManager {
        _setAllowListMintEndBlockHeight(_allowListMintEndBlockHeight);
    }

    /**
     * @notice see {_setPublicMintStartBlockHeight}
     */
    function setPublicMintStartBlockHeight(
        uint128 _publicMintStartBlockHeight
    ) external onlyManager {
        _setPublicMintStartBlockHeight(_publicMintStartBlockHeight);
    }

    /**
     * @notice combine {toggleSaleState}, {setAllowListMintEndBlockHeight}
     * & {setPublicMintStartBlockHeight} in one call.
     */
    function setSaleStateAndBlockHeights(
        bool _saleActive,
        uint128 _allowListMintEndBlockHeight,
        uint128 _publicMintStartBlockHeight
    ) external onlyManager {
        saleActive = _saleActive;
        _setAllowListMintEndBlockHeight(_allowListMintEndBlockHeight);
        _setPublicMintStartBlockHeight(_publicMintStartBlockHeight);
        emit SaleStatusChanged(_saleActive);
    }
    /**
     * @notice sets the baseURI of the token metadata.
     * @param _newBaseURI uri of the baseURI, should be on ipfs
     */
    function setBaseURI(string memory _newBaseURI) external onlyManager {
        _extendedBaseURI = _newBaseURI;
        emit BaseURIChanged(_newBaseURI);
    }

    /**
     * @notice sets a new recepient of royalties.
     * @param _recipient address of recepient or the royalties
     */
    function setRoyaltyRecipient(address _recipient) external onlyManager {
        _setTokenRoyaltyRecipient(_recipient);
    }

    /**
     * @notice decreases the royalties
     * @param _royaltyPercentage royalties to be payed in percent (10000 = 100%)
     */
    function decreaseRoyaltyPercentage(uint256 _royaltyPercentage) external onlyManager {
        require(_royaltyPercentage < royaltyPercentage, "royaltyPercentage not lower");
        _setTokenRoyaltyPercentage(_royaltyPercentage);
    }


    /**
     * @notice Mint tokens on behalve of the creator
     * @dev caller needs to have `MANAGER_ROLE` which is given by
     * default to the `manager` account specified in the constructor.
     * @dev caller should be the fuel-core backend which mint's tokens
     * on behalve of a buyer in order to purchase tokens without native
     * network tokens (ETH/MATIC ect.)
     * @dev tokenId is auto incremented.
     * @dev avoids minting tokens to contracts that can not recover them
     * through use of the _safeMint internal function.
     * @param to address of the receiver of the newly minted token
     */
    function managerMint(address to)
        external
        isSaleActive
        tokensLeft
        canStillMint(to, 1)
        onlyManager
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        minted[to]+=1;
        _safeMint(to, tokenId);
    }

    /**
     * @notice allows for minting tokens for mintPrice
     * if allowListMint is enabled and user provides a valid
     * mekle proof.
     * See {allowListMintEndBlockHeight}
     */
    function allowListMint(bytes32[] calldata _merkleProof)
        external
        payable
        onlyProof(_merkleProof)
        isSaleActive
        tokensLeft
        canStillMint(_msgSender(), 1)
    {
        require(
            block.number < allowListMintEndBlockHeight,
            "not allowList sale"
        );
        if(maxAllowListMintPerAddress > 0) {
            require(
                minted[_msgSender()] < maxAllowListMintPerAddress,
                "already minted"
            );
        }
        require(msg.value >= mintPrice, "price too low");
        minted[_msgSender()]+=1;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    /**
     * @notice allows for minting tokens for mintPrice
     * if sale is active and public.
     * See {publicMintStartBlockHeight}
     */
    function publicMint()
        external
        payable
        isSaleActive
        tokensLeft
        canStillMint(_msgSender(), 1)
    {
        require(
            publicMintStartBlockHeight > 0
            &&
            block.number >= publicMintStartBlockHeight,
            "not public sale"
        );
        require(msg.value >= mintPrice, "price too low");
        minted[_msgSender()]+=1;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }


    /**
     * @notice pause the contract for all transfers
     */
    function pause() external onlyManager {
        _pause();
    }

    /**
     * @notice unpause the contract for all transfers
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /**
     * @notice roleAdmin can withdraw
     * @param _to address of receiver of the tokens
     */
    function withdrawNativeTokens(
        address payable _to
    ) external onlyAdmin {
        require(_to != address(0), "invalid withdraw receiver");
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @notice allows roleAdmin to recover tokens that have accidentally
     * @param _tokenAddress contract address of the ERC20 token that
     * one intends to recover
     * @param _receiver address of account that shall receiver the tokens
     * @param _tokenAmount amount tokens that shall be sent to the receiver
     */
    function recoverERC20(
        address _tokenAddress,
        address _receiver,
        uint256 _tokenAmount
    ) external onlyAdmin {
        IERC20(_tokenAddress).safeTransfer(_receiver, _tokenAmount);
    }

    // External view functions

    /**
     * @notice tells how many tokens have been minted
     * @return amount of tokens that have been minted so far
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }


    // Public view functions

    /**
     * @notice test if a _merkleProof is valid
     * @param _merkleProof the proof for this _sender
     * @param _sender the sender of this _merkleProof
     * @return isValid true if the proof is valid in
     * the context of the allowListMerkleRoot in storage
     */
    function isProofValid(
        bytes32[] calldata _merkleProof,
        address _sender
    )
        public
        view
        returns (bool isValid)
    {
        isValid = MerkleProofUpgradeable.verify(
            _merkleProof,
            allowListMerkleRoot,
            keccak256(abi.encodePacked(_sender))
        );
    }

    /**
     * @notice informs external contracts about supported Interfaces
     * @param interfaceId the id of the interface in question
     * @return true if the interfaceId is supported
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, RoyaltiesV1, AccessControlUpgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) || // super is RoyaltiesV1
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }


    // Internal functions


    /**
     * @notice setter for allowListMintEndBlockHeight
     * @param _allowListMintEndBlockHeight the block height at which
     * {allowListMint} will become disabled
     */
    function _setAllowListMintEndBlockHeight(
        uint128 _allowListMintEndBlockHeight
    ) internal {
        allowListMintEndBlockHeight = _allowListMintEndBlockHeight;
        emit AllowListMintEndBlockHeightChanged(_allowListMintEndBlockHeight);
    }

    /**
     * @notice setter for publicMintStartBlockHeight
     * @param _publicMintStartBlockHeight the block.number at which
     * {publicMint} will become enabled. 0 means disabled.
     */
    function _setPublicMintStartBlockHeight(
        uint128 _publicMintStartBlockHeight
    ) internal {
        publicMintStartBlockHeight = _publicMintStartBlockHeight;
        emit PublicMintStartBlockHeightChanged(_publicMintStartBlockHeight);
    }


    /**
     * @notice Hook to control transfer behaviour
     * @dev The following function override required by Pausable
     * @dev this is a hook that is called by all transfer functions
     * @dev prevents transfers when paused
     * @param from address of token sender
     * @param to address of token receiver
     * @param tokenId the ID of the token to be sent
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    // Internal view functions

    /**
     * @notice get the baseURI for NFT metadata
     * @return the base uri of the metadata
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _extendedBaseURI;
    }
}