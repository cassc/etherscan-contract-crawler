pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IRDNRegistry} from "./RDN/RDNRegistry.sol";
import {IRDNDistributor} from "./RDN/RDNDistributor.sol";
import {WithdrawAnyERC20Token} from "./Utils/WithdrawAnyERC20Token.sol";

interface IPayments {
    
}

contract Payments is IPayments, AccessControlEnumerable, WithdrawAnyERC20Token {
    IRDNRegistry immutable REGISTRY;
    uint public fee = 500;

    struct Order {
        address currency;
        uint amount;
    }

    struct POS {
        address[] currencies;
        uint ownerId;
        uint rewards;
        bool paused;
        bool rdnOnly;
        uint activeTill;
        uint maxPaidAmount;
        uint maxOrdersCount;
        uint paidAmount;
    }

    mapping(uint => uint[]) public usersPOS;
    POS[] public POSRegistry;

    mapping(uint => mapping(uint => Order)) orders;
    uint[][] public posPaidOrders;

    bytes32 public constant SETFEE_ROLE = keccak256("SETFEE_ROLE");

    event Payment(
        uint indexed posId,
        uint indexed orderId,
        address indexed currency,
        uint amount,
        uint totalOrderAmount,
        uint rewardsAmount,
        uint feeAmount
    );

    constructor(address _registry, address _admin) WithdrawAnyERC20Token(_admin, false) {
        REGISTRY = IRDNRegistry(_registry);

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(SETFEE_ROLE, _admin);
    }

    function pay(uint _posId, uint _orderId, address _currency, uint _amount) public{
        POS memory pos = POSRegistry[_posId]; // gas savings
        require(inArray(pos.currencies, _currency), 'Invalid _currency or _posId');
        require(isActive(_posId), "POS not active");
        if (pos.rdnOnly) {
            require(REGISTRY.isRegisteredByAddress(msg.sender), 'Not registered in RDN');
        }
        require(_amount > 0, '_amount should be positive');
        IERC20 token = IERC20(_currency);
        token.transferFrom(msg.sender, address(this), _amount);
        uint remainedAmount = _amount;
        uint feeAmount = _amount * fee / 10000;
        remainedAmount -= feeAmount;
        uint rewardsAmount = 0;
        if (pos.rewards > 0 && REGISTRY.isRegisteredByAddress(msg.sender)) { // if msg.sender is out of RDN, rewerds forwards to POS owner
            rewardsAmount = remainedAmount * pos.rewards / 10000;
            remainedAmount -= rewardsAmount;
            IRDNDistributor distributor = IRDNDistributor(REGISTRY.getDistributor(_currency));
            token.approve(address(distributor), rewardsAmount);
            distributor.distribute(msg.sender, rewardsAmount);
        }
        token.transfer(REGISTRY.getUserAddress(pos.ownerId), remainedAmount);

        if (pos.maxPaidAmount > 0) {
            pos.paidAmount += _amount;
        }

        if (orders[_posId][_orderId].amount > 0) {
            // запрет повторной оплаты счета в другом токене
            orders[_posId][_orderId].amount += _amount;
        } else {
            Order memory newOrder = Order(_currency, _amount);
            orders[_posId][_orderId] = newOrder;
            posPaidOrders[_posId].push(_orderId);
        }
        
        emit Payment(_posId, _orderId, _currency, _amount, orders[_posId][_orderId].amount, rewardsAmount, feeAmount);
        
    }

    function inArray(address[] memory _haystack, address _needl) internal pure returns(bool) {
        for (uint i=0; i < _haystack.length; i++) {
            if (_haystack[i] == _needl) {
                return true;
            }
        }
        return false;
    }

    function createPOS(address[] calldata _currencies, uint _rewards, bool _rdnOnly, uint _activeTill, uint _maxOrdersCount, uint _maxPaidAmount) public {
        uint ownerId = REGISTRY.getUserIdByAddress(msg.sender);
        require(ownerId > 0, "Not registered in RDN");
        if (_maxPaidAmount > 0) {
            require(_currencies.length == 1, "_maxPaidAmount can't be positive for multiple currencies");
        }
        POS storage newPOS = POSRegistry.push();
        posPaidOrders.push();
        newPOS.ownerId = ownerId;
        newPOS.currencies = _currencies;
        newPOS.rewards = _rewards;
        newPOS.rdnOnly = _rdnOnly;
        newPOS.maxPaidAmount = _maxPaidAmount;
        newPOS.maxOrdersCount = _maxOrdersCount;
        newPOS.activeTill = _activeTill;
        uint posId = POSRegistry.length - 1;
        usersPOS[ownerId].push(posId);
    }


    function setFee(uint _fee) public onlyRole(SETFEE_ROLE) {
        fee = _fee;
    }

    function pause(uint _posId) public {
        uint ownerId = REGISTRY.getUserIdByAddress(msg.sender);
        require(POSRegistry[_posId].ownerId == ownerId, "Access denied");
        POSRegistry[_posId].paused = true;
    }

    function unPause(uint _posId) public {
        uint ownerId = REGISTRY.getUserIdByAddress(msg.sender);
        require(POSRegistry[_posId].ownerId == ownerId, "Access denied");
        POSRegistry[_posId].paused = false;
    }

    function isActive(uint _posId) public view returns(bool) {
        if (isPaused(_posId) || isStopped(_posId)) {
            return false;
        }
        return true;
    }

    function isPaused(uint _posId) public view returns(bool) {
        return POSRegistry[_posId].paused;
    }

    function isStopped(uint _posId) public view returns(bool) {
        POS memory pos = POSRegistry[_posId]; // gas savings
        if (pos.activeTill > 0 && pos.activeTill < block.timestamp) {
            return true;
        }
        if (pos.maxPaidAmount > 0 && pos.paidAmount >= pos.maxPaidAmount) {
            return true;
        }
        if (pos.maxOrdersCount > 0 && posPaidOrders[_posId].length >= pos.maxOrdersCount) {
            return true;
        }
        return false;
    }

    function getAllPOS() public view returns(POS[] memory) {
        return POSRegistry;
    }

    function getPOS() public view returns(POS memory) {

    }

    function getAllPOSOrders() public view returns(Order[] memory) {

    }

}