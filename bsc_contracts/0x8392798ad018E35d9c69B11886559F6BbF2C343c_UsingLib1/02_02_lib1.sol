pragma solidity ^0.8.0;

library lib1 {
    event logAdd(uint x, uint y, uint result);

    function add(uint x, uint y) public returns(uint) {
        uint s = x + y;
        emit logAdd(x, y, s);
        return s;
    }
}

library lib2 {
    function add(uint x, uint y) internal returns(uint) {
        return x + y;
    }
}