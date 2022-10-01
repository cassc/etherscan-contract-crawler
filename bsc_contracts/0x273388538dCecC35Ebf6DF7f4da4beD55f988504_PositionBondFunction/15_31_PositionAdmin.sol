pragma solidity ^0.8.9;

abstract contract PositionAdmin {
    address public positionAdmin;

    function initAdmin(address newAdmin) internal virtual {
        positionAdmin = newAdmin;
    }
}