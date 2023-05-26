pragma solidity =0.8.11;


contract Readable {
    uint32 constant month = 30 days;
    uint32 constant months = month;

    function since(uint _timestamp) internal view returns(uint) {
        if (not(passed(_timestamp))) {
            return 0;
        }
        return block.timestamp - _timestamp;
    }

    function till(uint _timestamp) internal view returns(uint) {
        if (passed(_timestamp)) {
            return 0;
        }
        return _timestamp - block.timestamp;
    }

    function passed(uint _timestamp) internal view returns(bool) {
        return _timestamp < block.timestamp;
    }

    function reached(uint _timestamp) internal view returns(bool) {
        return _timestamp <= block.timestamp;
    }

    function not(bool _condition) internal pure returns(bool) {
        return !_condition;
    }
}

library ExtraMath {
    function toUInt32(uint _a) internal pure returns(uint32) {
        require(_a <= type(uint32).max, 'uint32 overflow');
        return uint32(_a);
    }

    function toUInt88(uint _a) internal pure returns(uint88) {
        require(_a <= type(uint88).max, 'uint88 overflow');
        return uint88(_a);
    }

    function toUInt128(uint _a) internal pure returns(uint128) {
        require(_a <= type(uint128).max, 'uint128 overflow');
        return uint128(_a);
    }
}