pragma solidity ^0.8.14;

import "./GelatoLQTYWBTCArb.sol";


contract GelatoLQTYWBTCArbFactory {
    address constant GELATO_OPS = 0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;
    address constant GEM_SELLER = 0x7605aaA45344F91315E0C596Ab679159784F8b7b;

    event NewGelatoLQTYWBTCArb(address arbContract, address taskCreator);

    function deployGelatoLQTYWBTCArb(address _taskCreator) external returns (GelatoLQTYWBTCArb) {
        GelatoLQTYWBTCArb arbContract = new GelatoLQTYWBTCArb(GEM_SELLER, GELATO_OPS, _taskCreator);
        emit NewGelatoLQTYWBTCArb(address(arbContract), _taskCreator);
        return arbContract;
    }
}