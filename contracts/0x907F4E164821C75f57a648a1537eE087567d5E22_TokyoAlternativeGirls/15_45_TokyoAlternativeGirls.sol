// SPDX-License-Identifier: UNLICENSE
/*
  _____     _                     _    _ _                        _   _              ____ _      _     
 |_   _|__ | | ___   _  ___      / \  | | |_ ___ _ __ _ __   __ _| |_(_)_   _____   / ___(_)_ __| |___ 
   | |/ _ \| |/ / | | |/ _ \    / _ \ | | __/ _ \ '__| '_ \ / _` | __| \ \ / / _ \ | |  _| | '__| / __|
   | | (_) |   <| |_| | (_) |  / ___ \| | ||  __/ |  | | | | (_| | |_| |\ V /  __/ | |_| | | |  | \__ \
   |_|\___/|_|\_\\__, |\___/  /_/   \_\_|\__\___|_|  |_| |_|\__,_|\__|_| \_/ \___|  \____|_|_|  |_|___/
                 |___/                                                                                 

*/
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
//import {IERC2981Upgradeable, ERC2981Upgradeable} 
//    from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "./libs/ERC2981Upgradeable.sol";
import "./ERC721PsiAirdrop/ERC721PsiBurnableAirdropUpgradeable.sol";
import "./AntiScam/AntiScamWallet.sol";
import "closedsea/src/OperatorFilterer.sol";
import "./storage/TAGStorage.sol";
import "./descriptor/IDescriptor.sol";

