pragma solidity ^0.8.9;

contract Struct {
    struct Pool {
        string teamA;
        string teamB;
        bool isActive;
        uint256 endAt;
        uint256 scoreA;
        uint256 scoreB;
        bool winA;
    }

    struct betResult {
        uint256 pointA;
        uint256 pointB;
        bool winA;
        bool isBet;
    }

    struct Vouchers {
        address user;
        uint256 ammount;
        uint256 timestamp;
    }
}