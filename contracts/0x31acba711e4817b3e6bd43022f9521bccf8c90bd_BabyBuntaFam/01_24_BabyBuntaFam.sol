// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/*****************************************************************************\
| ____        _             ____              _          _____                |
|| __ )  __ _| |__  _   _  | __ ) _   _ _ __ | |_ __ _  |  ___|_ _ _ __ ___   |
||  _ \ / _` | '_ \| | | | |  _ \| | | | '_ \| __/ _` | | |_ / _` | '_ ` _ \  |
|| |_) | (_| | |_) | |_| | | |_) | |_| | | | | || (_| | |  _| (_| | | | | | | |
||____/ \__,_|_.__/ \__, | |____/ \__,_|_| |_|\__\__,_| |_|  \__,_|_| |_| |_| |
|                    |___/                                                    |
\*****************************************************************************/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "contract-allow-list/contracts/AntiScam/RestrictApprove/RestrictApprove.sol";
import "closedsea/src/OperatorFilterer.sol";
import "./libs/ERC2981.sol";
import "./descriptor/IDescriptor.sol";

contract BabyBuntaFam is 
    ERC721A, 
    Ownable, 
    AccessControl, 
    ERC2981, 
    OperatorFilterer, 
    RestrictApprove 
{

    ///////////////////////////////////////////////////////////////////////////
    // Constant Variables
    ///////////////////////////////////////////////////////////////////////////
    /// @dev Founder's address.
    address public constant ADDRESS_FOUNDER = 0xd3441bF5870eF9C2cec0212532a5B4EDD5ed9B74;
    /// @dev Maximum number of supply.
    uint256 public constant MAX_SUPPLY = 3000;
    /// @dev Roles for Seller
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");


    ///////////////////////////////////////////////////////////////////////////
    // Constant Variables
    ///////////////////////////////////////////////////////////////////////////
    /// @dev Configuration for ClosedSea.
    bool public operatorFilteringEnabled;
    /// @dev Configuration for Contract Lock.
    bool public contractLocked;
    /// @dev Descriptor contract address
    IDescriptor public descriptor;

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
    // Custom Errors
    ///////////////////////////////////////////////////////////////////////////
    /// @dev mints exceeding max supply.
    error MintExceedingMaxSupply();
    /// @dev Operation by unauthorized user
    error UnauthorizedOperation();
    /// @dev Contract under Lock.
    error ApproveUnderLocked();
    /// @dev Contract under Lock.
    error TransferUnderLocked();

    ///////////////////////////////////////////////////////////////////////////
    // Modifier
    ///////////////////////////////////////////////////////////////////////////
    modifier onlyAdmin() {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorizedOperation();
        _;
    }

    constructor () ERC721A("BabyBuntaFam", "BBF") {
        // Grant roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, ADDRESS_FOUNDER);
        
        // Initialize Closed Sea for OpenSea Filterer.
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the project owner,
        // at 10% (default denominator is 10000).
        _setDefaultRoyalty(ADDRESS_FOUNDER, 1000);

        // Initialize RestrictApprove
        _setRestrictEnabled(true);
        _setCALLevel(1);

        // Set CAL Proxy.
        _setCAL(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7);

    }

    function _mint(address to, uint256 quantity) internal virtual override {
        if (quantity + totalSupply() > MAX_SUPPLY) revert MintExceedingMaxSupply();
        super._mint(to, quantity);
    }

    function adminMint(address to, uint256 quantity) 
        public 
        virtual 
        onlyAdmin 
    {
        _mint(to, quantity);
    }

    function sellerMint(address to, uint256 quantity) 
        public 
        virtual 
        onlyRole(SELLER_ROLE) 
    {
        _mint(to, quantity);
    }

    function sellerSafeMint(address to, uint256 quantity) 
        public 
        virtual 
        onlyRole(SELLER_ROLE) 
    {
        _safeMint(to, quantity);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Descriptor Interfaces
    ///////////////////////////////////////////////////////////////////////////
    function setDescriptor(IDescriptor addr)
        external 
        onlyAdmin
    {
        descriptor = addr;
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721A Override
    ///////////////////////////////////////////////////////////////////////////
    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory uri) {
        _exists(tokenId);
        return descriptor.tokenURI(tokenId);
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC165 Override
    ///////////////////////////////////////////////////////////////////////////
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721A, ERC2981)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721RestrictApprove).interfaceId ||
            interfaceId == bytes4(0x49064906) ||                            // ERC4906
            ERC2981.supportsInterface(interfaceId);
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
        operatorFilteringEnabled = value;
    }

    ///////////////////////////////////////////////////////////////////////////
    // ClosedSea Override
    ///////////////////////////////////////////////////////////////////////////
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Contract Lock Admin Functions
    ///////////////////////////////////////////////////////////////////////////
    function setContractLock (bool value)
        external 
        onlyAdmin
    {
        contractLocked = value;
    }

    ///////////////////////////////////////////////////////////////////////////
    // ERC721A Approve and transfer functions with ClosedSea and AntiScam and SBT
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
        payable
        virtual 
        override
        onlyAllowedOperatorApproval(to)
        onlyTokenApprovable(to, tokenId)
    {
        if (contractLocked) revert ApproveUnderLocked();
        super.approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (contractLocked) return address(0);
        return super.getApproved(tokenId);
    }

    function isApprovedForAll(address holder, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (contractLocked) return false;
        return super.isApprovedForAll(holder, operator);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
        onlyWalletApprovable(operator, msg.sender, approved)
    {
        if (contractLocked) revert ApproveUnderLocked();
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        if (contractLocked) revert TransferUnderLocked();
        super.transferFrom(from, to, tokenId);
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