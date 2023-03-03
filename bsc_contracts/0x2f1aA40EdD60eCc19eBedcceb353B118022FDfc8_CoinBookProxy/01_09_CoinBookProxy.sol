// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract CoinBookProxy is TransparentUpgradeableProxy {
    constructor (
        address logic,
        address admin,
        address _multiSig,
        address _weth,
        address _priceFeed,
        uint256 _fees,
        address payable _taxWallet, 
        uint16 _tax
    ) TransparentUpgradeableProxy(logic, admin, generateData(
        _multiSig,
        _weth,
        _priceFeed,
        _fees,
        _taxWallet, 
        _tax
        )) {}

    function generateData(
        address _multiSig,
        address _weth,
        address _priceFeed,
        uint256 _fees,
        address payable _taxWallet, 
        uint16 _tax
    ) internal pure returns (bytes memory data) {
        data = abi.encodeWithSignature(
            "initialize(address,address,address,uint256,address,uint16)",
            _multiSig,
            _weth,
            _priceFeed,
            _fees,
            _taxWallet, 
            _tax
        );
    }
}