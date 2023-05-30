// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract FoldingAccountStorage {
    bytes32 constant ACCOUNT_STORAGE_POSITION = keccak256('folding.account.storage');

    /**
     * entryCaller:         address of the caller of the account, during a transaction
     *
     * callbackTarget:      address of logic to be run when expecting a callback
     *
     * expectedCallbackSig: signature of function to be run when expecting a callback
     *
     * foldingRegistry      address of factory creating FoldingAccount
     *
     * nft:                 address of the nft contract.
     *
     * owner:               address of the owner of this FoldingAccount.
     */
    struct AccountStore {
        address entryCaller;
        address callbackTarget;
        bytes4 expectedCallbackSig;
        address foldingRegistry;
        address nft;
        address owner;
    }

    modifier onlyAccountOwner() {
        AccountStore storage s = aStore();
        require(s.entryCaller == s.owner, 'FA2');
        _;
    }

    modifier onlyNFTContract() {
        AccountStore storage s = aStore();
        require(s.entryCaller == s.nft, 'FA3');
        _;
    }

    modifier onlyAccountOwnerOrRegistry() {
        AccountStore storage s = aStore();
        require(s.entryCaller == s.owner || s.entryCaller == s.foldingRegistry, 'FA4');
        _;
    }

    function aStore() internal pure returns (AccountStore storage s) {
        bytes32 position = ACCOUNT_STORAGE_POSITION;
        assembly {
            s_slot := position
        }
    }

    function accountOwner() internal view returns (address) {
        return aStore().owner;
    }
}