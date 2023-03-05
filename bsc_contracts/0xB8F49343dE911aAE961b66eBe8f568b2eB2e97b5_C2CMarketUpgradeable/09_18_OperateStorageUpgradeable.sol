// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Operate.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";


abstract contract OperateStorageUpgradeable is Initializable, ContextUpgradeable {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(address => uint256) public operateMapFactor;
    
    EnumerableSetUpgradeable.AddressSet private operateSetFactor;


    event AddOperated(address indexed operate,uint256 indexed factor);

    
    event RemoveOperated(address indexed operate);
    
    function __Operate_init() internal onlyInitializing {
        __Context_init_unchained();
        __Operate_init_unchained();
    }

    function __Operate_init_unchained() internal onlyInitializing {
        
    }

    function _addOperate(address  operate, uint256 factor) internal virtual {
        require(operate != address(0),"OperateStorageUpgradeable:operate not zero");
        operateMapFactor[operate] = factor;
        operateSetFactor.add(operate);
        emit AddOperated(operate,factor);
    }

    function _removeOperate(address operate) internal virtual  {
        operateSetFactor.remove(operate);
        delete operateMapFactor[operate];
        emit RemoveOperated(operate);
    }

    function operateLength() public view returns (uint256) {
        return operateSetFactor.length();
    }

    function operateIds() public view returns (address[] memory) {
        return operateSetFactor.values();
    }

    function operateAt(uint256 index) public view returns (address) {
        return operateSetFactor.at(index);
    }

    uint256[49] private __gap;
}