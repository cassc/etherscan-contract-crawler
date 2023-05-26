// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice Gas optimized airdrop extension with SSTORE2 technique for ERC721PsiBurnable Upgradeable.
/// @author 0xedy

import "./ERC721PsiAirdropUpgradeable.sol";
import "./storage/ERC721PsiAirdropStorage.sol";
import "solidity-bits/contracts/BitMaps.sol";
import "../ERC721Psi/extension/ERC721PsiBurnableUpgradeable.sol";

abstract contract ERC721PsiBurnableAirdropUpgradeable is ERC721PsiBurnableUpgradeable, ERC721PsiAirdropUpgradeable {
    using ERC721PsiAirdropStorage for ERC721PsiAirdropStorage.Layout;
    using BitMaps for BitMaps.BitMap;

    // =============================================================
    //     CONSTRUCTOR
    // =============================================================
    function __ERC721PsiBurnableAirdrop_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721Psi_init_unchained(name_, symbol_);
        __ERC721PsiBurnableAirdrop_init_unchain();
    }

    function __ERC721PsiBurnableAirdrop_init_unchain() internal onlyInitializing {
    }

    // =============================================================
    //     ERC721PsiAirdrop Override function
    // =============================================================
    /**
     * @dev This override for the custom ERC721PsiBurnable v0.7.0 to save the gas of calling totalSupply().
     * If use the original one, eliminate `++burnCounter;` command.
     */
    function _beforeAirdropZeroAddress(uint256 tokenId) internal virtual override {
        _burnedToken_().set(tokenId);
        unchecked{
            ++_burnCounter;
        }
        ERC721PsiAirdropStorage.layout().transferred.set(tokenId);
    }

    // =============================================================
    //     ERC721Psi Override functions
    // =============================================================
    function _exists(uint256 tokenId) 
        internal 
        view 
        virtual 
        override(ERC721PsiUpgradeable, ERC721PsiBurnableUpgradeable) 
        returns (bool) 
    {
        return ERC721PsiBurnableUpgradeable._exists(tokenId);
    }

    function totalSupply()
        public 
        view 
        virtual 
        override(ERC721PsiUpgradeable, ERC721PsiBurnableUpgradeable) 
        returns (uint256) 
    {
        return ERC721PsiBurnableUpgradeable.totalSupply();
    }

    function ownerOf(uint256 tokenId) 
        public 
        view 
        virtual 
        override(ERC721PsiUpgradeable, ERC721PsiAirdropUpgradeable) 
        returns (address)
    {
        return ERC721PsiAirdropUpgradeable.ownerOf(tokenId);
    }
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) 
        internal 
        virtual 
        override(ERC721PsiUpgradeable, ERC721PsiAirdropUpgradeable)
    {
        ERC721PsiAirdropUpgradeable._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function _transfer(address from, address to, uint256 tokenId) 
        internal 
        virtual 
        override(ERC721PsiUpgradeable, ERC721PsiAirdropUpgradeable)
    {
        ERC721PsiAirdropUpgradeable._transfer(from, to, tokenId);
    }
}