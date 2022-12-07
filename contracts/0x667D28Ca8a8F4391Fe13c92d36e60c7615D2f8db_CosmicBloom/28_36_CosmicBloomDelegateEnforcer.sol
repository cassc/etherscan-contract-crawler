// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './IDelegationRegistry.sol';

error InvalidColdWallet();

/**
 * @title CosmicBloomDelegateEnforcer
 * @author @NFTCulture
 * @dev Enforce requirements for Delegate wallets.
 *
 * This contract is hardcoded specifically for the Cosmic Bloom project.
 *
 * @notice Delegate.cash has some quirks, execute transactions using this
 * service at your own risk.
 */
abstract contract CosmicBloomDelegateEnforcer {
    address internal cosmicReef = 0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270;
    address internal elemental = 0xC9677Cd8e9652F1b1aaDd3429769b0Ef8D7A0425;

    // See: https://github.com/delegatecash/delegation-registry
    IDelegationRegistry public constant DELEGATION_REGISTRY =
        IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    function _TryDelegate(address self, address coldWallet) internal view returns (address) {
        if (coldWallet == address(0)) {
            return self;
        }

        // We only require that you've delegated either of the following projects in order for hotwallet to use the claims.
        bool isArtBlocksDelegate = _isDelegateForArtBlocksCosmicReef(coldWallet, 0);
        bool isElementalDelegate = _isDelegateForElemental(coldWallet, 0);

        if (!isArtBlocksDelegate && !isElementalDelegate) revert InvalidColdWallet();

        return coldWallet;
    }

    function _isDelegateForArtBlocksCosmicReef(address coldWallet, uint256 tokenId) internal view returns (bool) {
        return DELEGATION_REGISTRY.checkDelegateForToken(msg.sender, coldWallet, cosmicReef, tokenId);
    }

    function _isDelegateForElemental(address coldWallet, uint256 tokenId) internal view returns (bool) {
        return DELEGATION_REGISTRY.checkDelegateForToken(msg.sender, coldWallet, elemental, tokenId);
    }
}