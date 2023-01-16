// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "erc721a/contracts/ERC721A.sol";
import './IERC721AntiScam.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../proxy/interface/IContractAllowListProxy.sol";

/// @title AntiScam機能付きERC721A
/// @dev Readmeを見てください。

abstract contract ERC721AntiScam is ERC721A, IERC721AntiScam, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IContractAllowListProxy public CAL;
    EnumerableSet.AddressSet localAllowedAddresses;

    /*//////////////////////////////////////////////////////////////
    ロック変数。トークンごとに個別ロック設定を行う
    //////////////////////////////////////////////////////////////*/

    // token lock
    mapping(uint256 => LockStatus) internal _tokenLockStatus;
    mapping(uint256 => uint256) internal _tokenCALLevel;

    // wallet lock
    mapping(address => LockStatus) internal _walletLockStatus;
    mapping(address => uint256) internal _walletCALLevel;

    // contract lock
    LockStatus public contractLockStatus = LockStatus.CalLock;
    uint256 public CALLevel = 1;

    /*///////////////////////////////////////////////////////////////
    ロック機能ロジック
    //////////////////////////////////////////////////////////////*/

    function getLockStatus(uint256 tokenId) public virtual view returns (LockStatus) {
        require(_exists(tokenId), "AntiScam: locking query for nonexistent token");
        return _getLockStatus(ownerOf(tokenId), tokenId);
    }

    function getTokenLocked(address operator, uint256 tokenId) public virtual view returns(bool isLocked) {
        address holder = ownerOf(tokenId);
        LockStatus status = _getLockStatus(holder, tokenId);
        uint256 level = _getCALLevel(holder, tokenId);

        if (status == LockStatus.CalLock) {
            if (ownerOf(tokenId) == msg.sender) {
                return false;
            }
        } else {
            return _getLocked(operator, status, level);
        }
    }
    
    // TODO 標準実装
    function getTokensUnderLock(address to) external view returns (uint256[] memory){
        return new uint256[](0);
    }

    // TODO 標準実装
    function getTokensUnderLock(address to, uint256 start, uint256 end) external view returns (uint256[] memory){
        return new uint256[](0);
    }
    
    // TODO 標準実装
    function getTokensUnderLock(address holder, address to) external view returns (uint256[] memory){
        return new uint256[](0);
    }

    // TODO 標準実装
    function getTokensUnderLock(address holder, address to, uint256 start, uint256 end) external view returns (uint256[] memory){
        return new uint256[](0);
    }

    function getLocked(address operator, address holder) public virtual view returns(bool) {
        LockStatus status = _getLockStatus(holder);
        uint256 level = _getCALLevel(holder);
        return _getLocked(operator, status, level);
    }

    function _getLocked(address operator, LockStatus status, uint256 level) internal virtual view returns(bool){
        if (status == LockStatus.UnLock) {
            return false;
        } else if (status == LockStatus.AllLock)  {
            return true;
        } else if (status == LockStatus.CalLock) {
            if (isLocalAllowed(operator)) {
                return false;
            }
            if (address(CAL) == address(0)) {
                return true;
            }
            if (CAL.isAllowed(operator, level)) {
                return false;
            } else {
                return true;
            }
        } else {
            revert("LockStatus is invalid");
        }
    }

    function addLocalContractAllowList(address _contract) external onlyOwner {
        localAllowedAddresses.add(_contract);
    }

    function removeLocalContractAllowList(address _contract) external onlyOwner {
        localAllowedAddresses.remove(_contract);
    }

    function isLocalAllowed(address _transferer)
        public
        view
        returns (bool)
    {
        bool Allowed = false;
        if(localAllowedAddresses.contains(_transferer) == true){
            Allowed = true;
        }
        return Allowed;
    }

    function _getLockStatus(address holder, uint256 tokenId) internal virtual view returns(LockStatus){
        if(_tokenLockStatus[tokenId] != LockStatus.UnSet) {
            return _tokenLockStatus[tokenId];
        }

        return _getLockStatus(holder);
    }

    function _getLockStatus(address holder) internal virtual view returns(LockStatus){
        if(_walletLockStatus[holder] != LockStatus.UnSet) {
            return _walletLockStatus[holder];
        }

        return contractLockStatus;
    }

    function _getCALLevel(address holder, uint256 tokenId) internal virtual view returns(uint256){
        if(_tokenCALLevel[tokenId] > 0) {
            return _tokenCALLevel[tokenId];
        }

        return _getCALLevel(holder);
    }

    function _getCALLevel(address holder) internal virtual view returns(uint256){
        if(_walletCALLevel[holder] > 0) {
            return _walletCALLevel[holder];
        }

        return CALLevel;
    }

    // For token lock
    function _lock(LockStatus status, uint256 id) internal virtual {
        _tokenLockStatus[id] = status;
        emit TokenLock(ownerOf(id), msg.sender, uint(status), id);
    }

    // For wallet lock
    function _setWalletLock(address to, LockStatus status) internal virtual {
        _walletLockStatus[to] = status;
    }

    function _setWalletCALLevel(address to ,uint256 level) internal virtual {
        _walletCALLevel[to] = level;
    }

    // For contract lock
    function setContractAllowListLevel(uint256 level) external onlyOwner{
        CALLevel = level;
    }

    function setContractLockStatus(LockStatus status) external onlyOwner {
       require(status != LockStatus.UnSet, "AntiScam: contract lock status can not set UNSET");
       contractLockStatus = status;
    }

    function setCAL(address _cal) external onlyOwner {
        CAL = IContractAllowListProxy(_cal);
    }

    /*///////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        if(getLocked(operator, owner)){
            return false;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require (getLocked(operator, msg.sender) == false || approved == false, "Can not approve locked token");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public payable virtual override {
        require (getTokenLocked(to, tokenId) == false, "Can not approve locked token");
        super.approve(to, tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 /*quantity*/
    ) internal virtual override {
        // 転送やバーンにおいては、常にstartTokenIdは TokenIDそのものとなります。
        if (from != address(0)) {
            // トークンがロックされている場合、転送を許可しない
            require(getTokenLocked(to, startTokenId) == false , "LOCKED");
        }
    }

    function _afterTokenTransfers(
        address from,
        address /*to*/,
        uint256 startTokenId,
        uint256 /*quantity*/
    ) internal virtual override {
        // 転送やバーンにおいては、常にstartTokenIdは TokenIDそのものとなります。
        if (from != address(0)) {
            // ロックをデフォルトに戻す。（デフォルトは、 contractのLock status）
            delete _tokenLockStatus[startTokenId];
            delete _tokenCALLevel[startTokenId];
        }
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721AntiScam).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}