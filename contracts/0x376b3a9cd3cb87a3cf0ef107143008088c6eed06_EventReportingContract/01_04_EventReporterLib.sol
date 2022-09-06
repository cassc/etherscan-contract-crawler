// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IEventReportingContract.sol";

struct EventDispatchStorage {
    address eventReportingContract;
    function(address,address,ApplicationEventStruct memory) dispatchFunc;
}

contract EventReportingContract is Initializable {  

    event ApplicationEvent(address indexed account, address indexed _contract, bytes32 indexed selector, string name, bytes params);

    mapping(address => bool) private allowed;
    modifier onlyAllowed {
        require(allowed[msg.sender] == true, "not allowed");
        _;
    }
    function addAllowed(address _account) external onlyAllowed {
        allowed[_account] = true;
    }
    function dispatchEvent(address account, address _contract, ApplicationEventStruct memory evt) external onlyAllowed {
        emit ApplicationEvent(account, _contract, evt.selector, evt.name, evt.params);
    }
    function initialize(address[] memory moreAllowed) external initializer {
        allowed[msg.sender] = true;
        for (uint i = 0; i < moreAllowed.length; i++) {
            allowed[moreAllowed[i]] = true;
        }
    }
}

library EventReporterLib {

    bytes32 constant private DIAMOND_STORAGE_POSITION = keccak256("diamond.event.dispatch.storage");

    function diamondStorage() internal pure returns (EventDispatchStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function initialize(address[] memory other) internal {
        createEventReportingContract(other);
    }

    function getEventReportingContract() internal view returns (address) {
        EventDispatchStorage storage ds = diamondStorage();
        if(ds.eventReportingContract == address(0)) {
            return address(0);
        }
        return ds.eventReportingContract;
    }

    function createEventReportingContract(address[] memory other) internal returns (address _contract) {
        EventDispatchStorage storage ds = diamondStorage();
        ds.eventReportingContract = _contract = address(new EventReportingContract());
        EventReportingContract(ds.eventReportingContract).initialize(other);
    }

    function toEvent(string memory name, bytes memory params) internal pure returns (ApplicationEventStruct memory _event) {
        _event = ApplicationEventStruct(
            keccak256(bytes(name)), 
            name, 
            params
        );
    }

    function emitEvent(ApplicationEventStruct memory _event) internal {
        if(getEventReportingContract() == address(0)) {
            address[] memory a = new address[](1);
            a[0] = address(this);
            createEventReportingContract(a);
        }
        EventDispatchStorage storage ds = diamondStorage();
        EventReportingContract(ds.eventReportingContract).dispatchEvent(msg.sender, address(this), _event);
    }
}