// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.4;


//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@thirdweb-dev/contracts/feature/interface/IOwnable.sol";


//  ==========  Internal imports    ==========

import "../interfaces/IAllowlist.sol";
import "../interfaces/IPropsContract.sol";
import "../interfaces/IPropsCreatorConfig.sol";

import {DefaultOperatorFiltererUpgradeable} from "./opensea/DefaultOperatorFiltererUpgradeable.sol";


contract PropsERC1155UCreatorRoyalties is
    Initializable,
    IOwnable,
    IAllowlist,
    IPropsContract,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC2771ContextUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC2981
{
    using StringsUpgradeable for uint256;
    //////////////////////////////////////////////
    // State Vars
    /////////////////////////////////////////////

    bytes32 private constant MODULE_TYPE = bytes32("PropsERC1155UCreatorRoyalties");
    uint256 private constant VERSION = 4;

    mapping(address => uint256) public minted;
    mapping(address => mapping(uint256 => uint256)) public mintedByAllowlist;

    bytes32 private constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 private constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");

    // @dev reserving space for 10 more roles
    bytes32[32] private __gap;

    string public contractURI;
    address private _owner;
    address public configContract;
    address[] private trustedForwarders;

    Allowlists public allowlists;


    mapping(string => bool) internal nonces;

    //////////////////////////////////////////////
    // Errors
    /////////////////////////////////////////////

    error InsufficientFunds();

    //////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////

    event Minted(address indexed account, string tokens);

    //////////////////////////////////////////////
    // Extras
    /////////////////////////////////////////////

    mapping(string => uint256) internal tokenConfigurations;

    //////////////////////////////////////////////
    // Init
    /////////////////////////////////////////////

    function initialize(
        address _defaultAdmin,
        address[] memory _trustedForwarders
    ) public initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);
        __ERC1155_init("");

        _owner = _defaultAdmin;

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
        return _owner;
    }

    /*///////////////////////////////////////////////////////////////
                      ERC 165 / 1155 logic
  //////////////////////////////////////////////////////////////*/

    /**
     * @dev see {IERC721Metadata}
     */
    function uri(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(totalSupply(_tokenId) > 0, "U");
        return IPropsCreatorConfig(configContract).getTokenURI(_tokenId);
       
    }


    function createAndMint(IPropsCreatorConfig.ERC1155Token[] memory _token, IPropsCreatorConfig.Split[] memory _primarySplit, IPropsCreatorConfig.Split[] memory _royaltySplit, IPropsCreatorConfig.CreateMintConfig[] memory _config) external payable nonReentrant whenNotPaused {
         require(!IPropsCreatorConfig(configContract).isSanctioned(_msgSender()), "S");
        IPropsCreatorConfig.MintCart memory cart;

        unchecked {
            for (uint256 i = 0; i < _token.length; i++) {
            
                require(!nonces[_config[i]._nonce], "N");
                nonces[_config[i]._nonce] = true;

                uint256 lineItemCost = _config[i]._price * _config[i]._quantity;
                cart._cost += lineItemCost;

                if (cart._cost > msg.value) revert InsufficientFunds();

                string memory tokenCheck;
                string memory primaryCheck;
                string memory royaltyCheck;
            
                (tokenCheck, primaryCheck, royaltyCheck) = IPropsCreatorConfig(configContract).getCreationCheck(_token[i], _primarySplit[i], _royaltySplit[i]);

                IPropsCreatorConfig.SignatureRequest memory signatureRequest = IPropsCreatorConfig.SignatureRequest({tokenCheck: tokenCheck, primaryCheck: primaryCheck, royaltyCheck: royaltyCheck, configuration: _config[i]._configuration, quantity: _config[i]._quantity, price: _config[i]._price, nonce: _config[i]._nonce, issuedOn: _config[i]._issuedOn, signature: _config[i]._signature});
                
                IPropsCreatorConfig(configContract).revertOnUnauthorizedSignature(signatureRequest);
                
                uint256 existingConfigTokenId = tokenConfigurations[_config[i]._configuration];
                
                if(existingConfigTokenId > 0){
                    _token[i] = IPropsCreatorConfig(configContract).getToken(existingConfigTokenId);
                }
                else{
                    _token[i] = IPropsCreatorConfig(configContract).upsertToken(_token[i], _primarySplit[i], _royaltySplit[i], true);
                    tokenConfigurations[_config[i]._configuration] = _token[i].tokenId;
                }
                payable(IPropsCreatorConfig(configContract).getToken(_token[i].tokenId).primaryReceiver).transfer(lineItemCost);

                cart._tokensMinted =  string(
                    abi.encodePacked(
                        cart._tokensMinted,
                        _token[i].tokenId.toString(),
                        "|*|",
                        _config[i]._configuration,
                        "|*|",
                        existingConfigTokenId > 0 ? "false" : "true",
                        "|**|"

                    )
                );

                _mint(_msgSender(), _token[i].tokenId, _config[i]._quantity, "");
                
            }
        }
        emit Minted(_msgSender(), cart._tokensMinted);
    }
    

    function mint(
        uint256[] calldata _quantities, 
        bytes32[][] calldata _proofs, 
        uint256[] calldata _allotments, 
        uint256[] calldata _allowlistIds
    ) external payable nonReentrant whenNotPaused{
        require(IPropsCreatorConfig(configContract).isValidMinter(_msgSender(), _allowlistIds));

        IPropsCreatorConfig.MintCart memory cart;
        unchecked {
            for (uint256 i; i < _quantities.length; i++) {
                cart._quantity += _quantities[i];
                
                IPropsCreatorConfig.AllocationCheck memory allocationCheck = IPropsCreatorConfig.AllocationCheck({allowlist: allowlists.lists[_allowlistIds[i]], _address:_msgSender(), _minted: mintedByAllowlist[_msgSender()][_allowlistIds[i]], _quantity: _quantities[i], _alloted: _allotments[i], _proof:_proofs[i]});
                IPropsCreatorConfig(configContract).revertOnAllocationCheckFailure(allocationCheck);

                uint256 lineItemCost = allowlists.lists[_allowlistIds[i]].price * _quantities[i];
                cart._cost += lineItemCost;
                payable(IPropsCreatorConfig(configContract).getToken(allowlists.lists[_allowlistIds[i]].tokenPool).primaryReceiver).transfer(lineItemCost);
            }
        }

        if (cart._cost > msg.value) revert InsufficientFunds();

        
        unchecked {
            for (uint256 i; i < _quantities.length; i++) {
                mintedByAllowlist[address(_msgSender())][
                    _allowlistIds[i]
                ] += _quantities[i];             

                cart._tokensMinted =  string(
                    abi.encodePacked(
                        cart._tokensMinted,
                        allowlists.lists[_allowlistIds[i]].tokenPool.toString(),
                        ","
                    )
                ); 
                 
                 _mint(_msgSender(), allowlists
                        .lists[_allowlistIds[i]]
                        .tokenPool, _quantities[i], "");
            }
        }
        emit Minted(_msgSender(), cart._tokensMinted);
    }



    /*///////////////////////////////////////////////////////////////
                      Allowlist Logic
  //////////////////////////////////////////////////////////////*/


    function updateAllowlistByIndex(Allowlist calldata _allowlist, uint256 i)
        external
    {
        require(hasMinRole(PRODUCER_ROLE));
        allowlists.lists[i] = _allowlist;
    }

    function addAllowlist(Allowlist calldata _allowlist)
        external
    {
        require(hasMinRole(PRODUCER_ROLE));
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

     function setTokenRoyalty(uint256 _tokenId, address _royaltyReceiver, uint96 _royaltyPercentage) 
        external
    {
        require(_msgSender() == configContract, "A");
        _setTokenRoyalty(_tokenId, _royaltyReceiver, _royaltyPercentage);
    }

    function setInternals(address _configContract, bool pause) external {
       require(hasMinRole(CONTRACT_ADMIN_ROLE));
        configContract = _configContract;
        if(pause && !paused()) _pause();
        if(!pause && paused()) _unpause();
    }

     /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri)
        external
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        contractURI = _uri;
    }


    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "A");
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }


    /*///////////////////////////////////////////////////////////////
                      Miscellaneous / Overrides
  //////////////////////////////////////////////////////////////*/

    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        super._grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        super._revokeRole(role, account);
    }

    function hasMinRole(bytes32 _role) public view virtual returns (bool) {
        // @dev does account have role?
        if (hasRole(_role, _msgSender())) return true;
        // @dev are we checking against default admin?
        if (_role == DEFAULT_ADMIN_ROLE) return false;
        // @dev walk up tree to check if user has role admin role
        return hasMinRole(getRoleAdmin(_role));
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

     /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlEnumerableUpgradeable,
            ERC1155Upgradeable,
            ERC2981
        )
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            type(IERC1155Upgradeable).interfaceId == interfaceId ||
            type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

     /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        require(!IPropsCreatorConfig(configContract).isSanctioned(to), "S");
        IPropsCreatorConfig(configContract).updateOwnership(from, to, ids, amounts);
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    function setApprovalForAll(address operator, bool approved) public override {
        require(onlyAllowedOperatorApproval(operator), "O");
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
    {
        require(onlyAllowedOperatorApproval(from), "O");
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(onlyAllowedOperatorApproval(from), "O");
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }


    function totalBalanceOf(address owner) public view returns (uint256){
        return IPropsCreatorConfig(configContract).balanceOf(owner);

    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        return IPropsCreatorConfig(configContract).tokenOfOwnerByIndex(owner, index);

    }

    uint256[48] private ___gap;
}