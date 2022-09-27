pragma solidity ^0.8.0;
import "lib1.sol";

contract UsingLib1 {
    function sum(uint x, uint y) external returns(uint) {
        return lib1.add(x, y);
    }
}