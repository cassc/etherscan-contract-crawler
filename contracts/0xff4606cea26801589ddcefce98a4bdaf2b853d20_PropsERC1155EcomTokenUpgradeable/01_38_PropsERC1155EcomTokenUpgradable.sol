// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.4;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@thirdweb-dev/contracts/feature/interface/IOwnable.sol";
import "@thirdweb-dev/contracts/lib/MerkleProof.sol";

//  ==========  Internal imports    ==========

import "../interfaces/IAllowlist.sol";
import "../interfaces/IConfig.sol";
import "../interfaces/IPropsContract.sol";
import "../interfaces/IPropsAccessRegistry.sol";

import {DefaultOperatorFiltererUpgradeable} from "./opensea/DefaultOperatorFiltererUpgradeable.sol";

contract PropsERC1155EcomTokenUpgradeable is
    Initializable,
    IOwnable,
    IAllowlist,
    IConfig,
    IPropsContract,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC2771ContextUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC2981
{
    using StringsUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    //////////////////////////////////////////////
    // State Vars
    /////////////////////////////////////////////

    bytes32 private constant MODULE_TYPE = bytes32("PropsEcomToken");
    uint256 private constant VERSION = 9;

    uint256 public tokenIndex;
    mapping(address => uint256) public minted;
    mapping(address => mapping(uint256 => uint256)) public mintedByAllowlist;

    bytes32 private constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 private constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");
    // @dev reserving space for 10 more roles
    bytes32[32] private __gap;

    string private baseURI_;
    string public contractURI;
    address private _owner;
    address private accessRegistry;
    address public project;
    address public receivingWallet;
    address public rWallet;
    address[] private trustedForwarders;

    string public _name;
    string public _symbol;

    Allowlists public allowlists;
    Config public config;

    mapping(uint256 => Token1155) public tokens;

    //////////////////////////////////////////////
    // Errors
    /////////////////////////////////////////////

    error AllowlistInactive();
    error MintQuantityInvalid();
    error MerkleProofInvalid();
    error MintZeroQuantity();
    error InsufficientFunds();

    //////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////

    event Minted(address indexed account, string tokens);
    event Redeemed(address indexed account, string tokens);

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
        __ERC1155_init("");

        receivingWallet = _receivingWallet;
        rWallet = _receivingWallet;
        _owner = _defaultAdmin;
        accessRegistry = _accessRegistry;
        tokenIndex = 1;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PRODUCER_ROLE, CONTRACT_ADMIN_ROLE);


        // call registry add here
        // add default admin entry to registry
        IPropsAccessRegistry(accessRegistry).add(_defaultAdmin, address(this));
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
        require(totalSupply(_tokenId) > 0, "U1");
        return tokens[_tokenId].baseURI;
    }

    function getToken(uint256 _index)
        public
        view
        returns (Token1155 memory token)
    {
        token = tokens[_index];
    }

    function upsertToken(Token1155 memory _token)
        external
    {
        require(hasMinRole(PRODUCER_ROLE));

        //if update
        if(_token.tokenId > 0 && keccak256(abi.encodePacked(tokens[_token.tokenId].name)) != keccak256("")){
            tokens[_token.tokenId] = _token;
        }
        //else insert new token at the next index
        else{
            require(keccak256(abi.encodePacked(_token.name)) != keccak256(""), "Name required");
            _token.tokenId = tokenIndex;
            tokens[tokenIndex] = _token;
            tokenIndex++;
        }

    }


    function mint(
        uint256[] calldata _quantities,
        bytes32[][] calldata _proofs,
        uint256[] calldata _allotments,
        uint256[] calldata _allowlistIds
    ) external payable nonReentrant {

        uint256 _cost;
        uint256 _quantity;
        uint256 _allowlistId;

        for (uint256 i; i < _quantities.length; i++) {
            _quantity += _quantities[i];
            _allowlistId = _allowlistIds[i];

            // @dev Require could save .029kb
            revertOnInactiveList(_allowlistId);
            revertOnAllocationCheckFailure(
                msg.sender,
                _allowlistId,
                mintedByAllowlist[msg.sender][_allowlistId],
                _quantities[i],
                _allotments[i],
                _proofs[i]
            );
            _cost += allowlists.lists[_allowlistId].price * _quantities[i];
        }

        if (_cost > msg.value) revert InsufficientFunds();
        payable(receivingWallet).transfer(msg.value);

        // mint _quantity tokens
        string memory tokensMinted = "";
        unchecked {
            //for each quantity index
            for (uint256 i; i < _quantities.length; i++) {
                _allowlistId = _allowlistIds[i];
                //for each quantity in that index
                mintedByAllowlist[address(msg.sender)][
                    _allowlistId
                ] += _quantities[i];
                for (uint256 j; j < _quantities[i]; j++) {
                    tokensMinted = string(
                        abi.encodePacked(
                            tokensMinted,
                            allowlists
                                .lists[_allowlistId]
                                .tokenPool.toString(),
                            ","
                        )
                    );

                }
                 _mint(msg.sender, allowlists
                        .lists[_allowlistId]
                        .tokenPool, _quantities[i], "");
            }
        }
        emit Minted(msg.sender, tokensMinted);
    }


    function revertOnInactiveList(uint256 _allowlistId) internal view {
        Allowlist storage allowlist = allowlists.lists[_allowlistId];
        if (
            paused() ||
            block.timestamp < allowlist.startTime ||
            block.timestamp > allowlist.endTime ||
            !allowlist.isActive
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
            (bool validMerkleProof, ) = MerkleProof
                .verify(
                    _proof,
                    allowlist.typedata,
                    keccak256(abi.encodePacked(_address, _alloted))
                );
            if (!validMerkleProof) revert MerkleProofInvalid();
        }
    }

    function redeem(uint256[] calldata _tokenIds, uint256[] calldata _amounts) public virtual {
        string memory tokensMinted = "";
        for (uint256 t; t < _tokenIds.length; t++) {
            uint256 tokenId = _tokenIds[t];
            uint256 amount = _amounts[t];
            Token1155 storage _token = tokens[tokenId];
            require(balanceOf(_msgSender(), tokenId) >= amount, "R1");

            require(_token.isRedeemable && _token.redeemStart <= block.timestamp && _token.redeemEnd >= block.timestamp, "R2");

             _burn(_msgSender(),tokenId, amount);

            for (uint256 i; i < _token.tokensToIssueOnRedeem.length; i++) {

                _mint(_msgSender(), _token.tokensToIssueOnRedeem[i], amount, "");

                for (uint256 j; j < amount; j++) {
                    tokensMinted = string(
                            abi.encodePacked(
                                tokensMinted,
                                _token.tokensToIssueOnRedeem[i].toString(),
                                ","
                            )
                        );
                }

            }

        }

        emit Redeemed(msg.sender,tokensMinted);

    }

    /*///////////////////////////////////////////////////////////////
                      Allowlist Logic
  //////////////////////////////////////////////////////////////*/

    function setAllowlists(Allowlist[] calldata _allowlists)
        external
    {
        require(hasMinRole(PRODUCER_ROLE));
        allowlists.count = _allowlists.length;
        for (uint256 i; i < _allowlists.length; i++) {
            allowlists.lists[i] = _allowlists[i];
        }
    }

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
        minted_ = mintedByAllowlist[msg.sender][_allowlistId];
    }

     function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }  

    /*///////////////////////////////////////////////////////////////
                      Setters
  //////////////////////////////////////////////////////////////*/

    function setNameAndSymbol(string memory name, string memory symbol) external {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        _name = name;
        _symbol = symbol;
    }


    function setRoyalty(uint96 _royalty) external {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        _setDefaultRoyalty(rWallet, _royalty);
    }

    function setRoyaltyWallet(address _address)
        external
       
        {
            require(hasMinRole(CONTRACT_ADMIN_ROLE));
            rWallet = _address;
        }

    function setReceivingWallet(address _address)
        external
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        receivingWallet = _address;
    }

    function setConfig(Config calldata _config)
        external
    {
        require(hasMinRole(PRODUCER_ROLE));
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
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        contractURI = _uri;
    }

    /// @dev Lets a contract admin set the address for the access registry.
    function setAccessRegistry(address _accessRegistry)
        external
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        accessRegistry = _accessRegistry;
    }

    /// @dev Lets a contract admin set the address for the parent project.
    function setProject(address _project) external {
        require(hasMinRole(PRODUCER_ROLE));
        project = _project;
    }

    /*///////////////////////////////////////////////////////////////
                      Miscellaneous / Overrides
  //////////////////////////////////////////////////////////////*/


    function togglePause(bool pause) external {
      require(hasMinRole(PRODUCER_ROLE));
      if(pause){
        _pause();
      }else{
        _unpause();
      }
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
    {
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
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
        require(hasMinRole(CONTRACT_ADMIN_ROLE));
        if (hasRole(role, account)) {
            // @dev ya'll can't take your own admin role, fool.
            if (role == DEFAULT_ADMIN_ROLE && account == owner()) revert();
            // #TODO check if it still adds roles (enumerable)!
            super._revokeRole(role, account);
            IPropsAccessRegistry(accessRegistry).remove(account, address(this));
        }
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


    uint256[49] private ___gap;
}