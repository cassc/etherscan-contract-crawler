// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/C2CAdvertise.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";


abstract contract C2CAdvertiseStorageUpgradeable is Initializable, ContextUpgradeable {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    struct C2CAdvertise {
        uint256 id;
        address owner;//主人
        string nickName;
        uint256 total;//总量
        uint256 sold;//售出数量
        uint256 price;//价格
        uint256 min;//最小数量
        uint256 max;//最大数量
        address sellToken;//出售代币
        address receiveToken;//接收代币
    }


    CountersUpgradeable.Counter private _advertiseIdTracker;

    mapping(uint256 => C2CAdvertise) public c2CAdvertiseMap;

    EnumerableSetUpgradeable.UintSet internal c2CAdvertiseSet;

    mapping(uint256 => uint256[]) public idOfOrderIds;


    event AddC2CAdvertised(uint256 indexed id,address indexed owner,string nickName,uint256 total,uint256 price,uint256 min,uint256 max,address indexed sellToken,address receiveToken);

    
    event RemoveC2CAdvertised(uint256 indexed id);

    

    
    function __C2CAdvertise_init() internal onlyInitializing {
        __Context_init_unchained();
        __C2CAdvertise_init_unchained();
    }

    function __C2CAdvertise_init_unchained() internal onlyInitializing {
        
    }


    function _addC2CAdvertise(address  owner,string memory nickName,uint256 total,uint256 price,uint256 min,uint256 max,address  sellToken,address receiveToken) internal virtual returns(uint256) {
        require(owner != address(0),"C2COrderStorageUpgradeable:owner not zero");
        uint256 id = _advertiseIdTracker.current();
        c2CAdvertiseSet.add(id);
        c2CAdvertiseMap[id] = C2CAdvertise( id,owner,nickName,total,0,price,min,max,sellToken,receiveToken);
        
        _advertiseIdTracker.increment();
        emit AddC2CAdvertised(id,owner,nickName,total,price,min,max,sellToken,receiveToken);
        return id;
    }

    function _soldC2CAdvertise(uint256 adId,uint256 quantity,uint256 orderId) internal virtual  {
        require(c2CAdvertiseMap[adId].min == 0 || quantity >= c2CAdvertiseMap[adId].min,"C2CAdvertiseStorageUpgradeable:_soldC2CAdvertise:quantity less to min");
        require(c2CAdvertiseMap[adId].max == 0 || quantity <= c2CAdvertiseMap[adId].max,"C2CAdvertiseStorageUpgradeable:_soldC2CAdvertise:quantity great to min");
        require(c2CAdvertiseMap[adId].total >= c2CAdvertiseMap[adId].sold+quantity);
        c2CAdvertiseMap[adId].sold = c2CAdvertiseMap[adId].sold+quantity;
        idOfOrderIds[adId].push(orderId);

    }

    function _editC2CAdvertise(uint256 id,string memory nickName,uint256 total,uint256 price,uint256 min,uint256 max) internal virtual  {
        require(c2CAdvertiseSet.contains(id),"C2CAdvertiseStorageUpgradeable:edit id is not exist");
        c2CAdvertiseMap[id].nickName = nickName;
        c2CAdvertiseMap[id].total = total;
        c2CAdvertiseMap[id].price = price;
        c2CAdvertiseMap[id].min = min;
        c2CAdvertiseMap[id].max = max;
    }

    function _removeC2CAdvertise(uint256 id) internal virtual  {
        c2CAdvertiseSet.remove(id);
        delete c2CAdvertiseMap[id];
        emit RemoveC2CAdvertised(id);
    }


    function advertiseLength() public view returns (uint256) {
        return c2CAdvertiseSet.length();
    }

    function advertiseIds() public view returns (uint256[] memory) {
        return c2CAdvertiseSet.values();
    }

    function advertiseAt(uint256 index) public view returns (uint256) {
        return c2CAdvertiseSet.at(index);
    }

    uint256[49] private __gap;
}