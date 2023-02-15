// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IMTPClient.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract MTPClient is IMTPClient, Initializable {
    address[] internal _mtpWallets;


    /**
     * @dev Initializes the contract
     */
    function __MTPClient_init(
        address[] memory mtpWallets_
    ) internal onlyInitializing {
        __MTPClient_init_unchained(
            mtpWallets_
        );
    }

    function __MTPClient_init_unchained(
        address[] memory mtpWallets_
    ) internal onlyInitializing {
        _mtpWallets = mtpWallets_;
    }

    function mtpWallet() external view override returns (address[] memory) {
        return _mtpWallets;
    }

    function setMTPWallet(address[] calldata newWallet) external override {
        _authorizeMTPClient();
        emit SetMTPWallet(_mtpWallets, newWallet);
        _mtpWallets = newWallet;
    }

    // Implement this for auth function
    function _authorizeMTPClient() internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[5] private __gap;
}