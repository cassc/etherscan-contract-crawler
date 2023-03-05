// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/presets/C2CMarket.sol)

pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./C2CAdvertiseStorageUpgradeable.sol";
import "./C2COrderStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./OperateStorageUpgradeable.sol";

contract C2CMarketUpgradeable is Initializable, ContextUpgradeable, AccessControlEnumerableUpgradeable,C2CAdvertiseStorageUpgradeable,C2COrderStorageUpgradeable,OperateStorageUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    function initialize() public virtual initializer {
        __C2CMarket_init();
    }
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ADVERTISE_ROLE = keccak256("ADVERTISE_ROLE");
    bytes32 public constant OPERATE_ROLE = keccak256("OPERATE_ROLE");
    uint256 public FEE_FACTOR;


    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {C2CMarket-constructor}.
     */
    function __C2CMarket_init() internal onlyInitializing {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __C2CAdvertise_init_unchained();
        __C2CMarket_init_unchained();
        __Operate_init_unchained();
    }

    function __C2CMarket_init_unchained() internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(ADVERTISE_ROLE, _msgSender());
        _setupRole(OPERATE_ROLE, _msgSender());
        FEE_FACTOR = 20;
    }

    //创建广告
    function addC2CAdvertise(address  owner,string memory nickName,uint256 total,uint256 price,uint256 min,uint256 max,address  sellToken,address receiveToken) public virtual payable onlyRole(ADVERTISE_ROLE) {
        _addC2CAdvertise(owner,nickName,total,price,min,max,sellToken,receiveToken);
    }

    //修改广告
    function editC2CAdvertise(uint256 id,string memory nickName,uint256 total,uint256 price,uint256 min,uint256 max) public virtual payable onlyRole(ADVERTISE_ROLE){
        _editC2CAdvertise(id,nickName,total,price,min,max);
    }

    //删除广告
    function removeC2CAdvertise(uint256 id) public virtual onlyRole(ADVERTISE_ROLE) payable onlyRole(ADVERTISE_ROLE){
       _removeC2CAdvertise(id);
    }

    //创建订单
    function createC2COrder(uint256 adId,uint256 quantity) public virtual payable {
        require(c2CAdvertiseMap[adId].owner != _msgSender(),"C2CMarketUpgradeable:you cant buy your advertise");
        uint256 price = c2CAdvertiseMap[adId].price;
        uint256 amount = price * quantity / (10**18);
        uint256 orderId = _addC2COrder(_msgSender(), adId, c2CAdvertiseMap[adId].owner, quantity, price, amount);
        _soldC2CAdvertise(adId,quantity,orderId);
        _transferToken(adId,orderId);
    }

    function _transferToken(uint256 adId,uint256 orderId) internal virtual    {
        address sellToken = c2CAdvertiseMap[adId].sellToken;
        address receiveToken = c2CAdvertiseMap[adId].receiveToken;
        address seller = c2CAdvertiseMap[adId].owner;
        address buyer = c2COrderMap[orderId].owner;

        uint256 quantity = c2COrderMap[orderId].quantity;
        uint256 qfees = (quantity / 100) * FEE_FACTOR;
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(sellToken), seller, address(this),quantity-qfees);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(sellToken), buyer,quantity);

        
        uint256 amount = c2COrderMap[orderId].amount;
        uint256 afees = (amount / 100) * FEE_FACTOR;
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(receiveToken), buyer, address(this),amount);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(receiveToken), seller,amount-afees);
        
        for (uint i = 0; i < operateLength(); i++) {
            address operateAddress = operateAt(i);
            uint256 operateFactor = operateMapFactor[operateAddress];
            if(operateFactor > 0){
                uint256 operateFee = (amount / 100) * operateFactor;
                SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(receiveToken), operateAddress,operateFee);
            }
        }
    }


    function editOperate(address operate,uint256 factor) public virtual payable onlyRole(OPERATE_ROLE){
        _addOperate(operate,factor);
    }
    
    function editFeeFactor(uint256 factor) public virtual onlyRole(OPERATE_ROLE){
        FEE_FACTOR = factor;
    }

    function removeOperate(address operate) public virtual payable onlyRole(OPERATE_ROLE){
        _removeOperate(operate);
    }

    uint256[50] private __gap;
}