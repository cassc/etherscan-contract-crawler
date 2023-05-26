// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Upgradeable interface(abstract contract) for approval and transfer control mechanism
 * @author 0xedy
 * @notice This abstract contract is base for RestrcitApprove, Lockcable, etc..
 */

abstract contract AntiScamAbstract {

    error ApproveToNotAllowedTransferer();
    error TransferForNotAllowedToken();

    modifier onlyTokenApprovable (address transferer, uint256 tokenId) virtual {
        _checkTokenApprovable(transferer, tokenId);
        _;
    }

    modifier onlyWalletApprovable (address transferer, address holder, bool approved) virtual {
        _checkWalletApprovable(transferer, holder, approved);
        _;
    }

    modifier onlyTransferable (
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) virtual {
        _checkTransferable(from, to, startTokenId, quantity);
        _;
    }

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================
    function _initializeAntiScam() internal virtual {
        
    }

    // =============================================================
    //                          INTERNAL LOGIC FUNCTIONS
    // =============================================================

    function _isTokenApprovable (address /*transferer*/, uint256 /*tokenId*/) 
        internal
        view
        virtual
        returns (bool)
    {
        return true;
    }
    function _checkTokenApprovable (address transferer, uint256 tokenId)
        internal 
        view 
        virtual 
    {
        // Approving to Zero adress is alwayd allowed because it is disapproving.
        if (transferer != address(0)) {
            if (!_isTokenApprovable(transferer, tokenId)) revert ApproveToNotAllowedTransferer();
        }
    }

    function _isWalletApprovable(address /*transferer*/, address /*holder*/)
        internal
        view
        virtual
        returns (bool)
    {
        return true;
    }


    function _checkWalletApprovable (address transferer, address holder, bool approved)
        internal 
        view 
        virtual 
    {
        // Disapproving is always 
        if (approved) {
            if (!_isWalletApprovable(transferer, holder)) revert ApproveToNotAllowedTransferer();
        }
    }

    function _isTransferable (
        address /*from*/,
        address /*to*/,
        uint256 /*startTokenId*/,
        uint256 /*quantity*/
    ) internal view virtual returns (bool) {
        return true;
    }

    function _checkTransferable (
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view virtual {
        if (!_isTransferable(from, to, startTokenId, quantity)) revert TransferForNotAllowedToken();
    }
}