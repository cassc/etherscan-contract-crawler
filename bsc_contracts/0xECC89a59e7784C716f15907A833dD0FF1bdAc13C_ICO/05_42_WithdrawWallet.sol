// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract WithdrawWallet is
ContextUpgradeable,
OwnableUpgradeable
{
    using SafeERC20 for IERC20;

    // Address Receive Token
    address private withdrawWallet;

    address private refWallet;

    modifier isWithdrawWallet() {
        require(
            withdrawWallet != address(0),
            "You need setup address receive token"
        );
        _;
    }

    function __Withdraw_init(address _withdrawWallet)
    internal
    onlyInitializing
    {
        withdrawWallet = _withdrawWallet;
        refWallet = _withdrawWallet;
    }

    function getWithdrawWallet() public view returns (address) {
        return withdrawWallet;
    }

    function getRefWalletDefault() public view returns (address) {
        return refWallet;
    }

    // Set Withdraw Wallet
    function setWithdrawWallet(address _withdrawWallet) public onlyOwner {
        require(
            _withdrawWallet != address(0),
            "Address receive token can not null"
        );
        withdrawWallet = _withdrawWallet;
    }

    function setRefWalletDefault(address _refWallet) public onlyOwner {
        require(
            _refWallet != address(0),
            "Address receive ref token can not null"
        );
        refWallet = _refWallet;
    }
}