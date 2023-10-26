//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../admin-manager/AdminManagerUpgradable.sol";
import "../balance-limit/BalanceLimit.sol";

contract PriceUpgradable is Initializable, AdminManagerUpgradable {
    mapping(uint8 => uint256) private _price;

    function __Price_init() internal onlyInitializing {        
        __AdminManager_init_unchained();
        __Price_init_unchained();
    }

    function __Price_init_unchained() internal onlyInitializing {}

    function setPrice(uint8 stage_, uint256 value_) public onlyAdmin {
        _price[stage_] = value_;
    }

    function price(uint8 stage_) public view returns (uint256) {
        return _price[stage_];
    }

    function _handlePayment(uint256 cost) internal {
        require(msg.value >= cost, "Price: invalid");
        uint256 difference = msg.value - cost;
        if(difference > 0) {
            payable(msg.sender).transfer(difference);
        }
    }

    uint256[49] private __gap;
}