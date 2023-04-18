// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ZERO, ONE, UC, uc, into} from "unchecked-counter/src/UC.sol";

library LibBrokerManager {

    using SafeERC20 for IERC20;

    bytes32 constant BROKER_MANAGER_STORAGE_POSITION = keccak256("apollox.broker.manager.storage");

    struct Broker {
        string name;
        string url;
        address receiver;
        uint24 id;
        uint24 brokerIndex;
        uint16 commissionP;
    }

    struct Commission {
        uint total;
        uint pending;
    }

    struct BrokerManagerStorage {
        // id =>
        mapping(uint24 => Broker) brokers;
        uint24[] brokerIds;
        // id => token =>
        mapping(uint24 => mapping(address => Commission)) brokerCommissions;
        // id => tokens
        mapping(uint24 => address[]) brokerCommissionTokens;
        // token => total amount
        mapping(address => uint256) allPendingCommissions;
        uint24 defaultBroker;
    }

    function brokerManagerStorage() internal pure returns (BrokerManagerStorage storage bms) {
        bytes32 position = BROKER_MANAGER_STORAGE_POSITION;
        assembly {
            bms.slot := position
        }
    }

    event AddBroker(uint24 indexed id, Broker broker);
    event RemoveBroker(uint24 indexed id);
    event UpdateBrokerCommissionP(uint24 indexed id, uint16 oldCommissionP, uint16 commissionP);
    event UpdateBrokerReceiver(uint24 indexed id, address oldReceiver, address receiver);
    event UpdateBrokerName(uint24 indexed id, string oldName, string name);
    event UpdateBrokerUrl(uint24 indexed id, string oldUrl, string url);
    event WithdrawBrokerCommission(
        uint24 indexed id, address indexed token,
        address indexed operator, uint256 amount
    );

    function initialize(
        uint24 id, uint16 commissionP, address receiver,
        string calldata name, string calldata url
    ) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        require(bms.defaultBroker == 0, "LibBrokerManager: Already initialized");
        bms.defaultBroker = id;
        addBroker(id, commissionP, receiver, name, url);
    }

    function addBroker(
        uint24 id, uint16 commissionP, address receiver,
        string calldata name, string calldata url
    ) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        require(bms.brokers[id].receiver == address(0), "LibBrokerManager: Broker already exists");
        Broker memory b = Broker(name, url, receiver, id, uint24(bms.brokerIds.length), commissionP);
        bms.brokers[id] = b;
        bms.brokerIds.push(id);
        emit AddBroker(id, b);
    }

    function _checkBrokerExist(BrokerManagerStorage storage bms, uint24 id) private view returns (Broker storage) {
        Broker storage b = bms.brokers[id];
        require(b.receiver != address(0), "LibBrokerManager: broker does not exist");
        return b;
    }

    function removeBroker(uint24 id) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        withdrawCommission(id);

        uint24[] storage brokerIds = bms.brokerIds;
        uint last = brokerIds.length - 1;
        uint removeBrokerIndex = bms.brokers[id].brokerIndex;
        if (removeBrokerIndex != last) {
            uint24 lastBrokerId = brokerIds[last];
            brokerIds[removeBrokerIndex] = lastBrokerId;
            bms.brokers[lastBrokerId].brokerIndex = uint24(removeBrokerIndex);
        }
        brokerIds.pop();
        delete bms.brokers[id];
        emit RemoveBroker(id);
    }

    function updateBrokerCommissionP(uint24 id, uint16 commissionP) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        Broker storage b = _checkBrokerExist(bms, id);
        uint16 oldCommissionP = b.commissionP;
        b.commissionP = commissionP;
        emit UpdateBrokerCommissionP(id, oldCommissionP, commissionP);
    }

    function updateBrokerReceiver(uint24 id, address receiver) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        Broker storage b = _checkBrokerExist(bms, id);
        address oldReceiver = b.receiver;
        b.receiver = receiver;
        emit UpdateBrokerReceiver(id, oldReceiver, receiver);
    }

    function updateBrokerName(uint24 id, string calldata name) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        Broker storage b = _checkBrokerExist(bms, id);
        string memory oldName = b.name;
        b.name = name;
        emit UpdateBrokerName(id, oldName, name);
    }

    function updateBrokerUrl(uint24 id, string calldata url) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        Broker storage b = _checkBrokerExist(bms, id);
        string memory oldUrl = b.url;
        b.url = url;
        emit UpdateBrokerUrl(id, oldUrl, url);
    }

    function withdrawCommission(uint24 id) internal {
        BrokerManagerStorage storage bms = brokerManagerStorage();
        Broker storage b = _checkBrokerExist(bms, id);
        address operator = msg.sender;
        address[] memory tokens = bms.brokerCommissionTokens[id];
        for (UC i = ZERO; i < uc(tokens.length); i = i + ONE) {
            Commission storage c = bms.brokerCommissions[id][tokens[i.into()]];
            if (c.pending > 0) {
                IERC20(tokens[i.into()]).safeTransfer(b.receiver, c.pending);
                emit WithdrawBrokerCommission(id, tokens[i.into()], operator, c.pending);
                bms.allPendingCommissions[tokens[i.into()]] -= c.pending;
                c.pending = 0;
            }
        }
    }

    function _getBrokerOrDefault(BrokerManagerStorage storage bms, uint24 id) private view returns (Broker memory) {
        Broker memory b = bms.brokers[id];
        if (b.receiver != address(0)) {
            return b;
        } else {
            return bms.brokers[bms.defaultBroker];
        }
    }

    function updateBrokerCommission(
        address token, uint256 feeAmount, uint24 id
    ) internal returns (uint256, uint24){
        BrokerManagerStorage storage bms = brokerManagerStorage();

        Broker memory b = _getBrokerOrDefault(bms, id);
        uint commission = feeAmount * b.commissionP / 1e4;
        if (commission > 0) {
            Commission storage c = bms.brokerCommissions[b.id][token];
            if (c.total == 0) {
                bms.brokerCommissionTokens[b.id].push(token);
            }
            c.total += commission;
            c.pending += commission;
            bms.allPendingCommissions[token] += commission;
        }
        return (commission, b.id);
    }
}