contract TokyoAlternativeGirls is 
    Initializable, 
    UUPSUpgradeable, 
    AccessControlUpgradeable,
    OwnableUpgradeable,
    ERC721PsiBurnableAirdropUpgradeable, 
    OperatorFilterer,
    AntiScamWallet,
    ERC2981Upgradeable
{
    using TAGStorage for TAGStorage.Layout;

    ///////////////////////////////////////////////////////////////////////////
    // Constants
    ///////////////////////////////////////////////////////////////////////////

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 public constant MAX_SUPPLY = 10000;

    address private constant ADDRESS_OWNER = 0x6d8a59858211cc3ffA87e0e84cd1a648072082d1;

    error NotPermittedOperationExceptHolder();
    error NotPermittedOperationExceptAdmin();
    error NoTokenIdToBurn();
    error MintExceedingMaxSupply();

    ///////////////////////////////////////////////////////////////////////////
    // ERC4906 interface
    ///////////////////////////////////////////////////////////////////////////
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    ///////////////////////////////////////////////////////////////////////////
    // UUPS constructor and initializer and upgrade function
    ///////////////////////////////////////////////////////////////////////////

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer initializerAntiScam{
        // Call initilizing functions
        __ERC721PsiBurnableAirdrop_init("TokyoAlternativeGirls", "TAG");
        __UUPSUpgradeable_init();
        __Ownable_init();       // Transfer ownership for msg.sender in init
        __AccessControl_init();
        __AntiScamWallet_init();
        __ERC2981_init();
        
        // Set airdrop configuration
        _setAddressLengthInPointer(1200);

        // OpenSea Filterer by ClosedSea
        _registerForOperatorFiltering();
        TAGStorage.layout().operatorFilteringEnabled = true;

        // Set royalty receiver to the project owner,
        // at 10% (default denominator is 10000).
        _setDefaultRoyalty(ADDRESS_OWNER, 1000);

        // Grant roles.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, ADDRESS_OWNER);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        // Set CAL Proxy.
        _setCAL(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7);

        // Set Local CAL for UneMeta.
        _addLocalContractAllowList(0x836473Fa81FF3e7D4E6Ee3D542f03cCeb3f629d2);
        _addLocalContractAllowList(0x2445A4E934AF7C786755931610Af099554Ba1354);

        // Set ContractLock to Lock to prevent holder operation before the end of the airdrop.
        _setContractLock(LockStatus.Lock);

    }

    function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}

    ///////////////////////////////////////////////////////////////////////////
    // Access Control modifiers
    ///////////////////////////////////////////////////////////////////////////

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert NotPermittedOperationExceptAdmin();
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721 Internal mint logic override
    ///////////////////////////////////////////////////////////////////////////

    /// @dev Override to check minting over maximum supply.
    function _mint(address to, uint256 quantity) internal virtual override {
        if (totalSupply() + quantity > MAX_SUPPLY) revert MintExceedingMaxSupply();
        super._mint(to, quantity);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721 Mint / Burn
    ///////////////////////////////////////////////////////////////////////////
    function airdropMint(uint256 airdropPointerCount)
        external
        onlyAdmin
    {
        _airdropMint(airdropPointerCount);
    }
    function externalSafeMint(address to, uint256 quantity) 
        external 
        onlyRole(MINTER_ROLE) 
    {
        _safeMint(to, quantity);
    }

    function externalMint(address to, uint256 quantity) 
        external 
        onlyRole(MINTER_ROLE) 
    {
        _mint(to, quantity);
    }

    function externalBurn(uint256 tokenId) 
        external 
        onlyRole(BURNER_ROLE) 
    {
        _burn(tokenId);
    }

    function externalBurnBatch(uint256[] memory tokenIds) 
        external 
        onlyRole(BURNER_ROLE) 
    {
        uint256 len = tokenIds.length;
        if (len == 0) revert NoTokenIdToBurn();
        for (uint256 i; i < len; ){
            _burn(tokenIds[i]);
            unchecked{
                ++i;
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721Psi Override
    ///////////////////////////////////////////////////////////////////////////
    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    function balanceOf(address holder) 
        public 
        view 
        virtual 
        override 
        returns (uint) 
    {
        require(holder != address(0), "ERC721Psi: balance query for the zero address");

        uint256 count;
        uint256 nextTokenId = _nextTokenId();
        unchecked{
            for( uint i = _startTokenId(); i < nextTokenId; ++i ){
                if(_exists(i)){
                    if( holder == ownerOf(i)){
                        ++count;
                    }
                }
            }
        }
        return count;
    }

    /**
     * @dev Balance query function for specified range to prevent running out gas.
     * @param holder Specifies address for query
     * @param start Start token ID for query
     * @param end End token ID for query. Not include this token ID.
     */
    function balanceQuery(address holder, uint256 start, uint256 end)
        public 
        view 
        virtual 
        returns (uint) 
    {
        require(holder != address(0), "ERC721Psi: balance query for the zero address");

        uint256 count;
        uint256 nextTokenId = _nextTokenId();
        uint256 firstId = _startTokenId();
        if (start  < firstId) revert InvalidParameter();
        if (end  > nextTokenId) revert InvalidParameter();
        
        unchecked{
            for( uint i = start; i < end; ++i ){
                if(_exists(i)){
                    if( holder == ownerOf(i)){
                        ++count;
                    }
                }
            }
        }
        return count;
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721Psi Interface to external
    ///////////////////////////////////////////////////////////////////////////
    function getStartTokenId() external pure virtual returns (uint256) {
        return _startTokenId();
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721Psi Approve and transfer functions with ClosedSea and AntiScam
    ///////////////////////////////////////////////////////////////////////////
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) 
        internal 
        virtual 
        override
        onlyTransferable(from, to, startTokenId, quantity)
    {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function approve(address to, uint256 tokenId) 
        public 
        virtual 
        override
        onlyAllowedOperatorApproval(to)
        onlyTokenApprovable(to, tokenId)
    {
        super.approve(to, tokenId);
    }

    function isApprovedForAll(address holder, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.isApprovedForAll(holder, operator) && _isWalletApprovable(operator, holder);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
        onlyWalletApprovable(operator, msg.sender, approved)
    {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Override parent caller for ownerOf() function directly.
     */
    function _callOwnerOf(uint256 tokenId) internal view virtual override returns (address) {
        return ownerOf(tokenId);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC165 Override
    ///////////////////////////////////////////////////////////////////////////
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721PsiUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            AccessControlUpgradeable.supportsInterface(interfaceId) ||
            ERC721PsiUpgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721RestrictApprove).interfaceId ||
            interfaceId == bytes4(0x49064906) ||                            // ERC4906
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721PsiAirdrop Setter function
    ///////////////////////////////////////////////////////////////////////////
    function addAirdropListPointers(address[] memory pointers)
        external
        onlyAdmin
    {
        _addAirdropListPointers(pointers);
    }

    function updateAirdropListPointer(uint256 index, address pointer)
        external
        onlyAdmin
    {
        _updateAirdropListPointer(index, pointer);
    }

    ///////////////////////////////////////////////////////////////////////////
    // IERC721RestrictApprove Override
    ///////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set CAL Level.
     */
    function setCALLevel(uint256 level)
        external 
        onlyAdmin
    {
        _setCALLevel(level);
    }

    /**
     * @dev Set `calAddress` as the new proxy of the contract allow list.
     */
    function setCAL(address calAddress) 
        external
        onlyAdmin
    {
        _setCAL(calAddress);
    }

    /**
     * @dev Add `transferer` to local contract allow list.
     */
    function addLocalContractAllowList(address transferer)
        external
        onlyAdmin
    {
        _addLocalContractAllowList(transferer);
    }

    /**
     * @dev Remove `transferer` from local contract allow list.
     */
    function removeLocalContractAllowList(address transferer)
        external
        onlyAdmin
    {
        _removeLocalContractAllowList(transferer);
    }

    /**
     * @dev Set which the restriction by CAL is enabled.
     */
    function setRestrictEnabled(bool value)
        external
        onlyAdmin
    {
        _setRestrictEnabled(value);
    }

    ///////////////////////////////////////////////////////////////////////////
    // WalletLockable Override
    ///////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set which the lock is enabled.
     */
    function setLockEnabled(bool value) 
        external
        onlyAdmin
    {
        _setLockEnabled(value);
    }

    /**
     * @dev Set lock status of specified address.
     */
    function setWalletLock(LockStatus lockStatus) 
        external
    {
        _setWalletLock(msg.sender, lockStatus);
    }

    /**
     * @dev Set default lock status.
     */
    function setDefaultLock(LockStatus lockStatus)
        external
        onlyAdmin
    {
        _setDefaultLock(lockStatus);
    }

    /**
     * @dev Set contract lock status.
     */
    function setContractLock(LockStatus lockStatus)
        external
        onlyAdmin
    {
        _setContractLock(lockStatus);
    }

    ///////////////////////////////////////////////////////////////////////////
    // WalletLockable Admin function
    ///////////////////////////////////////////////////////////////////////////
    /**
     * @dev Unlock wallet lock. This is to prevent floor price attack by wallet lock.
     */
    function unlockWalletByAdmin(address to) 
        external
        onlyAdmin
    {
        _setWalletLock(to, LockStatus.UnLock);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC2981 Setter function
    ///////////////////////////////////////////////////////////////////////////
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) 
        public 
        onlyAdmin 
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ClosedSea Setter functions
    ///////////////////////////////////////////////////////////////////////////
    function setOperatorFilteringEnabled(bool value) 
        public 
        onlyAdmin 
    {
        TAGStorage.layout().operatorFilteringEnabled = value;
    }

    ///////////////////////////////////////////////////////////////////////////
    // ClosedSea Override
    ///////////////////////////////////////////////////////////////////////////
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return TAGStorage.layout().operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ClosedSea getter functions
    ///////////////////////////////////////////////////////////////////////////
    function operatorFilteringEnabled() external view returns (bool) {
        return TAGStorage.layout().operatorFilteringEnabled;
    }

    ///////////////////////////////////////////////////////////////////////////
    // TAG functions
    ///////////////////////////////////////////////////////////////////////////
    function descriptor() external view returns (IDescriptor) {
        return TAGStorage.layout().descriptor;
    }

    function setDescriptor(IDescriptor addr)
        external 
        onlyAdmin
    {
        TAGStorage.layout().descriptor = addr;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory uri) {
        _exists(tokenId);
        return TAGStorage.layout().descriptor.tokenURI(tokenId);
    }
    ///////////////////////////////////////////////////////////////////////////
    // ERC4906 functions
    ///////////////////////////////////////////////////////////////////////////
    function updateMetadata(uint256 tokenId) external onlyAdmin {
        emit MetadataUpdate(tokenId);
    }

    function updateMetadataBatch(uint256 from, uint256 to) external onlyAdmin {
        emit BatchMetadataUpdate(from, to);
    }

}