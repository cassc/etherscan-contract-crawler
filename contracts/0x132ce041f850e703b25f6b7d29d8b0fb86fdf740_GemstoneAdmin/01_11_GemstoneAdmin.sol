// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./INFT.sol";
import "./GemstoneWallet.sol";

contract GemstoneAdmin is AccessControl {
    address private _nftContract;

    constructor(address nftContract) {
        _nftContract = nftContract;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function claimAll(INFT.WalletTier[] memory wallets) external onlyRole(DEFAULT_ADMIN_ROLE) {
        INFT.WalletTier[] memory eligibleWallets = new INFT.WalletTier[](wallets.length);
        for (uint256 i = 0; i < wallets.length; i++) {
            INFT.WalletTier memory walletTier = wallets[i];
            GemstoneWallet wallet = new GemstoneWallet(walletTier.wallet, walletTier.tier);
            eligibleWallets[i] = INFT.WalletTier(address(wallet), walletTier.tier);
        }
        INFT(_nftContract).addEligibleWallets(eligibleWallets);

        for (uint256 i = 0; i < eligibleWallets.length; i++) {
            INFT.WalletTier memory wallet = eligibleWallets[i];
            GemstoneWallet(wallet.wallet).claim(_nftContract);
        }
    }
}