pragma solidity ^0.8.14;

import "./GelatoLQTYArb.sol";


contract GelatoLQTYArbFactory {
    address constant GELATO_OPS = 0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;

    function deployGelatoLQTYArb(address _taskCreator) external returns (GelatoLQTYArb) {
        return new GelatoLQTYArb(GELATO_OPS, _taskCreator);
    }
}