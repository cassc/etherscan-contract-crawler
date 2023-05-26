// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol";
import "./ERC721AntiScamSalesInfo.sol";
import "./ISalesItem.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract ERC721BasicFrameControlable is 
    IERC2981,
    ISalesItem,
    DefaultOperatorFilterer,
    AccessControl,
    Ownable,
    ERC721AntiScamSalesInfo
{

    ///////////////////////////////////////////////////////////////////////////
    // Constants
    ///////////////////////////////////////////////////////////////////////////

    uint256 public immutable MAX_SUPPLY;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    constructor(uint256 maxSupply){
        MAX_SUPPLY = maxSupply;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Variables
    ///////////////////////////////////////////////////////////////////////////

    // Mapping from tokenId to uint256 aux
    mapping(uint256 => uint256) private _tokenAux;

    // royalty
    address public royaltyAddress;
    uint96 public royaltyFee = 1000; // default:10%

    // SBT
    bool public isSBT;

    /*
    // tokenId -> unlock time
    mapping(uint256 => uint256) unlockTokenTimestamp;
    // wallet -> unlock time
    mapping(address => uint256) unlockWalletTimestamp;
    uint256 public unlockLeadTime = 3 hours;
    */

    ///////////////////////////////////////////////////////////////////////////
    // Error Functions
    ///////////////////////////////////////////////////////////////////////////
    error ZeroAddress();
    error InvlidRoyaltyFee(uint256 fee);
    error MaxSupplyExceeded();
    error ProhibitedBecauseSBT();
    error NotAllowedByCAL(address operator);
    error ArrayLengthIsZero();
    error NotTokenHolder();
    error WalletLockNotAllowedByOthers();
    error InvalidRole();
    error TokenNonexistent(uint256 tokenId);

    ///////////////////////////////////////////////////////////////////////////
    // External Mint / Burn function
    ///////////////////////////////////////////////////////////////////////////
    function externalMint(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        _mint(to, quantity);
    }

    function sellerMint(address to, uint256 quantity) external onlyRole(SELLER_ROLE) {
        _mint(to, quantity);
    }

    function externalBurn(uint256 tokenId) external onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    function sellerBurn(uint256 tokenId) external onlyRole(SELLER_ROLE) {
        _burn(tokenId);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Override function : _mint
    ///////////////////////////////////////////////////////////////////////////
    function _mint(address to, uint256 quantity) internal override {
        if (quantity + totalSupply() > MAX_SUPPLY) revert MaxSupplyExceeded();
        super._mint(to, quantity);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Number burned function
    ///////////////////////////////////////////////////////////////////////////
    function burned() external view returns(uint256){
        return _burned();
    }

    ///////////////////////////////////////////////////////////////////////////
    // Setter functions : Aux region of _addressData
    ///////////////////////////////////////////////////////////////////////////

    function setConsumedAllocation(address _target, uint8 _currentSaleIndex, uint16 _consumed)
        external
        virtual
        onlyRole(SELLER_ROLE)
    {
        // Grab memory
        AddressData memory data = _addressData[_target];
        data.saleIndex = _currentSaleIndex;
        data.numberConsumedInRecentSale = _consumed;
        _addressData[_target] = data;
    }

    function addConsumedAllocation(address _target, uint8 _currentSaleIndex, uint16 _consumed)
        external
        virtual
        onlyRole(SELLER_ROLE)
    {
        // Grab memory
        AddressData memory data = _addressData[_target];
        // If previous sale was recorded in the data, updates it with the current sale
        if (data.saleIndex != _currentSaleIndex){
            data.saleIndex = _currentSaleIndex;
            data.numberConsumedInRecentSale = _consumed;
        } else {
            data.numberConsumedInRecentSale += _consumed;
        }
        _addressData[_target] = data;
    }

    function _setAddressAux(address _target, uint40 _aux)
        internal
        virtual
    {
        _addressData[_target].aux = _aux;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Setter functions : TokenId Aux
    ///////////////////////////////////////////////////////////////////////////
    function _setTokenAux(uint256 tokenId, uint256 aux) internal virtual{
        _tokenAux[tokenId] = aux;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Setter functions : ERC2981
    ///////////////////////////////////////////////////////////////////////////
    function setRoyaltyAddress(address _new) external onlyAdmin {
        if (_new == address(0)) revert ZeroAddress();
        royaltyAddress = _new;
    }

    function setRoyaltyFee(uint96 _new) external onlyAdmin {
        if (_new > 10000) revert InvlidRoyaltyFee(_new);
        royaltyFee = _new;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Setter functions : Soul Bound Tokenizer
    ///////////////////////////////////////////////////////////////////////////
    function setIsSBT(bool _state) external onlyAdmin {
        isSBT = _state;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Essential getter functions
    ///////////////////////////////////////////////////////////////////////////
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, IERC165, ERC721AntiScamSubset)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(ISalesItem).interfaceId ||
            AccessControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    ///////////////////////////////////////////////////////////////////////////
    // AntiScam functions : Enabler
    ///////////////////////////////////////////////////////////////////////////
    function setEnableRestrict(bool value) external onlyAdmin {
        enableRestrict = value;
    }

    function setEnableLock(bool value) external onlyAdmin {
        enableLock = value;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Override functions : IERC721RestrictApprove
    ///////////////////////////////////////////////////////////////////////////
    function setCALLevel(uint256 level) external onlyAdmin{
        CALLevel = level;
    }

    function setCAL(address calAddress) external onlyAdmin{
        _setCAL(calAddress);
    }

    /*
    function addLocalContractAllowList(address transferer) external onlyAdmin{
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(address transferer) external onlyAdmin{
        _removeLocalContractAllowList(transferer);
    }

    function getLocalContractAllowList() external view returns(address[] memory){
        return _getLocalContractAllowList();
    }
    */

    ///////////////////////////////////////////////////////////////////////////
    // TimeLock derived from default-nft-contract
    // https://github.com/Lavulite/default-nft-contract/blob/main/contracts/tokens/NFT/base/ERC721AntiScamTimeLock.sol
    ///////////////////////////////////////////////////////////////////////////
    /*
    function setWalletLock(address to, LockStatus lockStatus)
        external
        override
    {
        if(msg.sender != to) revert WalletLockNotAllowedByOthers();

        if (
            walletLock[to] == LockStatus.Lock && lockStatus != LockStatus.Lock
        ) {
            unlockWalletTimestamp[to] = block.timestamp;
        }

        _setWalletLock(to, lockStatus);
    }

    function _isTokenLockToUnlock(uint256 tokenId, LockStatus newLockStatus)
        private
        view
        returns (bool)
    {
        if (newLockStatus == LockStatus.UnLock) {
            LockStatus currentWalletLock = walletLock[msg.sender];
            bool isWalletLock_TokenLockOrUnset = (currentWalletLock ==
                LockStatus.Lock &&
                tokenLock[tokenId] != LockStatus.UnLock);
            bool isWalletUnlockOrUnset_TokenLock = (currentWalletLock !=
                LockStatus.Lock &&
                tokenLock[tokenId] == LockStatus.Lock);

            return
                isWalletLock_TokenLockOrUnset ||
                isWalletUnlockOrUnset_TokenLock;
        } else if (newLockStatus == LockStatus.UnSet) {
            LockStatus currentWalletLock = walletLock[msg.sender];
            bool isNotWalletLock = currentWalletLock != LockStatus.Lock;
            bool isTokenLock = tokenLock[tokenId] == LockStatus.Lock;

            return isNotWalletLock && isTokenLock;
        } else {
            return false;
        }
    }

    function setTokenLock(uint256[] calldata tokenIds, LockStatus newLockStatus)
        external
        override
    {
        if (tokenIds.length == 0) revert ArrayLengthIsZero();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if(msg.sender != ownerOf(tokenIds[i])) revert NotTokenHolder();
        //}

        //for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_isTokenLockToUnlock(tokenIds[i], newLockStatus)) {
                unlockTokenTimestamp[tokenIds[i]] = block.timestamp;
            }
        }
        _setTokenLock(tokenIds, newLockStatus);
    }

    function _isTokenTimeLock(uint256 tokenId) private view returns (bool) {
        return unlockTokenTimestamp[tokenId] + unlockLeadTime > block.timestamp;
    }

    function _isWalletTimeLock(uint256 tokenId) private view returns (bool) {
        return
            unlockWalletTimestamp[ownerOf(tokenId)] + unlockLeadTime >
            block.timestamp;
    }

    function isLocked(uint256 tokenId)
        public
        view
///        override(IERC721Lockable, ERC721Lockable)
        override(ERC721Lockable)
        returns (bool)
    {
        return
            ERC721Lockable.isLocked(tokenId) ||
            _isTokenTimeLock(tokenId) ||
            _isWalletTimeLock(tokenId);
    }

    function setUnlockLeadTime(uint256 value) external onlyAdmin {
        unlockLeadTime = value;
    }
    */

    ///////////////////////////////////////////////////////////////////////////
    // Override functions for support interface of IERC721BasicFrame
    ///////////////////////////////////////////////////////////////////////////
    /*
    function ownerOf(uint256 tokenId) public view virtual override(IERC721BasicFrame, ERC721Psi) returns (address){
        return ERC721Psi.ownerOf(tokenId);
    }

    function totalSupply() public view virtual override(IERC721BasicFrame, ERC721PsiBurnable) returns (uint256){
        return ERC721PsiBurnable.totalSupply();
    }
    */
    ///////////////////////////////////////////////////////////////////////////
    // Override functions : ERC721Locable
    ///////////////////////////////////////////////////////////////////////////
    function setTokenLock(uint256[] calldata tokenIds, LockStatus lockStatus)
        external
        virtual
        override
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (msg.sender != ownerOf(tokenIds[i])) revert NotTokenHolder();
        }
        _setTokenLock(tokenIds, lockStatus);
    }

    function setWalletLock(address to, LockStatus lockStatus)
        external
        virtual
        override
    {
        require(to == msg.sender, "not yourself.");
        _setWalletLock(to, lockStatus);
    }

    function setContractLock(LockStatus lockStatus) external onlyAdmin{
        _setContractLock(lockStatus);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Internal State functions : TokenId Aux
    ///////////////////////////////////////////////////////////////////////////
    function _getAddressAux(address _target) internal virtual view returns(uint40){
        return _addressData[_target].aux;
    }
    
    function _getTokenAux(uint256 tokenId) internal virtual view returns(uint256){
        return _tokenAux[tokenId];
    }


    ///////////////////////////////////////////////////////////////////////////
    // Modifiers
    ///////////////////////////////////////////////////////////////////////////
    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

}

abstract contract ERC721BasicFrame is ERC721BasicFrameControlable {
    using Strings for uint256;

    ///////////////////////////////////////////////////////////////////////////
    // Constructor
    ///////////////////////////////////////////////////////////////////////////
    constructor(string memory _name, string memory _symbol, uint256 maxSupply) 
        ERC721Psi(_name, _symbol)
        ERC721BasicFrameControlable(maxSupply)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    ///////////////////////////////////////////////////////////////////////////
    // State functions : Aux region of _addressData
    ///////////////////////////////////////////////////////////////////////////
    /*
     * @dev Returns consumed allocation in the current sale
     */
    function getConsumedAllocation(address _target, uint8 _currentSaleIndex) external view virtual returns(uint16){
        
        // Grab stuck
        AddressData memory data = _addressData[_target];
        // If previous sale was recorded in the data, updates it with the current sale
        if (data.saleIndex != _currentSaleIndex){
            return 0;
        } 
        return data.numberConsumedInRecentSale;
    }
    
    ///////////////////////////////////////////////////////////////////////////
    // Override functions : ERC2981
    ///////////////////////////////////////////////////////////////////////////
    function royaltyInfo(
        uint256, /*_tokenId*/
        uint256 _salePrice
    ) public view virtual override returns (address, uint256) {
        return (royaltyAddress, (_salePrice * uint256(royaltyFee)) / 10000);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Transfer functions
    ///////////////////////////////////////////////////////////////////////////
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

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (
            isSBT &&
            from != address(0) &&
            to != address(0x000000000000000000000000000000000000dEaD)
        ) revert ProhibitedBecauseSBT();
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Approve functions
    ///////////////////////////////////////////////////////////////////////////
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        if (approved){
            if (isSBT) revert ProhibitedBecauseSBT();
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        if (operator != address(0)) {
            if (isSBT) revert ProhibitedBecauseSBT();
        }
        super.approve(operator, tokenId);
    }
}