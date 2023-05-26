// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Upgradeable WalletLockable
 * @author 0xedy
 * 
 */

import "../AntiScamInitializable.sol";
import "./storage/LockableStorage.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol";
import "./IWalletLockable.sol";
import "../AntiScamAbstract.sol";

abstract contract WalletLockable is AntiScamAbstract, AntiScamInitializable, IWalletLockable {
    using LockableStorage for LockableStorage.Layout;

    // 
    error TransferForLockedToken();

    // defualtLock cannot be set "Unset"
    error UnsetForDefaultLock();

    // contractLock cannot be set "Unset"
    error UnsetForContractLock();

    // Address Zero error
    error LockToZeroAddress();

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================
    /*
    function _initializeAntiScam() internal virtual override {
        LockableStorage.layout().lockEnabled = true;
        LockableStorage.layout().defaultLock = LockStatus.UnLock;
        LockableStorage.layout().contractLock  = LockStatus.UnLock;
    }
    */
    function __WalletLockable_init() internal onlyInitializingAntiScam {
        __WalletLockable_init_unchained();
    }

    function __WalletLockable_init_unchained() internal onlyInitializingAntiScam {
        LockableStorage.layout().lockEnabled = true;
        LockableStorage.layout().defaultLock = LockStatus.UnLock;
        LockableStorage.layout().contractLock  = LockStatus.UnLock;
    }

    // =============================================================
    //                        IWalletLockable
    // =============================================================
    function lockEnabled() external view returns (bool) {
        return LockableStorage.layout().lockEnabled;
    }

    function defaultLock() external view returns (LockStatus) {
        return LockableStorage.layout().defaultLock;
    }

    function contractLock() external view returns (LockStatus) {
        return LockableStorage.layout().contractLock;
    }

    function walletLock(address holder) external view returns (LockStatus) {
        return LockableStorage.layout().walletLock[holder];
    }

    function isTokenLocked(uint256 tokenId) public view virtual override returns (bool) {
        if (LockableStorage.layout().lockEnabled) {
            if (LockableStorage.layout().contractLock == LockStatus.Lock){
                return true;
            }
            address holder = _callOwnerOf(tokenId);
            if (_isWalletLocked(holder)) {
                return true;
            }
        }
        return false;   
    }

    function isWalletLocked(address holder) public view virtual override returns (bool) {
        if (LockableStorage.layout().lockEnabled) {
            if (LockableStorage.layout().contractLock == LockStatus.Lock){
                return true;
            }
            if (_isWalletLocked(holder)) {
                return true;
            }
        }
        return false;   

    }

    function _isWalletLocked(address holder) internal view virtual returns (bool) {
        // copy wallet lock status from storage to stack
        LockStatus walletLock_ = LockableStorage.layout().walletLock[holder];
        // When WalletLock, return true
        if (walletLock_ == LockStatus.Lock) {
            return true;
        } 
        if (walletLock_ == LockStatus.UnSet) {
            if (LockableStorage.layout().defaultLock == LockStatus.Lock) {
                return true;
            }
        } 
        return false;   

    }

    // =============================================================
    //      Internal setter functions
    // =============================================================
    function _setLockEnabled(bool value) internal virtual {
        LockableStorage.layout().lockEnabled = value;
    }
    
    function _setDefaultLock(LockStatus value) internal virtual {
        if (value == LockStatus.UnSet) revert UnsetForDefaultLock();
        LockableStorage.layout().defaultLock = value;
    }
    
    function _setContractLock(LockStatus value) internal virtual {
        if (value == LockStatus.UnSet) revert UnsetForContractLock();
        LockableStorage.layout().contractLock = value;
    }
    
    function _setWalletLock(address holder, LockStatus value) internal virtual {
        if (holder == address(0)) revert LockToZeroAddress();
        LockableStorage.layout().walletLock[holder] = value;
        emit WalletLockChanged(holder, msg.sender, value);
    }
    
    // =============================================================
    //      AntiScamAbstract Override
    // =============================================================

    function _isTokenApprovable(address /*transferer*/, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return !isTokenLocked(tokenId);
    }

    function _isWalletApprovable(address /*transferer*/, address holder)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return !isWalletLocked(holder);
    }

    function _isTransferable(
        address from,
        address to,
        uint256 /*startTokenId*/,
        uint256 /*quantity*/
    ) internal view virtual override returns (bool ret) {
        // If not minting nor burning:
        if (from != address(0)) {
            if (to != address(0)) {
                // Get wallet lock status
                if (isWalletLocked(from)) return false;
                // Get token lock status
                // This contract has only wallet lock, so the following procedures are skipped.
                /*
                uint256 lastTokenId = startTokenId + quantity;
                for (uint256 i = startTokenId; i < lastTokenId; ){
                    // If token locked, revert transfer.
                    if (isTokenLocked(i)) revert TransferForLockedToken();
                    unchecked {
                        ++i;
                    }
                }
                */
            }
        }
        return true;
    }

    

    // =============================================================
    //      Internal Parent Function Caller
    // =============================================================

    /**
     * @dev Parent function caller for ownerOf() of ERC721
     */
    function _callOwnerOf(uint256 tokenId) internal view virtual returns (address addr) {
        bytes memory payload;// = abi.encodeWithSignature("ownerOf(uint256)", tokenId); 
        // Prepare calldata
        assembly {
            // Set free memory
            payload := mload(0x40)
            // Shift free memory poiinter
            mstore(0x40, add(payload, 0x60))
            // Set length of calldata (selector[4bytes] + parameter[32 bytes])
            mstore(payload, 36)
            // Signature of "ownerOf(uint256)".
            let sigOwnerOf := 0x6352211e
            // Generate calldata 
            mstore(add(payload, 0x20), shl(224, sigOwnerOf))
            mstore(add(payload, 0x24), tokenId)
        }
        // Static call
        (bool success, bytes memory b) = address(this).staticcall(payload);

        // Extract return value
        if (!success) {
            revert();
        } else {
            assembly {
                addr := mload(add(b, 0x20))
            }
        }
    }


}