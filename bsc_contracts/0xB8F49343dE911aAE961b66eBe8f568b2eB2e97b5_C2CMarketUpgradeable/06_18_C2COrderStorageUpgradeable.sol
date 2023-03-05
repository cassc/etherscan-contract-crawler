// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/C2COrder.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";


abstract contract C2COrderStorageUpgradeable is Initializable, ContextUpgradeable {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;


    struct C2COrder {
        uint256 id;
        address owner;//订单主人
        uint256 adId;//广告ID
        address seller;//卖家地址
        uint256 quantity;//数量
        uint256 price;//价格
        uint256 amount;//金额
        uint256 createTime;
    }


    CountersUpgradeable.Counter private _orderIdTracker;

    mapping(uint256 => C2COrder) public c2COrderMap;

    EnumerableSetUpgradeable.UintSet private c2COrderSet;

    mapping(address => uint256[]) public ownerC2COrderMap;


    event AddC2COrderd(uint256 indexed id,address indexed owner, uint256 indexed adId,address seller,uint256 quantity,uint256 price,uint256 amount,uint256 createTime);

    
    event RemoveC2COrderd(uint256 indexed id);

    

    
    function __C2COrder_init() internal onlyInitializing {
        __Context_init_unchained();
        __C2COrder_init_unchained();
    }

    function __C2COrder_init_unchained() internal onlyInitializing {
        
    }

    function _addC2COrder(address  owner, uint256 adId,address seller,uint256 quantity,uint256 price,uint256 amount) internal virtual  returns(uint256)  {
        require(owner != address(0),"C2COrderStorageUpgradeable:owner not zero");
        uint256 id = _orderIdTracker.current();
        c2COrderSet.add(id);
        c2COrderMap[id] = C2COrder(id,owner,adId,seller,quantity,price,amount,block.timestamp);
        ownerC2COrderMap[owner].push(id);
        _orderIdTracker.increment();
        emit AddC2COrderd(id,owner,adId,seller,quantity,price,amount,block.timestamp);
        return id;
    }

    function _removeC2COrder(uint256 id) internal virtual  {
        c2COrderSet.remove(id);
        delete c2COrderMap[id];
        emit RemoveC2COrderd(id);
    }


    function orderLength() public view returns (uint256) {
        return c2COrderSet.length();
    }

    function orderIds() public view returns (uint256[] memory) {
        return c2COrderSet.values();
    }

    function orderAt(uint256 index) public view returns (uint256) {
        return c2COrderSet.at(index);
    }

    function ownerC2COrderIds(address owner) public view returns (uint256[] memory) {
        return ownerC2COrderMap[owner];
    }
    function ownerC2COrderLength(address owner) public view returns (uint256) {
        return ownerC2COrderMap[owner].length;
    }

    uint256[49] private __gap;
}