// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.4;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@thirdweb-dev/contracts/feature/interface/IOwnable.sol";
import "@thirdweb-dev/contracts/lib/MerkleProof.sol";

//  ==========  Internal imports    ==========

import "../interfaces/IAllowlist.sol";
import "../interfaces/IConfig.sol";
import "../interfaces/IPropsContract.sol";


import {DefaultOperatorFiltererUpgradeable} from "./opensea/DefaultOperatorFiltererUpgradeable.sol";

interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

contract PropsERC721UConfigPools is
    Initializable,
    IOwnable,
    IAllowlist,
    IConfig,
    IPropsContract,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC2981,
    DefaultOperatorFiltererUpgradeable
{
    using StringsUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using ECDSAUpgradeable for bytes32;

    //////////////////////////////////////////////
    // State Vars
    /////////////////////////////////////////////

    bytes32 private constant MODULE_TYPE = bytes32("PropsERC721UConfigPools");
    uint256 private constant VERSION = 2;

    mapping(address => uint256) public minted;
    mapping(address => mapping(uint256 => uint256)) public mintedByAllowlist;
    mapping(uint256 => uint256) public totalMintedByAllowlist;
    mapping(string => uint256) public configSupplyLimit;
    mapping(string => uint256) public mintedByConfig;
    mapping(string => uint256) public priceByConfig;


    bytes32 private constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 private constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");
    // @dev reserving space for  more roles
    bytes32[32] private __gap;

    string private baseURI_;
    string public contractURI;
    address private _owner;
    address public project;
    address public receivingWallet;
    address public rWallet;
    address public SANCTIONS_CONTRACT;
    address[] private trustedForwarders;
    uint256 private nextTokenId;


    Allowlists public allowlists;
    Config public config;

    //////////////////////////////////////////////
    // Errors
    /////////////////////////////////////////////

    error AllowlistInactive();
    error AllowlistSupplyExhausted();
    error MintQuantityInvalid();
    error MerkleProofInvalid();
    error MintClosed();
    error MintZeroQuantity();
    error InsufficientFunds();

    //////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////
    event Minted(address account, string tokens);

    //////////////////////////////////////////////
    // Init
    /////////////////////////////////////////////

    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address[] memory _trustedForwarders,
        address _receivingWallet
    ) public initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);
        __ERC721_init(_name, _symbol);

        receivingWallet = _receivingWallet;
        _owner = _defaultAdmin;
        baseURI_ = _baseURI;
        nextTokenId = 1;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PRODUCER_ROLE, CONTRACT_ADMIN_ROLE);
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
            "no token"
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
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    struct MintCart{
        uint256 _cost;
        uint256 _quantity;
        string _tokensMinted;
        uint256 _scratch;
    }

    function calculateCost(
        uint256[] calldata _quantities,
        uint256[] calldata _allowlistIds,
        string[][] calldata _config
    ) public view returns(uint256){
        MintCart memory cart;

        for (uint256 i = 0; i < _quantities.length; i++) {
            cart._scratch = 0;
            cart._quantity += _quantities[i];

            for (uint256 c = 0; c < _config[i].length; c++) {
                if(priceByConfig[_config[i][c]] > 0){
                    cart._scratch = Math.max(cart._scratch, priceByConfig[_config[i][c]]);
                }
            }
        
            cart._cost += cart._scratch > 0 ? cart._scratch * _quantities[i] : allowlists.lists[_allowlistIds[i]].price * _quantities[i];
        }
        return cart._cost;
    }

    function mint(
        uint256[] calldata _quantities,
        bytes32[][] calldata _proofs,
        uint256[] calldata _allotments,
        uint256[] calldata _allowlistIds,
        string[][] calldata _config
    ) external payable nonReentrant {
        require(!isSanctioned(_msgSender()), "S");
       
       MintCart memory cart;

        for (uint256 i = 0; i < _quantities.length; i++) {
            cart._scratch = 0;
            cart._quantity += _quantities[i];

            revertOnInactiveList(_allowlistIds[i]);
            revertOnAllocationCheckFailure(
                _msgSender(),
                _allowlistIds[i],
                mintedByAllowlist[_msgSender()][_allowlistIds[i]],
                _quantities[i],
                _allotments[i],
                _proofs[i]
            );
            revertOnConfigCheckFailure(_quantities[i], _config[i]);
            mintedByConfig[_config[i][0]] += _quantities[i];
            mintedByConfig[_config[i][1]] += _quantities[i];
            
            for (uint256 c = 0; c < _config[i].length; c++) {
                if(priceByConfig[_config[i][c]] > 0){
                    cart._scratch = Math.max(cart._scratch, priceByConfig[_config[i][c]]);
                }
                
            }
        
            cart._cost += cart._scratch > 0 ? cart._scratch * _quantities[i] : allowlists.lists[_allowlistIds[i]].price * _quantities[i];
        }
        require(cart._quantity + minted[_msgSender()] <= config.mintConfig.maxPerWallet, "Max wallet");
        require(nextTokenId + cart._quantity - 1 <= config.mintConfig.maxSupply, "Max supply");

        if (cart._cost > msg.value) revert InsufficientFunds();
        (bool sent, bytes memory data) = receivingWallet.call{value: msg.value}("");

        unchecked {

            for (uint256 i = 0; i < _quantities.length; i++) {

                for (uint256 j = 0; j < _quantities[i]; j++) {
                    cart._tokensMinted = string(
                        abi.encodePacked(
                            cart._tokensMinted,
                            nextTokenId.toString(),
                            ":",
                            _config[i][0],
                            ",",
                            _config[i][1],
                            "|"
                        )
                    );

                    _safeMint(_msgSender(), nextTokenId);
                    nextTokenId++;
                }
            }
            
        }
        emit Minted(_msgSender(), cart._tokensMinted);

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
    ) internal {
        if (_quantity == 0) revert MintZeroQuantity();
        Allowlist storage allowlist = allowlists.lists[_allowlistId];
        if(totalMintedByAllowlist[_allowlistId] + _quantity > allowlist.maxSupply)
            revert AllowlistSupplyExhausted();
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

         mintedByAllowlist[address(_msgSender())][
                    _allowlistId
                ] += _quantity;

        totalMintedByAllowlist[_allowlistId] += _quantity;
        minted[address(_msgSender())] += _quantity;
    }

    function revertOnConfigCheckFailure(
        uint256 _quantity,
        string[] calldata _config
    ) internal view {
       require(mintedByConfig[_config[0]] + _quantity <= configSupplyLimit[_config[0]], string( abi.encodePacked(_config[0], " max")));
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Auth"
        );
        _burn(tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                      Allowlist Logic
  //////////////////////////////////////////////////////////////*/

    function setAllowlists(Allowlist[] calldata _allowlists)
        external
        minRole(PRODUCER_ROLE)
    {
        allowlists.count = _allowlists.length;
        for (uint256 i = 0; i < _allowlists.length; i++) {
            allowlists.lists[i] = _allowlists[i];
        }
    }

    function updateAllowlistByIndex(Allowlist calldata _allowlist, uint256 i)
        external
        minRole(PRODUCER_ROLE)
    {
        allowlists.lists[i] = _allowlist;
    }

    function addAllowlist(Allowlist calldata _allowlist)
        external
        minRole(PRODUCER_ROLE)
    {
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
        minted_ = mintedByAllowlist[msg.sender][_allowlistId];
    }

    /*///////////////////////////////////////////////////////////////
                      Setters
  //////////////////////////////////////////////////////////////*/

    function upsertConfigSettings(string calldata _config, uint256 _supply, uint256 _price)
      external
      minRole(CONTRACT_ADMIN_ROLE)
    {
        priceByConfig[_config] = _price;
        configSupplyLimit[_config] = _supply;
    }


    function setRoyalty(uint96 _royalty) external minRole(PRODUCER_ROLE) {
        _setDefaultRoyalty(rWallet, _royalty);
    }

     function setTokenRoyalty(uint256[] calldata tokenId, address _receiverAddress, uint96 _royalty) external minRole(PRODUCER_ROLE) {
        for (uint256 i = 0; i < tokenId.length; i++) {
            _setTokenRoyalty(tokenId[i], _receiverAddress, _royalty);
        }
        
    }

    function setReceivingWallet(address _address)
      external
      minRole(CONTRACT_ADMIN_ROLE)
    {
        receivingWallet = _address;
    }

     function setRoyaltyWallet(address _address)
      external
      minRole(CONTRACT_ADMIN_ROLE)
    {
        rWallet = _address;
    }


    function setInternals(
        address _receivingWallet,
        address _rWallet
    ) external minRole(CONTRACT_ADMIN_ROLE) {
        receivingWallet = _receivingWallet;
        rWallet = _rWallet;
      
    }

    function setConfig(Config calldata _config)
        external
        minRole(PRODUCER_ROLE)
    {
        config = _config;
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "!A");
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        contractURI = _uri;
    }

    /// @dev Lets a contract admin set the URI for the baseURI.
    function setBaseURI(string calldata _baseURI)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        baseURI_ = _baseURI;
    }


    /// @dev Lets a contract admin set the address for the parent project.
    function setProject(address _project) external minRole(PRODUCER_ROLE) {
        project = _project;
    }

    /*///////////////////////////////////////////////////////////////
                      Miscellaneous / Overrides
  //////////////////////////////////////////////////////////////*/

    function togglePause(bool _isPaused) external minRole(PRODUCER_ROLE) {
        _isPaused ? _pause() : _unpause();
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
        minRole(CONTRACT_ADMIN_ROLE)
    {
        if (!hasRole(role, account)) {
            super._grantRole(role, account);
        }
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
        minRole(CONTRACT_ADMIN_ROLE)
    {
        if (hasRole(role, account)) {
            if (role == DEFAULT_ADMIN_ROLE && account == owner()) revert();
            super._revokeRole(role, account);
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

     function isSanctioned(address _operatorAddress) public view returns (bool) {
        if(SANCTIONS_CONTRACT != address(0)){
            SanctionsList sanctionsList = SanctionsList(SANCTIONS_CONTRACT);
            bool isToSanctioned = sanctionsList.isSanctioned(_operatorAddress);
            return isToSanctioned;
        }
        return false;
        
    }

     function setSactionsContract(address _address)
        external
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        SANCTIONS_CONTRACT = _address;
    }

    /**
     * @dev Check if minimum role for function is required.
     */
    modifier minRole(bytes32 _role) {
        require(_hasMinRole(_role), "Auth");
        _;
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

     function setApprovalForAll(address operator, bool approved) public override(ERC721Upgradeable, IERC721Upgradeable) {
        require(onlyAllowedOperatorApproval(operator), "O");
        super.setApprovalForAll(operator, approved);
    }

     function approve(address operator, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) {
        require(onlyAllowedOperatorApproval(operator), "O");
        super.approve(operator, tokenId);
     }

      function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) {
        require(onlyAllowedOperatorApproval(from), "O");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) {
        require(onlyAllowedOperatorApproval(from), "O");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
       
    {
       require(onlyAllowedOperatorApproval(from), "O");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        super._beforeTokenTransfer(from, to, tokenId, 1);
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