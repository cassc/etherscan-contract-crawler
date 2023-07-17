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
import "./IMintConstraintV1.sol";
import "./IMintConstraintFactoryV1.sol";

/**
 * @title Fuel Initializable implementation of ERC721 V2
 * @author https://www.onfuel.io
 * @dev this contract will not be deployed directly.
 * New clones shall be created through `UniqueCollectionCloneFactoryV2`.
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
 * - can call {setRoyaltyRecipient}
 * - can call {decreaseRoyaltyPercentage}
 * - can call {setBaseURI}
 * - can call {managerMint}
 * - can call {pause}
 * - can call {addMintPhase}
 * - can call {addMintPhaseWithNewConstraint}
 * - can call {replaceMintPhase}
 */
contract UniqueCollectionInitializableV2 is
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
     * @dev how many tokens can be minted in total.
     * {managerMint}, {allowListMint} and {publicMint} can only be called if
     * the total balance of all the token owners is less than maxSupply
     * see {tokensLeft} modifier.
     * Can not be changed after initialized
     */
    uint128 public maxSupply;

    /**
     * @dev how many tokens can be minted per address.
     * Can not be changed later.
     * Can not be changed after initialized
     */
    uint128 public maxMintPerAddress;

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
     * @dev how many tokens have been minted for one address in a given phase.
     * Is used to check if MintPhase.maxMintPerAddress has been exceeded.
     */
    mapping(address => mapping(uint256 => uint256)) public phaseMinted;

    mapping(uint256 => uint256) public totalPhaseMinted;

    MintPhase[] public mintPhases;

    /**
     * @dev `MANAGER_ROLE` this role can call all sensitive operations.
     * This role is given to the manager account in the initializer.
     * *WARNING* this role gives full control over all sensitive operations.
     * *WARNING* this role can NOT grant or revoke roles.
     */
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint256 public constant VERSION = 2;

    /**
     * @dev Emitted when a `manager` updated the baseURI through
     * a call to {setBaseURI}.
     * `baseURI` is a uri to the metadata of the NFT.
     */
    event BaseURIChanged(
        string baseURI
    );

    /**
     * @dev Emitted when a `manager` adds or replaces a MintPhase via
     * a call to {addMintPhase} or {replaceMintPhase}.
     * `index` the index in the mintPhases array.
     */
    event MintPhaseChanged(
        uint256 index,
        MintPhase mp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    /**
     * @notice Struct for initializing the `UniqueCollectionInitializableV2`.
     * @param _roleAdmin address of the account that will have `DEFAULT_ADMIN_ROLE`.
     * Can grant and revoke roles to other accounts on the new `UniqueCollectionInitializableV2`.
     * Can NOT mint, pause, ect. on the new `UniqueCollectionInitializableV2`.
     * @param _manager account that will have `MANAGER_ROLE` on the new UniqueCollectionV`.
     * Can call all sensitive operations ({managerMint} ect.)
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
     * {allowListMint}.
     */
    struct InitializeData {
        address roleAdmin;
        address manager;
        uint128 maxSupply;
        uint128 maxMintPerAddress;
        string name;
        string symbol;
        string baseURI;
        uint256 royaltyPercentage;
        address royaltyRecipient;
        MintPhase[] mintPhases;
    }

    /**
     * @param mintPrice eth price of one token to be payed by {allowListMint} and {publicMint}
     * @param maxMintPerAddress how many tokens can be minted per address trough
     * @param allowListMerkleRoot merke root hash of allowlist for {allowListMint}
     */
    struct MintPhase {
        uint128 startBlockHeight;
        uint128 endBlockHeight;
        uint128 maxMintInPhase;
        uint128 maxMintPerAddress;
        uint128 mintPrice;
        bytes32 allowListMerkleRoot;
        IMintConstraintV1 mintConstraint;
    }

    /**
     * @notice initialize the `UniqueCollectionInitializableV2`.
     * @dev clones of this contract are created by the `manager`
     * account of fuel-core through it's `UniqueCollectionCloneFactoryV2` contract
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
        for(uint256 i = 0; i < _init.mintPhases.length; i++) {
            _validateMintPhase(_init.mintPhases[i]);
            mintPhases.push(_init.mintPhases[i]);
        }
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
        uint256 _mintPhaseIndex,
        bytes32[] calldata _merkleProof
    ) {
        require(isProofValid(_mintPhaseIndex, _merkleProof, _msgSender()), "invalid proof");
        _;
    }

    modifier mintPhaseActive(
        uint256 _mintPhaseIndex
    ) {
        MintPhase memory mp = mintPhases[_mintPhaseIndex];
        require(
            block.number >= mp.startBlockHeight
            &&
            block.number < mp.endBlockHeight,
            "mintphase not active"
        );
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
     * @notice add a new MintPhase
     * @param mp the MintPhase to add
     */
    function addMintPhase(MintPhase memory mp)
        external
        onlyManager
    {
        _validateMintPhase(mp);
        mintPhases.push(mp);
        emit MintPhaseChanged(mintPhases.length -1, mp);
    }

    /**
    * @notice add a new MintPhase and creates a constraint on one call
    * @param mp the MintPhase to add
    * @param _constraintFactory the address of a IMintConstraintFactoryV1
    * @param _constraintInitData the init data for the new constraint
    */
    function addMintPhaseWithNewConstraint(
        MintPhase memory mp,
        address _constraintFactory,
        bytes memory _constraintInitData
    )
        external
        onlyManager
    {
        IMintConstraintFactoryV1 factory = IMintConstraintFactoryV1(_constraintFactory);
        require(
            factory.supportsInterface(type(IMintConstraintFactoryV1).interfaceId),
            "not IMintConstraintFactoryV1"
        );
        IMintConstraintV1 newConstraint = factory.createConstraint(_constraintInitData);
        require(
            newConstraint.supportsInterface(type(IMintConstraintV1).interfaceId),
            "not IMintConstraintV1"
        );
        mp.mintConstraint = newConstraint;
        _validateMintPhase(mp);
        mintPhases.push(mp);
        emit MintPhaseChanged(mintPhases.length -1, mp);
    }

    /**
     * @notice replace a new MintPhase at given index
     * @param _index the index in the mintPhases array to replace.
     * @param mp the new MintPhase to replace with
     */
    function replaceMintPhase(uint256 _index, MintPhase memory mp)
        external
        onlyManager
    {
        _validateMintPhase(mp);
        mintPhases[_index] = mp;
        emit MintPhaseChanged(_index, mp);
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
     */
    function allowListMint(
        uint256 _amount,
        uint256 _mintPhaseIndex,
        bytes32[] calldata _merkleProof,
        bytes calldata _data
    )
        external
        payable
        onlyProof(_mintPhaseIndex, _merkleProof)
        mintPhaseActive(_mintPhaseIndex)
        tokensLeft
        canStillMint(_msgSender(), _amount)
    {
        MintPhase memory mp = mintPhases[_mintPhaseIndex];
        _passMintConstraint(_amount, mp, _data);
        _phaseMint(_amount, _mintPhaseIndex, mp, _msgSender());
    }

    /**
     * @notice allows for minting tokens for mintPrice
     * if sale is active and public.
     * See {publicMintStartBlockHeight}
     */
    function publicMint(
        uint256 _amount,
        uint256 _mintPhaseIndex,
        bytes calldata _data
    )
        external
        payable
        mintPhaseActive(_mintPhaseIndex)
        tokensLeft
        canStillMint(_msgSender(), _amount)
    {
        MintPhase memory mp = mintPhases[_mintPhaseIndex];
        require(mp.allowListMerkleRoot == 0x00, "mint period is allowList");
        _passMintConstraint(_amount, mp, _data);
        _phaseMint(_amount, _mintPhaseIndex, mp, _msgSender());
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
    function totalSupply()
        public
        view
        // override
        returns (uint256)
    {
        return _tokenIdCounter.current() - 1;
    }

    /**
     * @return the amount of mintPhases
     */
    function mintPhasesLength() external view returns (uint256) {
        return mintPhases.length;
    }

    // Public view functions

    /**
     * @notice test if a _merkleProof is valid
     * @param _mintPhaseIndex the index of the mintPhase
     * @param _merkleProof the proof for this _sender
     * @param _sender the sender of this _merkleProof
     * @return isValid true if the proof is valid in
     * the context of the allowListMerkleRoot in storage
     */
    function isProofValid(
        uint256 _mintPhaseIndex,
        bytes32[] calldata _merkleProof,
        address _sender
    )
        public
        view
        returns (bool isValid)
    {
        isValid = MerkleProofUpgradeable.verify(
            _merkleProof,
            mintPhases[_mintPhaseIndex].allowListMerkleRoot,
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
        override(
            ERC721Upgradeable,
            RoyaltiesV1,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) || // super is RoyaltiesV1
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    // Internal functions

    /**
     * @notice mint tokens on public or allowList
     */
    function _phaseMint(
        uint256 _amount,
        uint256 _mintPhaseIndex,
        MintPhase memory _mp,
        address _to
    ) internal {
        require(msg.value >= _mp.mintPrice * _amount, "price too low");
        _canStillMintInPhase(_mintPhaseIndex, _mp, _to, _amount);
        minted[_to]+=_amount;
        phaseMinted[_to][_mintPhaseIndex]+=_amount;
        totalPhaseMinted[_mintPhaseIndex]+=_amount;
        uint256 i = 0;
        for(i; i < _amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(_to, tokenId);
        }
    }

    /**
     * @notice checks if a mintConstraint can pass
     */
    function _passMintConstraint(
        uint256 _amount,
        MintPhase memory mp,
        bytes memory _data
    ) internal {
        if(address(mp.mintConstraint) != address(0x00)) {
            require(
                mp.mintConstraint.canMint(_msgSender(), _amount, _data),
                "constraint not passed"
            );
        }
    }

    /**
     * @notice checks if a receiver has already reached the mint threshold
     * for this mintPeriod
     */
    function _canStillMintInPhase(
        uint256 _mintPhaseIndex,
        MintPhase memory mp,
        address to,
        uint256 amount
    )
        internal
        view
    {
        if(mp.maxMintInPhase> 0) {
            require(
                totalPhaseMinted[_mintPhaseIndex] + amount <= mp.maxMintInPhase,
                "totalPhaseMinted exceeded"
            );
        }
        if(mp.maxMintPerAddress > 0) {
            require(
                phaseMinted[to][_mintPhaseIndex] + amount <= mp.maxMintPerAddress,
                "already minted"
            );
        }
    }

    function _validateMintPhase(MintPhase memory mp)
        internal
        view
    {
        require(mp.endBlockHeight > mp.startBlockHeight, "start end block misconf");
        if(address(mp.mintConstraint) != address(0x00)) {
            require(
                IMintConstraintV1(mp.mintConstraint).supportsInterface(
                    type(IMintConstraintV1).interfaceId
                ),
                "not IMintConstraintV1"
            );
        }
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