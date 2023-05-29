// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/RoyaltyOverrideCore.sol";
import "contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol";
import "./ERC721AntiScamAddressData.sol";
import "./interface/ISalesItem.sol";
import "./interface/IERC4906.sol";

abstract contract ERC721BasicFrameControlable is 
    ISalesItem,
    AccessControl,
    Ownable,
    ERC721AntiScamAddressData,
    EIP2981RoyaltyOverrideCore,
    IERC4906
{

    ///////////////////////////////////////////////////////////////////////////
    // Constants
    ///////////////////////////////////////////////////////////////////////////
    bytes32 public constant ADMIN = keccak256("ADMIN");  
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant LOCK_ROLE = keccak256("LOCK_ROLE");

    constructor(uint256 _maxSupply){
        maxSupply = _maxSupply;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Variables
    ///////////////////////////////////////////////////////////////////////////
    uint256 public maxSupply;

    // Mapping from tokenId to uint256 aux
    mapping(uint256 => uint256) private _tokenAux;

    // Allow direct contract lock
    bool public isDirectContractLock;   // default:false
    /* time lock  */
    uint256 public unlockLeadTime = 3 hours;
	// tokenId -> unlock time
	mapping(uint256 => uint256) internal unlockTokenTimestamp;

	// wallet -> unlock time
	mapping(address => uint256) internal unlockWalletTimestamp;

    // SBT
    bool public isSBT;  // default:false

    ///////////////////////////////////////////////////////////////////////////
    // Error Functions
    ///////////////////////////////////////////////////////////////////////////
    error MaxSupplyExceeded();
    error ProhibitedBecauseSBT();
    error NotTokenHolder();
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
        if (quantity + totalSupply() > maxSupply) revert MaxSupplyExceeded();
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

    function setConsumedAllocation(address _target, uint16 _currentSaleIndex, uint16 _consumed)
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

    function addConsumedAllocation(address _target, uint16 _currentSaleIndex, uint16 _consumed)
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

    function _setAddressAux(address _target, uint32 _aux)
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
    // ERC-4906
    ///////////////////////////////////////////////////////////////////////////
	function refreshMetadata(uint256 _tokenId) external onlyAdmin {
		emit MetadataUpdate(_tokenId);
	}

	function refreshMetadata(uint256 _fromTokenId, uint256 _toTokenId) external onlyAdmin {
		emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
	}

    ///////////////////////////////////////////////////////////////////////////
    // EIP2981RoyaltyOverrideCore
    ///////////////////////////////////////////////////////////////////////////
    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royaltyConfigs)
        external
        override
        onlyAdmin
    {
        _setTokenRoyalties(royaltyConfigs);
    }

    function setDefaultRoyalty(TokenRoyalty calldata royalty)
        external
        override
        onlyAdmin
    {
        _setDefaultRoyalty(royalty);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Setter functions : basic
    ///////////////////////////////////////////////////////////////////////////
    function setMaxSupply(uint256 _value) external onlyAdmin {
        maxSupply = _value;
    }

    function setDirectContractLock(bool _state) external onlyAdmin {
        isDirectContractLock = _state;
    }

    function setUnlockLeadTime(uint256 _value) external onlyAdmin {
		unlockLeadTime = _value;
	}

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
        override(AccessControl, IERC165, ERC721AntiScam,EIP2981RoyaltyOverrideCore)
        returns (bool)
    {
        return
            interfaceId == type(ISalesItem).interfaceId ||
            ERC721AntiScam.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId) ||
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

    function addLocalContractAllowList(address transferer) external onlyAdmin{
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(address transferer) external onlyAdmin{
        _removeLocalContractAllowList(transferer);
    }

    function getLocalContractAllowList() external view returns(address[] memory){
        return _getLocalContractAllowList();
    }

    ///////////////////////////////////////////////////////////////////////////
    // external functions : Locable
    ///////////////////////////////////////////////////////////////////////////
    function setTokenLockEx(uint256[] calldata _tokenIds, uint256 _lockStatus)
        external
        onlyRole(LOCK_ROLE)
    {
        LockStatus _lockStatusCnvert;
        if(_lockStatus == uint256(LockStatus.UnSet)){
            _lockStatusCnvert = LockStatus.UnSet;
        }else if(_lockStatus == uint256(LockStatus.UnLock)){
            _lockStatusCnvert = LockStatus.UnLock;
        }else{  // Lock
            _lockStatusCnvert = LockStatus.Lock;
        }
        _setTokenLock(_tokenIds, _lockStatusCnvert);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
			emit MetadataUpdate(_tokenIds[i]);
		}
    }

    function setWalletLockEx(address _to, uint256 _lockStatus)
        external
        onlyRole(LOCK_ROLE)
    {
        LockStatus _lockStatusCnvert;
        if(_lockStatus == uint256(LockStatus.UnSet)){
            _lockStatusCnvert = LockStatus.UnSet;
        }else if(_lockStatus == uint256(LockStatus.UnLock)){
            _lockStatusCnvert = LockStatus.UnLock;
        }else{  // Lock
            _lockStatusCnvert = LockStatus.Lock;
        }
        _setWalletLock(_to, _lockStatusCnvert);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Override functions : ERC721Locable
    ///////////////////////////////////////////////////////////////////////////
    function setTokenLock(uint256[] calldata _tokenIds, LockStatus _lockStatus)
        external
        virtual
        override
    {
        require(isDirectContractLock == true,"not allow");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (msg.sender != ownerOf(_tokenIds[i])) revert NotTokenHolder();
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
			if (_isTokenLockToUnlock(_tokenIds[i], _lockStatus)) {
				unlockTokenTimestamp[_tokenIds[i]] = block.timestamp;
			}
		}

        _setTokenLock(_tokenIds, _lockStatus);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
			emit MetadataUpdate(_tokenIds[i]);
		}
    }

    function setWalletLock(address _to, LockStatus _lockStatus)
        external
        virtual
        override
    {
        require(isDirectContractLock == true,"not allow");
        require(_to == msg.sender, "not yourself.");

        if (walletLock[_to] == LockStatus.Lock && _lockStatus != LockStatus.Lock) {
			unlockWalletTimestamp[_to] = block.timestamp;
		}

        _setWalletLock(_to, _lockStatus);
    }

    function setContractLock(LockStatus lockStatus) external onlyAdmin{
        _setContractLock(lockStatus);
    }

    function _isTokenLockToUnlock(uint256 _tokenId, LockStatus _newLockStatus) private view returns (bool) {
		if (_newLockStatus == LockStatus.UnLock) {
			LockStatus currentWalletLock = walletLock[msg.sender];
			bool isWalletLock_TokenLockOrUnset = (currentWalletLock == LockStatus.Lock &&
				tokenLock[_tokenId] != LockStatus.UnLock);
			bool isWalletUnlockOrUnset_TokenLock = (currentWalletLock != LockStatus.Lock &&
				tokenLock[_tokenId] == LockStatus.Lock);

			return isWalletLock_TokenLockOrUnset || isWalletUnlockOrUnset_TokenLock;
		} else if (_newLockStatus == LockStatus.UnSet) {
			LockStatus currentWalletLock = walletLock[msg.sender];
			bool isNotWalletLock = currentWalletLock != LockStatus.Lock;
			bool isTokenLock = tokenLock[_tokenId] == LockStatus.Lock;

			return isNotWalletLock && isTokenLock;
		} else {
			return false;
		}
	}

	function _isTokenTimeLock(uint256 _tokenId) private view returns (bool) {
		return unlockTokenTimestamp[_tokenId] + unlockLeadTime > block.timestamp;
	}

	function _isWalletTimeLock(uint256 _tokenId) private view returns (bool) {
		return unlockWalletTimestamp[ownerOf(_tokenId)] + unlockLeadTime > block.timestamp;
	}

	function isLocked(uint256 _tokenId) public view override(IERC721Lockable, ERC721Lockable) returns (bool) {
        if(isDirectContractLock == true){
            // TimeLock
            return ERC721Lockable.isLocked(_tokenId) || _isTokenTimeLock(_tokenId) || _isWalletTimeLock(_tokenId);
        }else{
            return ERC721Lockable.isLocked(_tokenId);
        }
	}

    ///////////////////////////////////////////////////////////////////////////
    // Queriable (for block gas limit)
    ///////////////////////////////////////////////////////////////////////////
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view virtual returns (uint256[] memory) {
        unchecked {
            require(start < stop, "start must be greater than stop.");
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }

            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }

            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }

            for (
                uint256 i = start;
                i != stop && tokenIdsIdx != tokenIdsMaxLength;
                ++i
            ) {
                if (_exists(i)) {
                    if (ownerOf(i) == owner) {
                        tokenIds[tokenIdsIdx++] = i;
                    }
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Internal State functions : TokenId Aux
    ///////////////////////////////////////////////////////////////////////////
    function _getAddressAux(address _target) internal virtual view returns(uint32){
        return _addressData[_target].aux;
    }
    
    function _getTokenAux(uint256 tokenId) internal virtual view returns(uint256){
        return _tokenAux[tokenId];
    }

    ///////////////////////////////////////////////////////////////////////////
    // override AccessControl
    ///////////////////////////////////////////////////////////////////////////
    function grantRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        require(role != ADMIN, "not admin only.");
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        require(role != ADMIN, "not admin only.");
        _revokeRole(role, account);
    }

    function grantAdmin(address account) external onlyOwner {
        _grantRole(ADMIN, account);
    }

    function revokeAdmin(address account) external onlyOwner {
        _revokeRole(ADMIN, account);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Modifiers
    ///////////////////////////////////////////////////////////////////////////
    modifier onlyAdmin() {
        _checkRole(ADMIN);
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
        _grantRole(ADMIN, msg.sender);
    }

    ///////////////////////////////////////////////////////////////////////////
    // State functions : Aux region of _addressData
    ///////////////////////////////////////////////////////////////////////////
    /*
     * @dev Returns consumed allocation in the current sale
     */
    function getConsumedAllocation(address _target, uint16 _currentSaleIndex) external view virtual returns(uint16){
        // Grab stuck
        AddressData memory data = _addressData[_target];
        // If previous sale was recorded in the data, updates it with the current sale
        if (data.saleIndex != _currentSaleIndex){
            return 0;
        } 
        return data.numberConsumedInRecentSale;
    }
    
    ///////////////////////////////////////////////////////////////////////////
    // Transfer functions
    ///////////////////////////////////////////////////////////////////////////
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
    {
        if (operator != address(0)) {
            if (isSBT) revert ProhibitedBecauseSBT();
        }
        super.approve(operator, tokenId);
    }
}