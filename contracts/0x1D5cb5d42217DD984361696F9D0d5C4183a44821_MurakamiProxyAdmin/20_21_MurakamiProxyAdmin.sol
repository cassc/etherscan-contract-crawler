// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "./interfaces/IMurakamiFlowerCoin.sol";
import "./interfaces/IMurakamiMoneyCatCoinBank.sol";

contract MurakamiProxyAdmin is ProxyAdmin, AccessControl {
    TransparentUpgradeableProxy private _murakamiMoneyCatCoinBankProxy;
    TransparentUpgradeableProxy private _murakamiFlowerCoinProxy;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function deployMurakamiMoneyCatCoinBankProxy(
        address implementation,
        address royalty,
        uint96 royaltyFee,
        string memory name,
        string memory symbol,
        string memory baseUri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _murakamiMoneyCatCoinBankProxy = new TransparentUpgradeableProxy(
            implementation,
            address(this),
            abi.encodeWithSignature(
                "initialize(address,address,uint96,string,string,string)",
                _msgSender(),
                royalty,
                royaltyFee,
                name,
                symbol,
                baseUri
            )
        );
    }

    function deployMurakamiFlowerCoinProxy(
        address implementation,
        address royalty,
        uint96 royaltyFee,
        string memory name,
        string memory symbol,
        string memory baseUri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _murakamiFlowerCoinProxy = new TransparentUpgradeableProxy(
            implementation,
            address(this),
            abi.encodeWithSignature(
                "initialize(address,address,uint96,string,string,string)",
                _msgSender(),
                royalty,
                royaltyFee,
                name,
                symbol,
                baseUri
            )
        );
    }

    function upgradeMurakamiMoneyCatCoinBankProxy(
        address implementation
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            address(_murakamiMoneyCatCoinBankProxy) != address(0),
            "Proxy not deployed"
        );
        _murakamiMoneyCatCoinBankProxy.upgradeTo(implementation);
    }

    function upgradeMurakamiFlowerCoinProxy(
        address implementation
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            address(_murakamiFlowerCoinProxy) != address(0),
            "Proxy not deployed"
        );
        _murakamiFlowerCoinProxy.upgradeTo(implementation);
    }

    function murakamiMoneyCatCoinBankProxy() public view returns (address) {
        return address(_murakamiMoneyCatCoinBankProxy);
    }

    function murakamiFlowerCoinProxy() public view returns (address) {
        return address(_murakamiFlowerCoinProxy);
    }
}