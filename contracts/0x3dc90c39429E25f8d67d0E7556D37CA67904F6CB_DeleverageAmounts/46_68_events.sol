pragma solidity ^0.8.0;
import "./variables.sol";

contract Events is Variables {
    event updateAuthLog(address auth_);

    event updateVaultLog(address vaultAddr_, bool isVault_);

    event updatePremiumLog(uint256 premium_);

    event updatePremiumEthLog(uint256 premiumEth_);

    event withdrawPremiumLog(
        address[] tokens_,
        uint256[] amounts_,
        address to_
    );
}