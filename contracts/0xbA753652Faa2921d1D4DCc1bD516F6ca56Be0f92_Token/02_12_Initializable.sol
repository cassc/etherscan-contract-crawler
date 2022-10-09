pragma solidity ^0.8.9;

abstract contract Initializable {
    bool public initialized;

    modifier notInitialized() {
        require(!initialized, "Already initialized");
        _;
    }
}