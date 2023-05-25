// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IAddressRegistry.sol";
import "../interfaces/ILockManager.sol";
import "../interfaces/IRewardsHandler.sol";
import "../interfaces/ITokenVault.sol";
import "../interfaces/IRevestToken.sol";
import "../interfaces/IFNFTHandler.sol";
import "../lib/uniswap/IUniswapV2Factory.sol";
import "../interfaces/IInterestHandler.sol";


contract RevestAccessControl is Ownable {
    IAddressRegistry internal addressesProvider;
    address addressProvider;

    constructor(address provider) Ownable() {
        addressesProvider = IAddressRegistry(provider);
        addressProvider = provider;
    }

    modifier onlyRevest() {
        require(_msgSender() != address(0), "E004");
        require(
                _msgSender() == addressesProvider.getLockManager() ||
                _msgSender() == addressesProvider.getRewardsHandler() ||
                _msgSender() == addressesProvider.getTokenVault() ||
                _msgSender() == addressesProvider.getRevest() ||
                _msgSender() == addressesProvider.getRevestToken(),
            "E016"
        );
        _;
    }

    modifier onlyRevestController() {
        require(_msgSender() != address(0), "E004");
        require(_msgSender() == addressesProvider.getRevest(), "E017");
        _;
    }

    modifier onlyTokenVault() {
        require(_msgSender() != address(0), "E004");
        require(_msgSender() == addressesProvider.getTokenVault(), "E017");
        _;
    }

    function setAddressRegistry(address registry) external onlyOwner {
        addressesProvider = IAddressRegistry(registry);
    }

    function getAdmin() internal view returns (address) {
        return addressesProvider.getAdmin();
    }

    function getRevest() internal view returns (IRevest) {
        return IRevest(addressesProvider.getRevest());
    }

    function getRevestToken() internal view returns (IRevestToken) {
        return IRevestToken(addressesProvider.getRevestToken());
    }

    function getLockManager() internal view returns (ILockManager) {
        return ILockManager(addressesProvider.getLockManager());
    }

    function getTokenVault() internal view returns (ITokenVault) {
        return ITokenVault(addressesProvider.getTokenVault());
    }

    function getUniswapV2() internal view returns (IUniswapV2Factory) {
        return IUniswapV2Factory(addressesProvider.getDEX(0));
    }

    function getFNFTHandler() internal view returns (IFNFTHandler) {
        return IFNFTHandler(addressesProvider.getRevestFNFT());
    }

    function getRewardsHandler() internal view returns (IRewardsHandler) {
        return IRewardsHandler(addressesProvider.getRewardsHandler());
    }
}