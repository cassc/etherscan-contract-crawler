// SPDX-License-Identifier: Apache 2.0
//TODO: ensure that direct mints start at tokenID 10001
pragma solidity ^0.8.4;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@thirdweb-dev/contracts/feature/interface/IOwnable.sol";
import "@thirdweb-dev/contracts/lib/MerkleProof.sol";

//  ==========  Internal imports    ==========

import "../interfaces/IAllowlist.sol";
import "../interfaces/IConfig.sol";
import "../interfaces/IPropsContract.sol";
import "../interfaces/IPropsAccessRegistry.sol";
import "../interfaces/IRedeemableContract.sol";
import "../interfaces/IERC20StakingToken.sol";

import {DefaultOperatorFiltererUpgradeable} from "./opensea/DefaultOperatorFiltererUpgradeable.sol";

import "hardhat/console.sol";

contract PropsERC721Community is
    Initializable,
    IOwnable,
    IAllowlist,
    IConfig,
    IPropsContract,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721HolderUpgradeable,
    ERC2981
{
    using StringsUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using ECDSAUpgradeable for bytes32;

    //////////////////////////////////////////////
    // State Vars
    /////////////////////////////////////////////

    bytes32 private constant MODULE_TYPE = bytes32("PropsERC721Community");
    uint256 private constant VERSION = 1;

    uint256 private nextTokenId;
    mapping(address => uint256) public minted;
    mapping(address => mapping(uint256 => uint256)) public mintedByAllowlist;
    mapping(uint256 => uint256) public migratedByToken;

    bytes32 private constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 private constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");

    // @dev reserving space for  more roles
    bytes32[7] private __gap;

    string private baseURI_;
    string public contractURI;
    address private _owner;
    address private accessRegistry;
    address public project;
    address public receivingWallet;
    address public rWallet;
    address public stakingERC20Address;
    address public parentHolderContract;
    address[] private trustedForwarders;

    bool public migrationEnabled;
    bool public isSoulBound;
    bool public stakingEnabled;

    Allowlists public allowlists;
    Config public config;

    //////////////////////////////////////////////
    // Errors
    /////////////////////////////////////////////

    error AllowlistInactive();
    error MintQuantityInvalid();
    error MerkleProofInvalid();
    error MintClosed();
    error MintZeroQuantity();
    error InsufficientFunds();

    //////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////

    event Minted(address indexed account, string tokens);
    event Migrated(address indexed account, string tokens);
    event Upgraded(address indexed account, string tokens);

    //////////////////////////////////////////////
    // Init
    /////////////////////////////////////////////

    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address[] memory _trustedForwarders,
        address _receivingWallet,
        address _accessRegistry
    ) public initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);
        __ERC721_init(_name, _symbol);
        __DefaultOperatorFilterer_init();

        receivingWallet = _receivingWallet;
        _owner = _defaultAdmin;
        accessRegistry = _accessRegistry;
        baseURI_ = _baseURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PRODUCER_ROLE, CONTRACT_ADMIN_ROLE);

        nextTokenId = 1001;

        // add default admin entry to registry
        //IPropsAccessRegistry(accessRegistry).add(_defaultAdmin, address(this));
    }

    /*///////////////////////////////////////////////////////////////
                      Generic contract logic
  //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /*///////////////////////////////////////////////////////////////
                      ERC 165 / 721 logic
  //////////////////////////////////////////////////////////////*/

    /**
     * @dev see {IERC721Metadata}
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI_, _tokenId.toString(), ".json"));
    }

    /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlEnumerableUpgradeable,
            ERC721EnumerableUpgradeable,
            ERC2981
        )
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    function airdrop(address _to, uint256[] calldata _tokenIds)
        external
       {
        require(hasMinRole(PRODUCER_ROLE), "Not authorized");
        string memory tokensMinted = "";
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _mint(_to, _tokenIds[i]);
             tokensMinted = string(
                abi.encodePacked(
                    tokensMinted,
                    _tokenIds[i].toString(),
                    ","
                )
            );
        }
        emit Minted(_to, tokensMinted);
        
    }

    function migrate(
        uint256 tokenID
    ) public nonReentrant {
        require(!paused(), "Paused");
        require(migrationEnabled, "Migration not enabled");
        require(migratedByToken[tokenID] < 1, "Already migrated");
            console.log("parentHolderContract", parentHolderContract);
            require(
                IERC721(parentHolderContract).ownerOf(tokenID) == _msgSender(),
                "User Unauthorized"
            );

            if(!isSoulBound){
                ERC721Burnable(parentHolderContract).burn(tokenID);
            }

            migratedByToken[tokenID] = 1;
            _safeMint(_msgSender(), tokenID);
            emit Migrated(
                _msgSender(),
                string(
                    abi.encodePacked(
                        tokenID.toString()
                    )
                )
            );
    } 

    function mint(
        uint256[] calldata _quantities,
        bytes32[][] calldata _proofs,
        uint256[] calldata _allotments,
        uint256[] calldata _allowlistIds
    ) external payable nonReentrant {
        require(isUniqueArray(_allowlistIds), "boo");
        uint256 _cost = 0;
        uint256 _quantity = 0;

        for (uint256 i = 0; i < _quantities.length; i++) {
            _quantity += _quantities[i];

            revertOnInactiveList(_allowlistIds[i]);
            revertOnAllocationCheckFailure(
                _msgSender(),
                _allowlistIds[i],
                mintedByAllowlist[_msgSender()][_allowlistIds[i]],
                _quantities[i],
                _allotments[i],
                _proofs[i]
            );
            _cost += allowlists.lists[_allowlistIds[i]].price * _quantities[i];
        }

        require(
            nextTokenId + _quantity - 1 <= config.mintConfig.maxSupply,
            "Exceeded max supply."
        );

        if (_cost > msg.value) revert InsufficientFunds();
        payable(receivingWallet).transfer(msg.value);

        string memory tokensMinted = "";
        unchecked {
            for (uint256 i = 0; i < _quantities.length; i++) {
                mintedByAllowlist[address(_msgSender())][
                    _allowlistIds[i]
                ] += _quantities[i];
                for (uint256 j = 0; j < _quantities[i]; j++) {
                    tokensMinted = string(
                        abi.encodePacked(
                            tokensMinted,
                            nextTokenId.toString(),
                            ","
                        )
                    );

                    _safeMint(_msgSender(), nextTokenId);
                    nextTokenId++;
                }
            }
        }
        emit Minted(_msgSender(), tokensMinted);
    }

    function revertOnInactiveList(uint256 _allowlistId) internal view {
        if (
            paused() ||
            block.timestamp < allowlists.lists[_allowlistId].startTime ||
            block.timestamp > allowlists.lists[_allowlistId].endTime ||
            !allowlists.lists[_allowlistId].isActive
        ) revert AllowlistInactive();
    }

    // @dev +~0.695kb
    function revertOnAllocationCheckFailure(
        address _address,
        uint256 _allowlistId,
        uint256 _minted,
        uint256 _quantity,
        uint256 _alloted,
        bytes32[] calldata _proof
    ) internal view {
        if (_quantity == 0) revert MintZeroQuantity();
        Allowlist storage allowlist = allowlists.lists[_allowlistId];
        if (_quantity + _minted > allowlist.maxMintPerWallet)
            revert MintQuantityInvalid();
        if (allowlist.typedata != bytes32(0)) {
            if (_quantity > _alloted || ((_quantity + _minted) > _alloted))
                revert MintQuantityInvalid();
            (bool validMerkleProof, ) = MerkleProof.verify(
                _proof,
                allowlist.typedata,
                keccak256(abi.encodePacked(_address, _alloted))
            );
            if (!validMerkleProof) revert MerkleProofInvalid();
        }
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                      Allowlist Logic
  //////////////////////////////////////////////////////////////*/

    function setAllowlists(Allowlist[] calldata _allowlists)
        external
       {
        require(hasMinRole(PRODUCER_ROLE), "Not authorized");
        allowlists.count = _allowlists.length;
        for (uint256 i = 0; i < _allowlists.length; i++) {
            allowlists.lists[i] = _allowlists[i];
        }
    }

    function updateAllowlistByIndex(Allowlist calldata _allowlist, uint256 i)
        external
       {
        require(hasMinRole(PRODUCER_ROLE), "Not authorized");
        allowlists.lists[i] = _allowlist;
    }

    function addAllowlist(Allowlist calldata _allowlist)
        external
       {
        require(hasMinRole(PRODUCER_ROLE), "Not authorized");
        allowlists.lists[allowlists.count] = _allowlist;
        allowlists.count++;
    }

    /*///////////////////////////////////////////////////////////////
                      Getters
  //////////////////////////////////////////////////////////////*/

    /// @dev Returns the allowlist at the given uid.
    function getAllowlistById(uint256 _allowlistId)
        external
        view
        returns (Allowlist memory allowlist)
    {
        allowlist = allowlists.lists[_allowlistId];
    }

    /// @dev Returns the number of minted tokens for sender by allowlist.
    function getMintedByAllowlist(uint256 _allowlistId)
        external
        view
        returns (uint256 minted_)
    {
        minted_ = mintedByAllowlist[_msgSender()][_allowlistId];
    }

    /*///////////////////////////////////////////////////////////////
                      Setters
  //////////////////////////////////////////////////////////////*/

   function setMigrationEnabled(bool _isEnabled, bool _isSoulBound) external {
        require(hasMinRole(CONTRACT_ADMIN_ROLE), "Not authorized");
        migrationEnabled = _isEnabled;
        isSoulBound = _isSoulBound;
    }

    function setNextId(uint256 _id) external {
        require(hasMinRole(CONTRACT_ADMIN_ROLE), "Not authorized");
        nextTokenId = _id;
    }

    function setRoyalty(uint96 _royalty) external {
        require(hasMinRole(PRODUCER_ROLE), "Not authorized");
        _setDefaultRoyalty(rWallet, _royalty);
    }

    function setReceivingWallet(address _address)
      external
      {
        require(hasMinRole(CONTRACT_ADMIN_ROLE), "Not authorized");
        receivingWallet = _address;
    }

     function setRoyaltyWallet(address _address)
      external
      {
        require(hasMinRole(CONTRACT_ADMIN_ROLE), "Not authorized");
        rWallet = _address;
    }

    function setParentHolderContract(address _address)
        external
        {
        require(hasMinRole(CONTRACT_ADMIN_ROLE), "Not authorized");
        parentHolderContract = _address;
    }

     function setStakingERC20Contract(address _address, bool _isEnabled)
        external
        {
        require(hasMinRole(CONTRACT_ADMIN_ROLE), "Not authorized");
        stakingERC20Address = _address;
        stakingEnabled = _isEnabled;
    }


    function setInternals(
        address _receivingWallet,
        address _rWallet,
        address _stakingERC20Address,
        address _parentHolderContract
    ) external {
        require(hasMinRole(CONTRACT_ADMIN_ROLE), "Not authorized");
        receivingWallet = _receivingWallet;
        rWallet = _rWallet;
        stakingERC20Address = _stakingERC20Address;
        parentHolderContract = _parentHolderContract;
    }

    function setConfig(Config calldata _config)
        external
       {
        require(hasMinRole(PRODUCER_ROLE), "Not authorized");
        config = _config;
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "!ADMIN");
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri)
        external
        {
        require(hasMinRole(CONTRACT_ADMIN_ROLE), "Not authorized");
        contractURI = _uri;
    }

    /// @dev Lets a contract admin set the URI for the baseURI.
    function setBaseURI(string calldata _baseURI)
        external
        {
        require(hasMinRole(CONTRACT_ADMIN_ROLE), "Not authorized");
        baseURI_ = _baseURI;
    }

    /// @dev Lets a contract admin set the address for the access registry.
    function setAccessRegistry(address _accessRegistry)
        external
        {
        require(hasMinRole(CONTRACT_ADMIN_ROLE), "Not authorized");
        accessRegistry = _accessRegistry;
    }

    /// @dev Lets a contract admin set the address for the parent project.
    function setProject(address _project) external {
        require(hasMinRole(PRODUCER_ROLE), "Not authorized");
        project = _project;
    }

    /*///////////////////////////////////////////////////////////////
                      Miscellaneous / Overrides
  //////////////////////////////////////////////////////////////*/

    function togglePause(bool _isPaused) external{
        require(hasMinRole(CONTRACT_ADMIN_ROLE), "Not authorized");
        _isPaused ? _pause() : _unpause();
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
        {
        require(hasMinRole(CONTRACT_ADMIN_ROLE), "Not authorized");
        if (!hasRole(role, account)) {
            super._grantRole(role, account);
            IPropsAccessRegistry(accessRegistry).add(account, address(this));
        }
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
        {
        require(hasMinRole(CONTRACT_ADMIN_ROLE), "Not authorized");
        if (hasRole(role, account)) {
            // @dev ya'll can't take your own admin role, fool.
            if (role == DEFAULT_ADMIN_ROLE && account == owner()) revert();
            // #TODO check if it still adds roles (enumerable)!
            super._revokeRole(role, account);
            IPropsAccessRegistry(accessRegistry).remove(account, address(this));
        }
    }

    function isUniqueArray(uint256[] calldata _array)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _array.length; i++) {
            for (uint256 j = 0; j < _array.length; j++) {
                if (_array[i] == _array[j] && i != j) return false;
            }
        }
        return true;
    }

    function hasMinRole(bytes32 _role) public view virtual returns (bool) {
        return _hasMinRole(_role);
    }

    function _hasMinRole(bytes32 _role) internal view returns (bool) {
        // @dev does account have role?
        if (hasRole(_role, _msgSender())) return true;
        // @dev are we checking against default admin?
        if (_role == DEFAULT_ADMIN_ROLE) return false;
        // @dev walk up tree to check if user has role admin role
        return _hasMinRole(getRoleAdmin(_role));
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    uint256[49] private ___gap;
}