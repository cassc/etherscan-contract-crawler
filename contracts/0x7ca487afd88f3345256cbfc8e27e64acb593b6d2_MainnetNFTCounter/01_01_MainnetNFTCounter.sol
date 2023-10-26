pragma solidity ^0.8.14;

contract MainnetNFTCounter {
    address public immutable dev;
    uint64 public constant EVOTURES_PRICE = 0.04 ether;
    uint64 public constant BOOSTER_PRICE = 0.006 ether;

    struct UserInfo {
        uint8 boosters;
        uint8 evotures;
    }

    mapping(address => UserInfo) public userInfo;

    constructor() {
        dev = msg.sender;
    }

    function buy(uint8 _evotures, uint8 _boosters) external payable {
        require(msg.value >= (_evotures*EVOTURES_PRICE + _evotures*_boosters*BOOSTER_PRICE), "EvoturesNFT::buy: INSUFFICIENT_ETH");
        require(_evotures <= (3 - userInfo[msg.sender].evotures) && _boosters <= 5, "EvoturesNFT::buy: FORBIDDEN");

        userInfo[msg.sender].evotures += _evotures;
        userInfo[msg.sender].boosters += _evotures*_boosters;
    }

    function withdrawETH() external {
        // Withdraw raised eth
        require (msg.sender == dev, "EvoturesNFT::withdrawETH: CALLER_NOT_DEV");
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "EvoturesNFT::withdrawETH: TRANSFER_FAILED");
    }

    receive() external payable {}
}